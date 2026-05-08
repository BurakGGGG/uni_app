# Firebase için ProGuard kuralları
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn io.grpc.**

# Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Play Core (Flutter deferred components / split install references)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
