package tirol.taler.taler_id_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.media.AudioFocusRequest
import android.media.AudioAttributes
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var audioFocusRequest: AudioFocusRequest? = null
    private var focusListener: AudioManager.OnAudioFocusChangeListener? = null
    private var audioFocusGranted = false
    private var flutterChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val messagesChannel = NotificationChannel(
                "messages",
                "Сообщения",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Уведомления о новых сообщениях"
                enableVibration(true)
            }
            nm.createNotificationChannel(messagesChannel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taler_id/audio")
        flutterChannel = ch
        ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSpeaker" -> {
                        val on = call.arguments as? Boolean ?: false
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        am.mode = AudioManager.MODE_IN_COMMUNICATION
                        if (on) requestAudioFocus(am)
                        am.isSpeakerphoneOn = on  // Must be after requestAudioFocus (which resets to false)
                        result.success(null)
                    }
                    "getAudioOutputs" -> {
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        val outputs = mutableListOf<Map<String, String>>()
                        outputs.add(mapOf("id" to "earpiece", "name" to "Телефон", "type" to "earpiece"))
                        outputs.add(mapOf("id" to "speaker", "name" to "Динамик", "type" to "speaker"))
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val devices = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                            val hasWired = devices.any { d ->
                                d.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                                d.type == AudioDeviceInfo.TYPE_WIRED_HEADSET
                            }
                            val btDevice = devices.firstOrNull { d ->
                                d.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                                d.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                                    (d.type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                                     d.type == AudioDeviceInfo.TYPE_BLE_SPEAKER))
                            }
                            if (hasWired) {
                                outputs.add(mapOf("id" to "headphones", "name" to "Наушники", "type" to "headphones"))
                            }
                            if (btDevice != null) {
                                val btName = btDevice.productName?.toString() ?: "Bluetooth"
                                outputs.add(mapOf("id" to "bluetooth", "name" to btName, "type" to "bluetooth"))
                            }
                        }
                        result.success(outputs)
                    }
                    "setAudioOutput" -> {
                        val type = call.arguments as? String ?: "earpiece"
                        val am = getSystemService(AUDIO_SERVICE) as AudioManager
                        am.mode = AudioManager.MODE_IN_COMMUNICATION
                        when (type) {
                            "speaker" -> {
                                am.stopBluetoothSco()
                                am.isBluetoothScoOn = false
                                am.isSpeakerphoneOn = true
                            }
                            "bluetooth" -> {
                                am.isSpeakerphoneOn = false
                                am.startBluetoothSco()
                                am.isBluetoothScoOn = true
                            }
                            else -> { // earpiece, headphones
                                am.stopBluetoothSco()
                                am.isBluetoothScoOn = false
                                am.isSpeakerphoneOn = false
                            }
                        }
                        requestAudioFocus(am)
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
                    "requestBatteryOptimizationExemption" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                            val pkg = packageName
                            if (!pm.isIgnoringBatteryOptimizations(pkg)) {
                                val intent = Intent(
                                    android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                    Uri.parse("package:$pkg")
                                )
                                startActivity(intent)
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestAudioFocus(am: AudioManager) {
        // Set earpiece mode immediately — LiveKit may default to speakerphone
        am.mode = AudioManager.MODE_IN_COMMUNICATION
        am.isSpeakerphoneOn = false

        // If we already hold audio focus, just enforce the mode — don't re-request.
        // Re-requesting would cause the previous listener to receive AUDIOFOCUS_LOSS_TRANSIENT
        // which triggers spurious beeps in Flutter.
        if (audioFocusGranted) return

        val listener = AudioManager.OnAudioFocusChangeListener { focusChange ->
            when (focusChange) {
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                    // A real external audio source (phone call, alarm) took focus
                    audioFocusGranted = false
                    runOnUiThread { flutterChannel?.invokeMethod("audioInterrupted", null) }
                }
                AudioManager.AUDIOFOCUS_GAIN -> {
                    // Focus returned — restore earpiece mode
                    audioFocusGranted = true
                    am.mode = AudioManager.MODE_IN_COMMUNICATION
                    am.isSpeakerphoneOn = false
                    runOnUiThread { flutterChannel?.invokeMethod("audioResumed", null) }
                }
                AudioManager.AUDIOFOCUS_LOSS -> {
                    audioFocusGranted = false
                }
                else -> {}
            }
        }
        focusListener = listener

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(attrs)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener(listener)
                .build()
            audioFocusRequest = req
            val result = am.requestAudioFocus(req)
            audioFocusGranted = (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        } else {
            @Suppress("DEPRECATION")
            val result = am.requestAudioFocus(listener, AudioManager.STREAM_VOICE_CALL,
                AudioManager.AUDIOFOCUS_GAIN)
            audioFocusGranted = (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        }
    }

    private fun abandonAudioFocus(am: AudioManager) {
        audioFocusGranted = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(focusListener)
        }
        focusListener = null
    }
}
