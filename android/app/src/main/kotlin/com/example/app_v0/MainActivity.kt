package com.example.app_v0 // **VERIFIQUE E AJUSTE ESTE PACOTE SE NECESSÁRIO**

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.seuapp.sms/send" // Canal de comunicação

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "sendSms") {
                    val number: String? = call.argument("number")
                    val message: String? = call.argument("message")
                    if (number != null && message != null) {
                        sendSms(number, message, result)
                    } else {
                        result.error("INVALID_ARGS", "Número ou mensagem nulos", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun sendSms(number: String, message: String, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS), 0)
            result.error("NO_PERMISSION", "Permissão SEND_SMS não concedida", null)
            return
        }

        try {
            SmsManager.getDefault().sendTextMessage(number, null, message, null, null)
            result.success("SMS_ENVIADO")
        } catch (e: Exception) {
            result.error("SMS_ERROR", e.message, null)
        }
    }
}