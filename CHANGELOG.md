## 1.0.0+2

* Fix relative image links in README.md by using absolute GitHub raw URLs for pub.dev compatibility.

## 1.0.0+1

* Android: `checkSupport()` and `getVerifiedPhoneNumber()` bridging the Firebase Phone Number Verification (PNV) SDK via the Android Credential Manager.
* iOS: stub implementation that returns an `UNAVAILABLE` `PlatformException` for all methods, since Firebase PNV is currently Android-only.
