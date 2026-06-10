package com.unisec.app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val AUTH_CHANNEL = "com.unisec.app/auth_storage"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "clearFirebaseAuthStorage" -> {
                        val cleared = clearFirebaseAuthStorage(applicationContext)
                        result.success(cleared)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Firebase Auth şifreli SharedPreferences bozulduğunda oturum geri yüklenemez.
     * Bu dosyaları silerek bir sonraki girişte temiz kayıt oluşturulmasını sağlar.
     */
    private fun clearFirebaseAuthStorage(context: Context): Int {
        val prefsDir = File(context.applicationInfo.dataDir, "shared_prefs")
        if (!prefsDir.exists()) return 0

        var cleared = 0
        prefsDir.listFiles()?.forEach { file ->
            val name = file.name.lowercase()
            val isFirebaseAuth = name.contains("firebase.auth") ||
                name.contains("firebaseauth") ||
                name.startsWith("com.google.firebase.auth")
            if (isFirebaseAuth) {
                val prefName = file.name.removeSuffix(".xml")
                context.getSharedPreferences(prefName, Context.MODE_PRIVATE)
                    .edit()
                    .clear()
                    .commit()
                if (file.delete()) cleared++
            }
        }
        return cleared
    }
}
