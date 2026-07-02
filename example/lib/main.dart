import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_pnv/firebase_pnv.dart';

void main() {
  runApp(const MyApp());
}

// ============================================================================
// Neobrutalist design tokens.
// ============================================================================

/// Shared neobrutalist design constants: stark black borders, harsh offset
/// shadows, bold flat colors, and no rounded softness.
class _NeoStyle {
  static const Color ink = Color(0xFF0A0A0A);
  static const Color bg = Color(0xFFF5F1E8);
  static const Color yellow = Color(0xFFFFD400);
  static const Color green = Color(0xFF00E676);
  static const Color pink = Color(0xFFFF5C8A);
  static const Color red = Color(0xFFFF3B30);
  static const Color card = Color(0xFFFFFFFF);

  static BoxDecoration block({
    Color color = card,
    double borderWidth = 3,
    Offset shadowOffset = const Offset(6, 6),
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: ink, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: ink,
          offset: shadowOffset,
          blurRadius: 0,
        ),
      ],
    );
  }
}

// ============================================================================
// Verification flow status - state logic, kept separate from the UI below.
// ============================================================================

enum _VerificationStep { idle, loading, unsupported, success, error }

/// Holds the outcome of a verification attempt, decoupled from any widget.
class _VerificationState {
  const _VerificationState({
    this.step = _VerificationStep.idle,
    this.phoneNumber,
    this.token,
    this.errorMessage,
  });

  final _VerificationStep step;
  final String? phoneNumber;
  final String? token;
  final String? errorMessage;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _firebasePnv = FirebasePnv();
  _VerificationState _state = const _VerificationState();

  bool get _isLoading => _state.step == _VerificationStep.loading;

  /// Runs the recommended PNV flow:
  /// 1. checkSupport() - cheap, consent-free capability check.
  /// 2. If supported, getVerifiedPhoneNumber() - shows the Credential
  ///    Manager consent sheet and verifies via the carrier.
  /// 3. If unsupported, surface a banner telling the caller to fall back to
  ///    SMS-based verification (e.g. firebase_auth).
  Future<void> _startVerification() async {
    setState(() => _state = const _VerificationState(step: _VerificationStep.loading));

    final bool supported = await _firebasePnv.checkSupport();
    if (!mounted) return;

    if (!supported) {
      setState(
        () => _state = const _VerificationState(step: _VerificationStep.unsupported),
      );
      return;
    }

    try {
      final result = await _firebasePnv.getVerifiedPhoneNumber();
      if (!mounted) return;
      setState(
        () => _state = _VerificationState(
          step: _VerificationStep.success,
          phoneNumber: result?['phoneNumber']?.toString(),
          token: result?['token']?.toString(),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(
        () => _state = _VerificationState(
          step: _VerificationStep.error,
          errorMessage: e.message ?? e.code,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _NeoStyle.bg,
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      home: _HomeScreen(
        state: _state,
        isLoading: _isLoading,
        onVerifyPressed: _startVerification,
      ),
    );
  }
}

// ============================================================================
// UI layer - purely presentational, driven entirely by _VerificationState.
// ============================================================================

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.state,
    required this.isLoading,
    required this.onVerifyPressed,
  });

  final _VerificationState state;
  final bool isLoading;
  final VoidCallback onVerifyPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeaderBanner(),
                  const SizedBox(height: 24),
                  _VerifyButton(onPressed: isLoading ? null : onVerifyPressed),
                  const SizedBox(height: 24),
                  if (state.step == _VerificationStep.unsupported)
                    const _AlertBanner(
                      color: _NeoStyle.red,
                      title: 'PNV NOT SUPPORTED',
                      message:
                          'This device/SIM cannot verify via carrier. Fall back to '
                          'SMS OTP verification (e.g. firebase_auth) instead.',
                    ),
                  if (state.step == _VerificationStep.error)
                    _AlertBanner(
                      color: _NeoStyle.red,
                      title: 'VERIFICATION FAILED',
                      message: state.errorMessage ?? 'Unknown error.',
                    ),
                  if (state.step == _VerificationStep.success)
                    _ResultBlock(
                      phoneNumber: state.phoneNumber ?? '-',
                      token: state.token ?? '-',
                    ),
                ],
              ),
            ),
            // Loading overlay: obscures the UI so the native Credential
            // Manager bottom sheet takes visual focus.
            if (isLoading) const _LoadingOverlay(),
          ],
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _NeoStyle.block(color: _NeoStyle.yellow),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIREBASE PNV',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _NeoStyle.ink,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'NO SMS. NO OTP. JUST YOUR SIM.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _NeoStyle.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: _NeoStyle.block(
          color: enabled ? _NeoStyle.green : _NeoStyle.card,
          shadowOffset: enabled ? const Offset(6, 6) : const Offset(2, 2),
        ),
        alignment: Alignment.center,
        child: Text(
          enabled ? 'VERIFY PHONE' : 'WORKING...',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _NeoStyle.ink,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.color,
    required this.title,
    required this.message,
  });

  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _NeoStyle.block(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _NeoStyle.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: _NeoStyle.ink),
          ),
        ],
      ),
    );
  }
}

/// Displays the verified phone number and PNV token in a copyable block,
/// so it can be quickly shared with beta testers for backend debugging.
class _ResultBlock extends StatelessWidget {
  const _ResultBlock({required this.phoneNumber, required this.token});

  final String phoneNumber;
  final String token;

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _NeoStyle.block(color: _NeoStyle.pink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VERIFIED ✓',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _NeoStyle.ink,
            ),
          ),
          const SizedBox(height: 16),
          _CopyableField(
            label: 'PHONE NUMBER',
            value: phoneNumber,
            onCopy: () => _copy(context, 'Phone number', phoneNumber),
          ),
          const SizedBox(height: 12),
          _CopyableField(
            label: 'TOKEN',
            value: token,
            onCopy: () => _copy(context, 'Token', token),
          ),
        ],
      ),
    );
  }
}

class _CopyableField extends StatelessWidget {
  const _CopyableField({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _NeoStyle.ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: _NeoStyle.block(
            color: _NeoStyle.card,
            borderWidth: 2,
            shadowOffset: const Offset(3, 3),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 13, color: _NeoStyle.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: _NeoStyle.ink),
                onPressed: onCopy,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A full-screen glass-like overlay shown while a PNV call is in flight, so
/// the native Credential Manager bottom sheet has undivided visual focus.
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: _NeoStyle.ink.withValues(alpha: 0.85),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: _NeoStyle.block(color: _NeoStyle.yellow),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: _NeoStyle.ink,
                  strokeWidth: 4,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'AWAITING CARRIER\nVERIFICATION...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _NeoStyle.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
