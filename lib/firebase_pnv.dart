import 'package:flutter/services.dart';

import 'firebase_pnv_platform_interface.dart';

export 'firebase_pnv_stubs.dart';

/// Public Dart API for the `firebase_pnv` plugin.
///
/// Firebase Phone Number Verification (PNV) is fundamentally different from
/// `firebase_auth`'s SMS-based phone verification: instead of sending a text
/// message with a one-time code, PNV verifies the user's phone number
/// directly with their mobile carrier via the Android Credential Manager.
/// No SMS is ever sent, which means:
///  * No SMS pumping fraud risk (attackers can't rack up SMS costs by
///    spamming your verification endpoint with junk phone numbers).
///  * No waiting for an SMS to arrive, and no "I didn't get my code" support
///    tickets.
///  * The verification is tied to the physical SIM in the device, which is
///    a stronger signal than "whoever received the SMS".
///
/// This SDK is currently Android-only. On iOS, every method resolves to a
/// [PlatformException] with the code `UNAVAILABLE` so that apps can safely
/// call [checkSupport] on any platform and simply fall back to SMS-based
/// verification (e.g. `firebase_auth`) when it returns `false` or throws.
class FirebasePnv {
  /// Enables a Firebase PNV test session for development/testing without a
  /// billing account or a real SIM.
  ///
  /// Generate a [token] from the Firebase console under
  /// **Security > Phone Verification > Testing**, then call this once,
  /// before any other `firebase_pnv` call. While a test session is active,
  /// [getVerifiedPhoneNumber] resolves to a fake phone number (a valid
  /// country code followed by all zeros) instead of hitting a real carrier.
  /// Test tokens expire after 7 days.
  ///
  /// Throws a [PlatformException] if called more than once per app process,
  /// or on iOS, where PNV is unavailable.
  Future<void> enableTestSession(String token) {
    return FirebasePnvPlatform.instance.enableTestSession(token);
  }

  /// Checks whether the current device/SIM combination supports Firebase
  /// Phone Number Verification.
  ///
  /// This does **not** require user consent and does not show any UI - it's
  /// a cheap capability check that should be called before
  /// [getVerifiedPhoneNumber]. Use the result to decide whether to show a
  /// PNV-based verification button, or to silently fall back to SMS OTP
  /// verification (e.g. via `firebase_auth`) instead.
  ///
  /// Returns `false` (rather than throwing) on iOS, and on Android if the
  /// device, its SIM(s), or the network state don't support PNV, or if the
  /// underlying platform call fails.
  Future<bool> checkSupport() async {
    try {
      return await FirebasePnvPlatform.instance.checkSupport();
    } on PlatformException {
      // Treat any platform failure (including the iOS "UNAVAILABLE" stub)
      // as "unsupported" so callers can safely fall back to SMS.
      return false;
    }
  }

  /// Runs the full Firebase PNV verification flow and returns the verified
  /// phone number and an opaque token.
  ///
  /// On Android, this triggers the Android Credential Manager consent
  /// bottom sheet. If the user consents, Firebase PNV verifies the phone
  /// number with the carrier in the background - no SMS is sent - and
  /// returns:
  ///  * `phoneNumber`: the verified E.164 phone number.
  ///  * `token`: an opaque token that must be sent to your backend and
  ///    exchanged for a Firebase custom auth token via the Firebase Admin
  ///    SDK (see the package README for a backend integration snippet).
  ///
  /// Returns `null` if the native platform returned no result. Throws a
  /// [PlatformException] if:
  ///  * The user declines consent (`code: "USER_CANCELED"` or similar).
  ///  * The device does not support PNV (`code: "UNSUPPORTED"`).
  ///  * The platform is not Android (`code: "UNAVAILABLE"`).
  ///  * Any other native/network error occurs.
  ///
  /// Callers should always wrap this call in a `try`/`catch` and fall back
  /// to SMS-based verification on failure.
  Future<Map<String, dynamic>?> getVerifiedPhoneNumber() async {
    try {
      return await FirebasePnvPlatform.instance.getVerifiedPhoneNumber();
    } on PlatformException {
      rethrow;
    }
  }
}
