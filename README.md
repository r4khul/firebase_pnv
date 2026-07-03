# firebase_pnv

<p align="center">
  <img src="https://raw.githubusercontent.com/r4khul/firebase_pnv/main/banner/firebase_pnv.png" alt="firebase_pnv Banner" width="100%">
</p>

<p align="center">
  <a href="https://pub.dev/packages/firebase_pnv"><img src="https://img.shields.io/pub/v/firebase_pnv?label=pub.dev&labelColor=0F172A&logo=dart&logoColor=fff&color=0EA5E9&style=flat" alt="pub"></a>
  <a href="https://github.com/r4khul/firebase_pnv"><img src="https://img.shields.io/github/stars/r4khul/firebase_pnv?style=flat&label=stars&labelColor=0F172A&color=8B5CF6&logo=github&logoColor=fff" alt="github"></a>
  <a href="https://github.com/r4khul/firebase_pnv/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/r4khul/firebase_pnv/ci.yml?branch=main&label=build&labelColor=0F172A&color=22C55E&logo=github&logoColor=fff&style=flat" alt="build"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-F97316.svg?labelColor=0F172A&style=flat" alt="license"></a>
</p>


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

## Screenshots

Here is how the native consent sheet and carrier verification flow look on an Android device (Realme C67 5G):

<p align="center">
  <img src="https://raw.githubusercontent.com/r4khul/firebase_pnv/main/banner/carrier-verification.jpg" width="45%" alt="Carrier Verification Consent Sheet" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/r4khul/firebase_pnv/main/banner/auth-token-generate.jpg" width="45%" alt="Auth Token Generation" />
</p>

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

## Usage

This is all you need to start using the package in your app.

**1. Import it and create an instance** (one instance is enough for your
whole app - you can reuse it anywhere):

```dart
import 'package:firebase_pnv/firebase_pnv.dart';

final firebasePnv = FirebasePnv();
```

**2. Check if the device supports it.** Call this first, every time, before
trying to verify anything:

