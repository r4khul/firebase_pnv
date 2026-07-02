import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'firebase_pnv_method_channel.dart';

/// The platform interface that all `firebase_pnv` platform implementations
/// must extend.
///
/// This class exists so that platform-specific implementations (currently
/// only Android, with iOS providing a graceful stub) can be swapped out
/// without changing the public [FirebasePnv] API surface. Most consumers of
/// this package will never need to interact with this class directly.
abstract class FirebasePnvPlatform extends PlatformInterface {
  /// Constructs a FirebasePnvPlatform.
  FirebasePnvPlatform() : super(token: _token);

  static final Object _token = Object();

  static FirebasePnvPlatform _instance = MethodChannelFirebasePnv();

  /// The default instance of [FirebasePnvPlatform] to use.
  ///
  /// Defaults to [MethodChannelFirebasePnv].
  static FirebasePnvPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FirebasePnvPlatform] when
  /// they register themselves.
  static set instance(FirebasePnvPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Enables a Firebase PNV test session using a token generated from the
  /// Firebase console's Security > Phone Verification > Testing tab.
  ///
  /// Test sessions let you develop and test the full PNV flow on physical
  /// devices and emulators, without a billing account and without a real
  /// SIM - `getVerifiedPhoneNumber` will resolve to a fake phone number
  /// consisting of a valid country code followed by all zeros. Test tokens
  /// expire after 7 days.
  ///
  /// This must be called only once per app process, before any other
  /// Firebase PNV call; the native SDK throws if called more than once on
  /// the same underlying instance.
  Future<void> enableTestSession(String token) {
    throw UnimplementedError('enableTestSession() has not been implemented.');
  }

  /// Checks whether the current device and SIM card(s) support Firebase
  /// Phone Number Verification (PNV).
  ///
  /// This is a lightweight, consent-free pre-check. Apps should call this
  /// before attempting [getVerifiedPhoneNumber] so that unsupported
  /// devices/carriers can fall back to a traditional SMS OTP flow (e.g. via
  /// `firebase_auth`) without ever showing the PNV consent sheet.
  Future<bool> checkSupport() {
    throw UnimplementedError('checkSupport() has not been implemented.');
  }

  /// Runs the full Firebase PNV verification flow.
  ///
  /// On Android, this displays the Android Credential Manager consent
  /// bottom sheet, letting the user consent to sharing their carrier
  /// verified phone number with the app - no SMS code is ever sent. On
  /// success, a map containing `phoneNumber` and `token` is returned. The
  /// `token` must be forwarded to your backend to be exchanged for a
  /// Firebase custom auth token.
  ///
  /// Throws a [PlatformException] on failure (e.g. user declined consent,
  /// no network, or unsupported platform/device).
  Future<Map<String, dynamic>?> getVerifiedPhoneNumber() {
    throw UnimplementedError(
      'getVerifiedPhoneNumber() has not been implemented.',
    );
  }
}
