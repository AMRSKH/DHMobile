package dev.amscenter.donghua_player

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val volumeChannel = "dev.amscenter.donghua_player/volume"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, volumeChannel)
            .setMethodCallHandler { call, result ->
                val audioManager =
                    getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val maxVolume =
                    audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)

                when (call.method) {
                    "getVolume" -> {
                        val current =
                            audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                        result.success(
                            if (maxVolume > 0) current.toDouble() / maxVolume else 0.0
                        )
                    }
                    "setVolume" -> {
                        val value = call.argument<Double>("value") ?: 0.0
                        val index =
                            (value.coerceIn(0.0, 1.0) * maxVolume).roundToInt()
                        audioManager.setStreamVolume(
                            AudioManager.STREAM_MUSIC,
                            index,
                            0
                        )
                        result.success(
                            if (maxVolume > 0) index.toDouble() / maxVolume else 0.0
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
