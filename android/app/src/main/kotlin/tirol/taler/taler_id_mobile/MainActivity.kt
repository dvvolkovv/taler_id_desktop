package tirol.taler.taler_id_mobile

import android.media.AudioManager
import android.os.Build
import android.media.AudioFocusRequest
import android.media.AudioAttributes
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var audioFocusRequest: AudioFocusRequest? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSpeaker" -> {
                        val on = call.arguments as? Boolean ?: false
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        am.mode = AudioManager.MODE_IN_COMMUNICATION
                        am.isSpeakerphoneOn = on
                        if (on) requestAudioFocus(am)
                        result.success(null)
                    }
                    "requestAudioFocus" -> {
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        requestAudioFocus(am)
                        result.success(null)
                    }
                    "abandonAudioFocus" -> {
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        abandonAudioFocus(am)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestAudioFocus(am: AudioManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(attrs)
                .setOnAudioFocusChangeListener { }
                .build()
            audioFocusRequest = req
            am.requestAudioFocus(req)
        } else {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(null, AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
        }
    }

    private fun abandonAudioFocus(am: AudioManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(null)
        }
    }
}
