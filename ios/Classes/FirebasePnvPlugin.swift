import Flutter
import UIKit

/// iOS stub implementation of the `firebase_pnv` plugin.
///
/// Firebase Phone Number Verification (PNV) currently only ships an Android
/// SDK. Rather than crashing or silently no-oping, every method call on iOS
/// immediately resolves with a `FlutterError` using the `UNAVAILABLE` code,
/// so that Dart callers can reliably detect this platform is unsupported
/// and fall back to SMS-based verification (e.g. via `firebase_auth`).
public class FirebasePnvPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "firebase_pnv", binaryMessenger: registrar.messenger())
    let instance = FirebasePnvPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(
      FlutterError(
        code: "UNAVAILABLE",
        message: "Firebase Phone Number Verification (PNV) is currently Android-only.",
        details: nil
      )
    )
  }
}
