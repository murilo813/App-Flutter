package com.alembro

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    private val CHANNEL_CHROME = "abrir_chrome"
    private val CHANNEL_SIGNATURE = "app_signature_channel"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal para abrir Chrome
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CHROME).setMethodCallHandler { call, result ->
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

        // Canal para obter assinatura do app (compatível com Android 7+)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SIGNATURE)
            .setMethodCallHandler { call, result ->
                if (call.method == "getassinatura") {
                    try {
                        val md = MessageDigest.getInstance("SHA-256")

                        val signatures = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                            packageInfo.signingInfo?.apkContentsSigners
                        } else {
                            @Suppress("DEPRECATION")
                            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                            @Suppress("DEPRECATION")
                            packageInfo.signatures
                        }

                        if (signatures != null && signatures.isNotEmpty()) {
                            md.update(signatures[0].toByteArray())
                            val sha256 = Base64.encodeToString(md.digest(), Base64.NO_WRAP)
                            result.success(sha256)
                        } else {
                            result.error("NO_SIGNATURE", "Nenhuma assinatura encontrada", null)
                        }

                    } catch (e: Exception) {
                        result.error("ERROR", "Erro ao obter assinatura: ${e.message}", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
