package com.kernelly.app

import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.kernelly.app/phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "getLine1Number") {
                result.success(readLine1Number())
            } else {
                result.notImplemented()
            }
        }
    }

    // Оператор/eSIM/прошивка нередко не отдают номер даже при выданном
    // разрешении — TelephonyManager в таком случае возвращает null или "",
    // это штатный случай, не ошибка: вызывающая сторона просто откатывается
    // на ручной ввод.
    private fun readLine1Number(): String? {
        return try {
            val telephonyManager = getSystemService(TELEPHONY_SERVICE) as? TelephonyManager
            telephonyManager?.line1Number?.takeIf { it.isNotBlank() }
        } catch (e: SecurityException) {
            null
        }
    }
}
