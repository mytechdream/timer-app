package com.example.timer_app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "timer_app/background_timer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundTimer" -> {
                        val title = call.argument<String>("title") ?: "计时器"
                        val body = call.argument<String>("body") ?: "计时进行中"
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_START
                            putExtra(TimerForegroundService.EXTRA_TITLE, title)
                            putExtra(TimerForegroundService.EXTRA_BODY, body)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }

                    "stopForegroundTimer" -> {
                        stopService(Intent(this, TimerForegroundService::class.java))
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
