import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'firebase_pnv_platform_interface.dart';

/// An implementation of [FirebasePnvPlatform] that uses method channels.
class MethodChannelFirebasePnv extends FirebasePnvPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('firebase_pnv');

  @override
  Future<void> enableTestSession(String token) {
    return methodChannel.invokeMethod<void>('enableTestSession', {
      'token': token,
    });
  }

  @override
  Future<bool> checkSupport() async {
    final supported = await methodChannel.invokeMethod<bool>('checkSupport');
    return supported ?? false;
  }

  @override
  Future<Map<String, dynamic>?> getVerifiedPhoneNumber() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'getVerifiedPhoneNumber',
    );
    return result;
  }
}
