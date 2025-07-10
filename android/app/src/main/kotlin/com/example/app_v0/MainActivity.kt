package com.example.app_v0

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Usaremos um único canal, dedicado para esta função pura.
    private val SMS_CHANNEL = "com.seuapp.sms/send_direct"
    private val TAG = "SMS_PURO_NATIVO"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "send") {
                    val number: String? = call.argument("number")
                    val message: String? = call.argument("message")

                    if (number == null || message == null) {
                        result.error("INVALID_ARGS", "Número ou mensagem nulos", null)
                        return@setMethodCallHandler
                    }

                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
                        try {
                            Log.d(TAG, "Permissão OK. Enviando SMS com SmsManager.getDefault()...")
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault().sendTextMessage(number, null, message, null, null)
                            result.success("SMS_SENT_OK")
                        } catch (e: Exception) {
                            Log.e(TAG, "ERRO no envio: ${e.message}")
                            result.error("ERROR_SMS", e.message, null)
                        }
                    } else {
                        Log.e(TAG, "ERRO DE PERMISSÃO no envio!")
                        result.error("NO_PERMISSION", "Permissão de SMS negada", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}