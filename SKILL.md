# Firebase PNV (Phone Number Verification) - AI Skill Guide

## Overview
`firebase_pnv` is a Flutter plugin that provides carrier-based phone number verification through Firebase's Phone Number Verification (PNV) SDK. This is **NOT** traditional SMS-based authentication - it verifies phone numbers directly with mobile carriers via Android's Credential Manager, eliminating SMS costs and SMS pumping fraud.

## Key Differentiators
- **No SMS verification codes** - Users tap "Allow" on native system sheet
- **Zero SMS costs** - No text messages are sent
- **Immune to SMS pumping fraud** - Direct carrier verification
- **Android-only** - iOS/Web have safe stubs that return false/throw UNAVAILABLE
- **Requires Google Play Services** and Android minSdkVersion 24+

## Core API Methods

### FirebasePnv Class
```dart
final _firebasePnv = FirebasePnv();
```

#### `checkSupport()` - Future<bool>
- **Purpose**: Check if device/SIM/carrier supports PNV
- **Returns**: `true` if supported, `false` otherwise (including iOS)
- **Usage**: Always call first before attempting verification
- **Safe**: Won't throw on unsupported platforms

#### `getVerifiedPhoneNumber()` - Future<Map<String, dynamic>?>
- **Purpose**: Trigger verification flow and get verified data
- **Returns**: Map with `phoneNumber` (E.164) and `token` (JWT) or `null`
- **Throws**: PlatformException on user cancel, unsupported, non-Android, or missing activity
- **UI**: Shows Android Credential Manager consent sheet

#### `enableTestSession(String token)` - Future<void>
- **Purpose**: Enable test mode for development without real SIM
- **Parameter**: Test token from Firebase Console (Security > Phone Verification > Testing)
- **Usage**: Call once before other methods in debug builds
- **Throws**: PlatformException if called more than once per app process, or on non-Android platforms
- **Expires**: Test tokens expire after 7 days

## Recommended Implementation Pattern

```dart
import 'package:firebase_pnv/firebase_pnv.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebasePnv = FirebasePnv();

Future<void> authenticateUser() async {
  // 1. Check support first
  final bool isSupported = await _firebasePnv.checkSupport();
  
  if (isSupported) {
    try {
      // 2. Try PNV verification
      final result = await _firebasePnv.getVerifiedPhoneNumber();
      final String? pnvToken = result?['token'] as String?;
      
      if (pnvToken != null) {
        // 3. Exchange token on backend for Firebase custom token
        final String customToken = await exchangePnvTokenWithBackend(pnvToken);
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
        return;
      }
    } catch (e) {
      // User cancelled or verification failed - fall through to SMS
      print("PNV failed: $e");
    }
  }
  
  // 4. Fallback to traditional SMS verification
  await _startSmsVerification();
}
```

## Platform Handling

### Android (Full Support)
- Requires Google Play Services
- Uses Android Credential Manager
- Shows native consent bottom sheet
- Direct carrier API integration

### iOS/Web/Desktop (Safe Stubs)
- `checkSupport()` returns `false`
- `getVerifiedPhoneNumber()` throws `PlatformException` with code `UNAVAILABLE`
- `enableTestSession()` throws `PlatformException` with code `UNAVAILABLE`
- Allows single codebase with graceful fallback

## Backend Integration

PNV tokens must be exchanged on your backend for Firebase custom tokens:

```javascript
// Node.js Express example
const { JwtVerifier } = require('aws-jwt-verify');
const admin = require('firebase-admin');

const FIREBASE_PROJECT_NUMBER = 'your-project-number';
const issuer = `https://fpnv.googleapis.com/projects/${FIREBASE_PROJECT_NUMBER}`;
const jwksUri = 'https://fpnv.googleapis.com/v1beta/jwks';

const fpnvVerifier = JwtVerifier.create({ issuer, audience: issuer, jwksUri });

app.post('/api/verify-pnv', async (req, res) => {
  try {
    const payload = await fpnvVerifier.verify(req.body.pnvToken);
    const phoneNumber = payload.sub;
    
    // Find or create Firebase user
    let user = await admin.auth().getUserByPhoneNumber(phoneNumber).catch(() => 
      admin.auth().createUser({ phoneNumber })
    );
    
    // Create custom token
    const customToken = await admin.auth().createCustomToken(user.uid);
    res.json({ customToken });
  } catch (error) {
    res.status(400).send('Invalid token');
  }
});
```

## Testing

### Without Real SIM
1. Go to Firebase Console > Security > Phone Verification > Testing
2. Generate test token (expires 7 days)
3. In debug build: `await _firebasePnv.enableTestSession('your-token');`
4. Verification returns fake number like `+10000000000`

### Error Handling
Always wrap PNV calls in try-catch and provide SMS fallback:
- `USER_CANCELED` - User declined consent
- `UNSUPPORTED` - Device/carrier not supported  
- `UNAVAILABLE` - Non-Android platform
- Network/carrier errors

## Setup Requirements

### Android
- `minSdkVersion: 24`+
- Firebase project with PNV enabled
- Google Play Services on device
- Production: SHA-256 fingerprint registered, Blaze plan, API key restrictions

### Dependencies
```yaml
dependencies:
  firebase_pnv: ^1.0.1
  firebase_auth: ^latest  # for SMS fallback
```

## Common Use Cases

### 1. Primary Authentication
Use PNV as primary auth method with SMS fallback for unsupported devices.

### 2. Phone Number Verification
Verify user owns phone number without SMS costs or fraud risk.

### 3. Multi-platform Apps
Single codebase works across platforms - PNV on Android, SMS elsewhere.

## Best Practices

1. **Always call `checkSupport()` first** - cheap capability check
2. **Provide SMS fallback** - not all carriers support PNV
3. **Handle PlatformException gracefully** - user may cancel
4. **Use test sessions in development** - no real SIM needed
5. **Secure backend token exchange** - never trust client-side tokens
6. **Test on real devices** - emulators may not have full carrier support

## Error Codes to Handle

### Platform-Specific Codes
- `UNAVAILABLE` - Non-Android platform (iOS, Web, macOS, Windows, Linux)
- `NO_ACTIVITY` - Android: No foreground activity available for consent UI
- `INVALID_ARGUMENT` - Empty/null token passed to `enableTestSession()`

### Android-Specific Codes
- `USER_CANCELED` - User declined consent sheet
- `UNSUPPORTED` - Device/carrier doesn't support PNV  
- `CHECK_SUPPORT_FAILED` - Failed to check device support
- `ENABLE_TEST_SESSION_FAILED` - Test session setup failed (e.g., called twice)
- `GET_VERIFIED_PHONE_NUMBER_FAILED` - Verification failed (network, carrier, etc.)
- `NETWORK_ERROR` - Carrier API connectivity issues
- `TIMEOUT` - Verification timed out

## Integration Checklist

- [ ] Firebase project with PNV enabled
- [ ] Android minSdkVersion 24+
- [ ] Google Play Services dependency
- [ ] Backend token exchange endpoint
- [ ] SMS fallback implementation
- [ ] Error handling for all scenarios
- [ ] Test session setup for development
- [ ] Production configuration (Blaze plan, API restrictions)
