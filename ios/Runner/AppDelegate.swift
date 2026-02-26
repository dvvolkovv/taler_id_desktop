import Flutter
import UIKit
import AVFoundation
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "taler_id/audio",
      binaryMessenger: controller.binaryMessenger
    )
    audioChannel = channel
    channel.setMethodCallHandler { call, result in
      let session = AVAudioSession.sharedInstance()
      switch call.method {
      case "setSpeaker":
        let on = call.arguments as? Bool ?? false
        do {
          try session.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP])
          try session.overrideOutputAudioPort(on ? .speaker : .none)
          result(nil)
        } catch {
          result(FlutterError(code: "AUDIO_ERROR", message: error.localizedDescription, details: nil))
        }
      case "getAudioOutputs":
        var outputs: [[String: String]] = []
        let currentOutputs = session.currentRoute.outputs
        let hasWired = currentOutputs.contains {
          $0.portType == .headphones || $0.portType == .headsetMic
        }
        let btOutput = currentOutputs.first {
          $0.portType == .bluetoothHFP || $0.portType == .bluetoothA2DP || $0.portType == .bluetoothLE
        }
        outputs.append(["id": "earpiece", "name": "Телефон", "type": "earpiece"])
        outputs.append(["id": "speaker", "name": "Динамик", "type": "speaker"])
        if hasWired {
          outputs.append(["id": "headphones", "name": "Наушники", "type": "headphones"])
        }
        if let bt = btOutput {
          outputs.append(["id": "bluetooth", "name": bt.portName, "type": "bluetooth"])
        }
        result(outputs)
      case "setAudioOutput":
        let type = call.arguments as? String ?? "earpiece"
        do {
          switch type {
          case "speaker":
            try session.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            try session.overrideOutputAudioPort(.speaker)
          case "bluetooth":
            try session.setCategory(.playAndRecord, options: [.allowBluetooth])
            try session.setActive(true)
            try session.overrideOutputAudioPort(.none)
          default: // earpiece, headphones
            try session.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            try session.overrideOutputAudioPort(.none)
          }
          result(nil)
        } catch {
          result(FlutterError(code: "AUDIO_ERROR", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Register for audio session interruptions (parallel calls from other apps/phone)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )

    // Register for VoIP push notifications via PushKit
    let voipRegistry = PKPushRegistry(queue: .main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func handleAudioInterruption(_ notification: Notification) {
    guard let info = notification.userInfo,
          let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
    DispatchQueue.main.async {
      if type == .began {
        // Notify Flutter to play 3 beeps
        self.audioChannel?.invokeMethod("audioInterrupted", arguments: nil)
      } else if type == .ended {
        // Reactivate our audio session when the other call ends
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        self.audioChannel?.invokeMethod("audioResumed", arguments: nil)
      }
    }
  }
}

extension AppDelegate: PKPushRegistryDelegate {
  func pushRegistry(_ registry: PKPushRegistry,
                    didUpdate credentials: PKPushCredentials,
                    for type: PKPushType) {
    guard type == .voIP else { return }
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(_ registry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType,
                    completion: @escaping () -> Void) {
    guard type == .voIP else { completion(); return }
    // MUST call showCallkitIncoming synchronously — iOS kills app if delayed
    let data = flutter_callkit_incoming.Data(args: payload.dictionaryPayload as NSDictionary)
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }
}
