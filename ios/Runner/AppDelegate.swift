import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(
      name: "taler_id/audio",
      binaryMessenger: controller.binaryMessenger
    )
    audioChannel.setMethodCallHandler { call, result in
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
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
