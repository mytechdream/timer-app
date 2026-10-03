package com.example.timer_app

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class TimerVibrationHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "vibrateCountdownComplete") {
            result.notImplemented()
            return
        }

        val durations = call.argument<List<Number>>("pattern")?.map { it.toLong() }
        if (durations == null || durations.size !in 2..16 ||
            durations.any { it < 0 || it > 5000 } || durations.sum() > 10000 ||
            durations.withIndex().none { it.index % 2 == 1 && it.value > 0 }
        ) {
            result.error("invalid_pattern", "Invalid countdown vibration pattern", null)
            return
        }

        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
            if (vibrator == null || !vibrator.hasVibrator()) {
                result.success(false)
                return
            }
            vibrate(vibrator, durations.toLongArray())
            result.success(true)
        } catch (error: SecurityException) {
            result.error("vibration_denied", "Vibration is not permitted", null)
        } catch (error: IllegalArgumentException) {
            result.error("invalid_pattern", "Unsupported countdown vibration pattern", null)
        }
    }

    @Suppress("DEPRECATION")
    private fun vibrate(vibrator: Vibrator, pattern: LongArray) {
        // Use alarm attributes, not touch feedback. Never bypass the user's DND.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrator.vibrate(
                VibrationEffect.createWaveform(pattern, -1),
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM)
            )
            return
        }
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1), attributes)
        } else {
            vibrator.vibrate(pattern, -1, attributes)
        }
    }
}
