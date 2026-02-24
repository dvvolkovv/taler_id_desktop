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
      if call.method == "setSpeaker" {
        let on = call.arguments as? Bool ?? false
        let session = AVAudioSession.sharedInstance()
        do {
          try session.setCategory(.playAndRecord, options: [.allowBluetooth])
          try session.overrideOutputAudioPort(on ? .speaker : .none)
          result(nil)
        } catch {
          result(FlutterError(code: "AUDIO_ERROR",
                              message: error.localizedDescription,
                              details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
