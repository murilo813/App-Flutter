package com.example.novo_app  

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "abrir_chrome"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "abrirNoChrome") {
                val url = call.argument<String>("url")
                try {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    intent.setPackage("com.android.chrome")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ACTIVITY_NOT_FOUND", "Chrome não encontrado", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
