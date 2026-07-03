import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'firebase_pnv_platform_interface.dart';

/// Web implementation of the `firebase_pnv` plugin.
class FirebasePnvWeb extends FirebasePnvPlatform {
  /// Registers this class as the default instance of [FirebasePnvPlatform].
  static void registerWith(Registrar registrar) {
    FirebasePnvPlatform.instance = FirebasePnvWeb();
  }

  @override
  Future<void> enableTestSession(String token) {
    throw PlatformException(
      code: 'UNAVAILABLE',
      message:
          'Firebase Phone Number Verification (PNV) is not supported on Web.',
    );
  }

  @override
  Future<bool> checkSupport() async {
    return false;
  }

  @override
  Future<Map<String, dynamic>?> getVerifiedPhoneNumber() {
    throw PlatformException(
      code: 'UNAVAILABLE',
      message:
          'Firebase Phone Number Verification (PNV) is not supported on Web.',
    );
  }
}