```dart
bool isSupported = await firebasePnv.checkSupport();
```
- Returns `true` → device/SIM can use Firebase PNV, safe to continue.
- Returns `false` → not supported (or you're on iOS) - show your normal SMS
  verification instead.

**3. If supported, verify the phone number.** This is the only method that
shows UI - it pops up the native consent sheet:

```dart
Map<String, dynamic>? result = await firebasePnv.getVerifiedPhoneNumber();

String? phoneNumber = result?['phoneNumber']; // e.g. "+14155550123"
String? token = result?['token'];             // send this to your backend
```
- If the user taps "Allow", you get back the `phoneNumber` and a `token`.
- If the user declines, or something goes wrong, it throws a
  `PlatformException` - always wrap the call in `try`/`catch`.

**4. Send the `token` to your backend.** Your app never needs to look inside
the token - just forward it as-is. Your backend verifies it and gives you
back a Firebase custom auth token, which you use to sign the user in (see
[Backend integration](#backend-integration) below for the full backend code).

That's really the whole public API - three methods total:

| Method | What it does | When to call it |
|---|---|---|
| `checkSupport()` | Checks if the device/SIM can use PNV. No UI, no consent needed. | Every time, before verifying. |
| `getVerifiedPhoneNumber()` | Shows the consent sheet and verifies the number via carrier. | Only after `checkSupport()` returns `true`. |
| `enableTestSession(token)` | Switches to test mode (fake phone number, no real SIM needed). | Optional - only during development. See below. |

## Testing without a real SIM (test mode)

Firebase PNV supports a test mode so you can build and test the entire flow
on physical devices and emulators **without a billing account or a real
SIM**:

1. In the [Firebase console](https://console.firebase.google.com), go to
   **Security > Phone Verification > Testing** and click **Generate token**.
   (Requires the Firebase Phone Number Verification Admin IAM role.)
2. In your app, call `enableTestSession` **once**, before any other
   `firebase_pnv` call:

   ```dart
   await FirebasePnv().enableTestSession('COPIED_TOKEN_STRING');
   ```
3. While the test session is active, `getVerifiedPhoneNumber()` resolves to
   a fake phone number (a valid country code followed by all zeros) instead
   of contacting a real carrier.

Test tokens expire after 7 days. Calling `enableTestSession` more than once
throws a `PlatformException`. Remove this call entirely before shipping to
production.

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

/// Enables a test session (development only). Call once, before any other
/// firebase_pnv call. See "Testing without a real SIM" above.
await firebasePnv.enableTestSession('COPIED_TOKEN_STRING');

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
   endpoint (`https://fpnv.googleapis.com/v1beta/jwks`, `ES256`).
2. Extracts the verified phone number from the token's `sub` claim.
3. Uses the **Firebase Admin SDK** to mint a **custom auth token** for that
   user, which the client then exchanges for a real Firebase Auth session
   via `signInWithCustomToken()`.

> Since this package uses Firebase PNV's unified `getVerifiedPhoneNumber()`
> API (rather than manually driving Credential Manager yourself), you do
> **not** need to generate/track nonces on the client - that's only required
> if you implement the [custom digital-credential flow](https://firebase.google.com/docs/phone-number-verification/android/custom-flow).

```javascript
// server.js - Node.js + Express + firebase-admin
const express = require('express');
const admin = require('firebase-admin');
const { JwtVerifier } = require('aws-jwt-verify');

admin.initializeApp();

// Find your Firebase project number on Settings > General in the console.
const FIREBASE_PROJECT_NUMBER = '123456789';
const issuer = `https://fpnv.googleapis.com/projects/${FIREBASE_PROJECT_NUMBER}`;
const audience = issuer;
const jwksUri = 'https://fpnv.googleapis.com/v1beta/jwks';

// Verifies: signature (ES256, via JWKS), issuer/audience match your
// project, and that the token has not expired.
const fpnvVerifier = JwtVerifier.create({ issuer, audience, jwksUri });

const app = express();
app.use(express.json());

app.post('/exchangePnvToken', async (req, res) => {
  const { fpnvToken } = req.body;
  if (!fpnvToken) return res.sendStatus(400);

  try {
    // 1. Verify signature, issuer, audience, and expiry.
    const payload = await fpnvVerifier.verify(fpnvToken);

    // 2. The verified phone number is the token's subject claim.
    const verifiedPhoneNumber = payload.sub;

    // 3. Look up (or create) a Firebase user for this phone number, then
    //    mint a custom auth token for it.
    const user = await admin.auth().getUserByPhoneNumber(verifiedPhoneNumber)
      .catch(() => admin.auth().createUser({ phoneNumber: verifiedPhoneNumber }));

    const customToken = await admin.auth().createCustomToken(user.uid);

    return res.json({ customToken });
  } catch (e) {
    // Signature, issuer/audience, or expiry check failed - reject the token.
    return res.sendStatus(400);
  }
});

app.listen(3000);
```

Back on the client, sign in with the returned custom token:

```dart
final customToken = await sendTokenToBackend(pnvToken);
await FirebaseAuth.instance.signInWithCustomToken(customToken);
```

## Going to production

Test mode is great for prototyping, but before shipping you must:

1. Remove the `enableTestSession(...)` call from your production build.
2. Add your app's **SHA-256 fingerprint** under **Settings > General** in
   the Firebase console.
3. Upgrade your project to the **Blaze (pay-as-you-go)** billing plan.
4. In Google Cloud Console > **APIs & Services > Credentials**, restrict your
   Android API key to include the Firebase Phone Number Verification API. If
   you use API restrictions, also allow-list `com.google.android.gms` with
   SHA-1 `38918a453d07199354f8b19af05ec6562ced5788`, or you'll see
   `PERMISSION_DENIED` errors in your logs.
5. In the Firebase console, go to **Security > Phone Verification >
   Production**, click **Upgrade to production**, and complete OAuth brand
   verification (requires a publicly accessible privacy policy).

Full details: [Upgrade to production mode](https://firebase.google.com/docs/phone-number-verification/android/production-mode).

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
* [Get started with Firebase PNV on Android](https://firebase.google.com/docs/phone-number-verification/android/get-started)
* [Customizing the PNV flow](https://firebase.google.com/docs/phone-number-verification/android/custom-flow)
* [Upgrade to production mode](https://firebase.google.com/docs/phone-number-verification/android/production-mode)
* [Verifying Firebase PNV tokens](https://firebase.google.com/docs/phone-number-verification/verify-tokens)
* [Flutter plugin development](https://docs.flutter.dev/packages-and-plugins/developing-packages)
