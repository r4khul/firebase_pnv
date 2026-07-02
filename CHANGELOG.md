## 0.0.1

* Initial release.
* Android: `checkSupport()` and `getVerifiedPhoneNumber()` bridging the Firebase Phone Number Verification (PNV) SDK via the Android Credential Manager.
* iOS: stub implementation that returns an `UNAVAILABLE` `PlatformException` for all methods, since Firebase PNV is currently Android-only.
