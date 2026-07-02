import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_pnv/firebase_pnv_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFirebasePnv platform = MethodChannelFirebasePnv();
  const MethodChannel channel = MethodChannel('firebase_pnv');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'enableTestSession':
              return null;
            case 'checkSupport':
              return true;
            case 'getVerifiedPhoneNumber':
              return <String, dynamic>{
                'phoneNumber': '+10000000000',
                'token': 'mock-token',
              };
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('enableTestSession', () async {
    await expectLater(platform.enableTestSession('test-token'), completes);
  });

  test('checkSupport', () async {
    expect(await platform.checkSupport(), true);
  });

  test('getVerifiedPhoneNumber', () async {
    final result = await platform.getVerifiedPhoneNumber();
    expect(result?['phoneNumber'], '+10000000000');
    expect(result?['token'], 'mock-token');
  });
}
