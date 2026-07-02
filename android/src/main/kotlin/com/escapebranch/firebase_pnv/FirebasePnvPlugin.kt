package com.escapebranch.firebase_pnv

import android.app.Activity
import com.google.firebase.pnv.FirebasePhoneNumberVerification
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Native Android implementation of the `firebase_pnv` Flutter plugin.
 *
 * Firebase Phone Number Verification (PNV) requires a foreground [Activity]
 * in order to launch the Android Credential Manager consent bottom sheet, so
 * this class implements [ActivityAware] and defers all SDK usage until an
 * activity is attached. The [FirebasePhoneNumberVerification] instance
 * itself does not require an activity to be constructed, but calls that
 * present UI (namely `getVerifiedPhoneNumber`) do.
 */
class FirebasePnvPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel

    /** The currently attached foreground activity, if any. */
    private var activity: Activity? = null

    /** Lazily created once, reused across calls. */
    private val fpnv: FirebasePhoneNumberVerification by lazy {
        FirebasePhoneNumberVerification.getInstance()
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "firebase_pnv")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // region ActivityAware
    //
    // Firebase PNV's `getVerifiedPhoneNumber` call presents the Android
    // Credential Manager consent UI, which requires a foreground Activity.
    // We must never attempt to initialize/use the SDK from
    // `onAttachedToEngine` alone, because at that point no Activity is
    // guaranteed to exist (e.g. background execution, headless engines).

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
    // endregion

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "enableTestSession" -> enableTestSession(call, result)
            "checkSupport" -> checkSupport(result)
            "getVerifiedPhoneNumber" -> getVerifiedPhoneNumber(result)
            else -> result.notImplemented()
        }
    }

    private fun enableTestSession(
        call: MethodCall,
        result: Result
    ) {
        val token = call.argument<String>("token")
        if (token.isNullOrEmpty()) {
            result.error(
                "INVALID_ARGUMENT",
                "enableTestSession requires a non-empty 'token' argument.",
                null
            )
            return
        }

        try {
            // The underlying SDK only allows this to be called once per
            // FirebasePhoneNumberVerification instance; subsequent calls throw.
            fpnv.enableTestSession(token)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "ENABLE_TEST_SESSION_FAILED",
                e.message ?: "Failed to enable Firebase PNV test session.",
                null
            )
        }
    }

    private fun checkSupport(result: Result) {
        fpnv
            .getVerificationSupportInfo()
            .addOnSuccessListener { results ->
                val supported = results.any { it.isSupported() }
                result.success(supported)
            }.addOnFailureListener { e ->
                result.error(
                    "CHECK_SUPPORT_FAILED",
                    e.message ?: "Failed to check Firebase PNV support.",
                    null
                )
            }
    }

    private fun getVerifiedPhoneNumber(result: Result) {
        val currentActivity =
            activity ?: run {
                result.error(
                    "NO_ACTIVITY",
                    "Firebase PNV requires a foreground activity to display the " +
                        "consent UI, but none is currently attached.",
                    null
                )
                return
            }

        fpnv
            .getVerifiedPhoneNumber(currentActivity)
            .addOnSuccessListener { verificationResult ->
                result.success(
                    mapOf(
                        "phoneNumber" to verificationResult.getPhoneNumber(),
                        "token" to verificationResult.getToken()
                    )
                )
            }.addOnFailureListener { e ->
                result.error(
                    "GET_VERIFIED_PHONE_NUMBER_FAILED",
                    e.message ?: "Failed to verify phone number via Firebase PNV.",
                    null
                )
            }
    }
}
