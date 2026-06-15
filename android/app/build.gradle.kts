import java.io.FileInputStream
import java.util.Base64
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Keystore yapılandırması
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val googleTestAdMobAppId = "ca-app-pub-3940256099942544~3347511713"

fun decodedDartDefines(): Map<String, String> {
    val encodedDefines = (project.findProperty("dart-defines") as? String)
        ?.takeIf { it.isNotBlank() }
        ?: return emptyMap()

    return encodedDefines.split(",")
        .mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            }.getOrNull()
        }
        .mapNotNull { define ->
            val separatorIndex = define.indexOf("=")
            if (separatorIndex <= 0) {
                null
            } else {
                define.substring(0, separatorIndex) to define.substring(separatorIndex + 1)
            }
        }
        .toMap()
}

val dartDefines = decodedDartDefines()

fun configuredProperty(name: String): String? {
    return (project.findProperty(name) as? String)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
        ?: dartDefines[name]?.trim()?.takeIf { it.isNotEmpty() }
}

fun keystoreProperty(name: String): String? {
    return (keystoreProperties[name] as? String)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
}

val configuredAdMobAppId = configuredProperty("ADMOB_APP_ID")

fun validateAndroidReleaseConfig() {
    val missingOrInvalid = mutableListOf<String>()

    if (!keystorePropertiesFile.exists()) {
        missingOrInvalid += "android/key.properties bulunamadi"
    }

    listOf("keyAlias", "keyPassword", "storeFile", "storePassword").forEach { propertyName ->
        if (keystoreProperty(propertyName) == null) {
            missingOrInvalid += "android/key.properties icinde '$propertyName' eksik"
        }
    }

    keystoreProperty("storeFile")?.let { storeFilePath ->
        if (!file(storeFilePath).exists()) {
            missingOrInvalid += "keystore dosyasi bulunamadi: $storeFilePath"
        }
    }

    when {
        configuredAdMobAppId == null -> {
            missingOrInvalid += "ADMOB_APP_ID eksik (-PADMOB_APP_ID=... veya --dart-define=ADMOB_APP_ID=...)"
        }
        configuredAdMobAppId == googleTestAdMobAppId ||
            configuredAdMobAppId.startsWith("ca-app-pub-3940256099942544") -> {
            missingOrInvalid += "release build Google test AdMob App ID kullanamaz"
        }
    }

    if (missingOrInvalid.isNotEmpty()) {
        throw GradleException(
            "Release build yapilandirmasi eksik veya guvensiz:\n" +
                missingOrInvalid.joinToString(separator = "\n") { "- $it" }
        )
    }
}

android {
    namespace = "com.unisec.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.unisec.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // AdMob App ID: -PADMOB_APP_ID=ca-app-pub-xxx~yyy
        // veya --dart-define=ADMOB_APP_ID=ca-app-pub-xxx~yyy.
        val admobAppId = configuredAdMobAppId ?: googleTestAdMobAppId
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    signingConfigs {
        create("release") {
            val releaseKeyAlias = keystoreProperty("keyAlias")
            val releaseKeyPassword = keystoreProperty("keyPassword")
            val releaseStoreFile = keystoreProperty("storeFile")
            val releaseStorePassword = keystoreProperty("storePassword")

            if (releaseKeyAlias != null &&
                releaseKeyPassword != null &&
                releaseStoreFile != null &&
                releaseStorePassword != null
            ) {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFile)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

val validateReleaseConfigTask = tasks.register("validateReleaseConfig") {
    group = "verification"
    description = "Fails release builds when signing or production AdMob configuration is missing."

    doLast {
        validateAndroidReleaseConfig()
    }
}

tasks.matching {
    it.name.contains("Release") && it.name != "validateReleaseConfig"
}.configureEach {
    dependsOn(validateReleaseConfigTask)
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Flutter embedding deferred component classes reference splitinstall APIs.
    implementation("com.google.android.play:feature-delivery:2.1.0")
    // image_cropper exposes UCropActivity from the uCrop artifact.
    implementation("com.github.Yalantis:ucrop:2.2.11")
}
