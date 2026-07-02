import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_pnv/firebase_pnv.dart';
import 'package:firebase_pnv/firebase_pnv_platform_interface.dart';
import 'package:firebase_pnv/firebase_pnv_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFirebasePnvPlatform
    with MockPlatformInterfaceMixin
    implements FirebasePnvPlatform {
  @override
  Future<bool> checkSupport() => Future.value(true);

  @override
  Future<Map<String, dynamic>?> getVerifiedPhoneNumber() =>
      Future.value({'phoneNumber': '+10000000000', 'token': 'mock-token'});
}

void main() {
  final FirebasePnvPlatform initialPlatform = FirebasePnvPlatform.instance;

  test('$MethodChannelFirebasePnv is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFirebasePnv>());
  });

  test('checkSupport', () async {
    FirebasePnv firebasePnvPlugin = FirebasePnv();
    MockFirebasePnvPlatform fakePlatform = MockFirebasePnvPlatform();
    FirebasePnvPlatform.instance = fakePlatform;

    expect(await firebasePnvPlugin.checkSupport(), true);
  });

  test('getVerifiedPhoneNumber', () async {
    FirebasePnv firebasePnvPlugin = FirebasePnv();
    MockFirebasePnvPlatform fakePlatform = MockFirebasePnvPlatform();
    FirebasePnvPlatform.instance = fakePlatform;

    final result = await firebasePnvPlugin.getVerifiedPhoneNumber();
    expect(result?['phoneNumber'], '+10000000000');
    expect(result?['token'], 'mock-token');
  });
}
