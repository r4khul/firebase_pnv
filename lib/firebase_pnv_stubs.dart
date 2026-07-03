import 'package:flutter/services.dart';
import 'firebase_pnv_platform_interface.dart';

/// macOS stub implementation of the `firebase_pnv` plugin.
class FirebasePnvMacOs extends FirebasePnvPlatform {
  /// Registers this class as the default instance of [FirebasePnvPlatform].
  static void registerWith() {
    FirebasePnvPlatform.instance = FirebasePnvMacOs();
  }

  @override
  Future<void> enableTestSession(String token) {
    throw PlatformException(
      code: 'UNAVAILABLE',
      message: 'Firebase Phone Number Verification (PNV) is not supported on macOS.',
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
      message: 'Firebase Phone Number Verification (PNV) is not supported on macOS.',
    );
  }
}

/// Windows stub implementation of the `firebase_pnv` plugin.
class FirebasePnvWindows extends FirebasePnvPlatform {
  /// Registers this class as the default instance of [FirebasePnvPlatform].
  static void registerWith() {
    FirebasePnvPlatform.instance = FirebasePnvWindows();
  }

  @override
  Future<void> enableTestSession(String token) {
    throw PlatformException(
      code: 'UNAVAILABLE',
      message: 'Firebase Phone Number Verification (PNV) is not supported on Windows.',
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
      message: 'Firebase Phone Number Verification (PNV) is not supported on Windows.',
    );
  }
}

/// Linux stub implementation of the `firebase_pnv` plugin.
class FirebasePnvLinux extends FirebasePnvPlatform {
  /// Registers this class as the default instance of [FirebasePnvPlatform].
  static void registerWith() {
    FirebasePnvPlatform.instance = FirebasePnvLinux();
  }

  @override
  Future<void> enableTestSession(String token) {
    throw PlatformException(
      code: 'UNAVAILABLE',
      message: 'Firebase Phone Number Verification (PNV) is not supported on Linux.',
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
      message: 'Firebase Phone Number Verification (PNV) is not supported on Linux.',
    );
  }
}
