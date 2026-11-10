package dev.amscenter.donghua_player

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val volumeChannel = "dev.amscenter.donghua_player/volume"

    // The app's cache folder (Context.getCacheDir), where the posters of
    // cached_network_image live. Directory.systemTemp in Dart is the code
    // cache instead (TASK-033 QA).
    private val storageChannel = "dev.amscenter.donghua_player/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "cacheDir" -> result.success(cacheDir.absolutePath)
                    else -> result.notImplemented()
                }
            }

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
