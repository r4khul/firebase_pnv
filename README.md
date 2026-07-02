# firebase_pnv

**Verify a phone number without ever sending an SMS.**

`firebase_pnv` is an unofficial Flutter bridge to Google's **Firebase Phone
Number Verification (PNV)** SDK. Unlike `firebase_auth`'s classic phone
sign-in - which texts the user a one-time SMS code they must type back in -
Firebase PNV verifies the number **directly with the user's mobile carrier**
in the background, via the **Carrier API** exposed through the Android
Credential Manager. The user simply taps "Allow" on a native consent sheet;
no code is ever sent or typed.

|  | `firebase_pnv` (this package) | `firebase_auth` phone sign-in |
|---|---|---|
| Verification method | Carrier / SIM (Carrier API) | SMS OTP |
| User action | Tap "Allow" on a system sheet | Read SMS, type 6-digit code |
| SMS pumping fraud risk | **None** - no SMS is ever sent | Vulnerable to SMS pumping/toll fraud |
| Speed | Near-instant | Depends on SMS delivery |
| Platform support | Android only (today) | Android, iOS, Web |
| Auth integration | Returns a token you exchange via a custom backend for a Firebase custom auth token | Native Firebase Auth credential |

Because Firebase PNV never sends an SMS, it is immune to **SMS pumping
fraud**, where attackers repeatedly trigger your SMS verification endpoint
with junk numbers to rack up your SMS bill. It's currently **Android-only**;
this package ships a safe iOS stub so your shared Dart code can call it on
every platform and simply fall back to SMS when it's unavailable.

## Installation

```yaml
dependencies:
  firebase_pnv: ^0.0.1
```

### Android setup

1. Add Firebase to your Android app if you haven't already ([guide](https://firebase.google.com/docs/android/setup)).
2. In the [Firebase console](https://console.firebase.google.com), enable Phone Number Verification for your project.
3. `minSdkVersion` must be `24` or higher.
4. This package's `android/build.gradle.kts` already declares:
   ```kotlin
   implementation(platform("com.google.firebase:firebase-bom:34.15.0"))
   implementation("com.google.firebase:firebase-pnv")
   ```
   You don't need to add anything to your app's `build.gradle`.

### iOS

No setup required. Every method call resolves to a `PlatformException` with
code `UNAVAILABLE`, so make sure your app checks `checkSupport()` (which
safely returns `false` on iOS) before attempting verification.

## Recommended architecture: PNV first, SMS fallback

The recommended pattern is to **always attempt Firebase PNV first**, and
fall back to `firebase_auth`'s SMS-based verification only when PNV is
unsupported or fails:

```dart
import 'package:firebase_pnv/firebase_pnv.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebasePnv = FirebasePnv();

Future<void> verifyPhoneNumber(String phoneNumber) async {
  // 1. Cheap, consent-free capability check.
  final bool supported = await _firebasePnv.checkSupport();

  if (supported) {
    try {
      // 2. Show the native Credential Manager consent sheet.
      final result = await _firebasePnv.getVerifiedPhoneNumber();
      final String? verifiedNumber = result?['phoneNumber'] as String?;
      final String? pnvToken = result?['token'] as String?;

      // 3. Send `pnvToken` to your backend to mint a Firebase custom auth
      //    token (see "Backend Integration" below), then sign in:
      final customToken = await sendTokenToBackend(pnvToken!);
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      return;
    } on Exception {
      // PNV failed (user declined, network error, etc.) - fall through
      // to SMS-based verification below.
    }
  }

  // 4. Fallback: standard firebase_auth SMS OTP flow.
  await FirebaseAuth.instance.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (credential) {},
    verificationFailed: (e) {},
    codeSent: (verificationId, resendToken) {},
    codeAutoRetrievalTimeout: (verificationId) {},
  );
}
```

## API reference

```dart
final firebasePnv = FirebasePnv();

/// Consent-free check - use to decide whether to show a PNV button
/// or go straight to SMS verification.
bool supported = await firebasePnv.checkSupport();

/// Shows the Credential Manager consent sheet and verifies via carrier.
/// Returns { 'phoneNumber': String, 'token': String } or throws
/// PlatformException on failure/decline.
Map<String, dynamic>? result = await firebasePnv.getVerifiedPhoneNumber();
```

## Backend integration

Firebase Authentication does not (yet) accept the Firebase PNV token
directly as a sign-in credential. Instead, your Flutter app sends the token
returned by `getVerifiedPhoneNumber()` to **your own backend**, which:

1. Verifies the token's signature and claims against Firebase PNV's JWKS
   endpoint.
2. Extracts the verified phone number from the token's `sub` claim.
3. Uses the **Firebase Admin SDK** to mint a **custom auth token** for that
   user, which the client then exchanges for a real Firebase Auth session
   via `signInWithCustomToken()`.

```javascript
// server.js - Node.js + Express + firebase-admin
const admin = require('firebase-admin');
const { JwtVerifier } = require('aws-jwt-verify');

admin.initializeApp();

const FIREBASE_PROJECT_NUMBER = '123456789'; // Settings > General in console
const issuer = `https://fpnv.googleapis.com/projects/${FIREBASE_PROJECT_NUMBER}`;
const audience = issuer;
const jwksUri = 'https://fpnv.googleapis.com/v1beta/jwks';

const fpnvVerifier = JwtVerifier.create({ issuer, audience, jwksUri });

app.post('/exchangePnvToken', async (req, res) => {
  const { fpnvToken } = req.body;
  if (!fpnvToken) return res.sendStatus(400);

  try {
    // 1. Verify signature, issuer, audience, and expiry.
    const payload = await fpnvVerifier.verify(fpnvToken);

    // 2. Verify the nonce you generated earlier hasn't been replayed
    //    (see Firebase PNV's "custom flow" docs for nonce generation).
    await testAndRemoveNonce(payload.nonce);

    // 3. The verified phone number is the token's subject claim.
    const verifiedPhoneNumber = payload.sub;

    // 4. Look up (or create) a Firebase user for this phone number, then
    //    mint a custom auth token for it.
    const user = await admin.auth().getUserByPhoneNumber(verifiedPhoneNumber)
      .catch(() => admin.auth().createUser({ phoneNumber: verifiedPhoneNumber }));

    const customToken = await admin.auth().createCustomToken(user.uid);

    return res.json({ customToken });
  } catch (e) {
    return res.sendStatus(400);
  }
});
```

Back on the client, sign in with the returned custom token:

```dart
final customToken = await sendTokenToBackend(pnvToken);
await FirebaseAuth.instance.signInWithCustomToken(customToken);
```

## Example app

See `example/lib/main.dart` for a full neobrutalist demo app that runs the
`checkSupport()` -> `getVerifiedPhoneNumber()` flow and displays the
resulting phone number/token in a copyable block for easy sharing with beta
testers.

## Contributing

This is an open-source, community-maintained bridge - issues and PRs are
welcome. Since Firebase PNV is a very new SDK, expect the native API surface
to evolve; please open an issue if Google changes method signatures.

## Links

* [Firebase PNV overview](https://firebase.google.com/docs/phone-number-verification)
* [Firebase PNV Android setup](https://firebase.google.com/docs/phone-number-verification/android/get-started)
* [Customizing the PNV flow](https://firebase.google.com/docs/phone-number-verification/android/custom-flow)
* [Flutter plugin development](https://docs.flutter.dev/packages-and-plugins/developing-packages)
