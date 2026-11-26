import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/lineup_logo.dart';

/// Phone-number OTP sign in / sign up — the real deployed app asks for a
/// WhatsApp number and sends a 6-digit code, so this matches that flow
/// against the real Firebase project (see lib/firebase_options.dart).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  ConfirmationResult? _confirmation;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    var number = _phone.text.trim();
    if (number.isEmpty) return;
    // Existing accounts look like +91XXXXXXXXXX; default a 10-digit input to +91.
    if (!number.startsWith('+')) number = '+91$number';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await FirebaseAuth.instance.signInWithPhoneNumber(number);
      setState(() => _confirmation = result);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Could not send the code.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final c = _confirmation;
    if (c == null || _code.text.trim().length < 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.confirm(_code.text.trim());
      // On success, AuthGate's authStateChanges listener takes over.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Invalid code.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final awaitingCode = _confirmation != null;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LineUpLogo(size: 56, isDark: true, showShadow: true),
                  const SizedBox(height: 16),
                  const Text(
                    'LineUp',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI agents for your business',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign in or sign up',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          awaitingCode
                              ? 'Enter the 6-digit code we sent to your WhatsApp.'
                              : "Enter your WhatsApp number. We'll send you a 6-digit code.",
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                        const SizedBox(height: 14),
                        if (!awaitingCode)
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.smartphone, color: AppColors.textSecondary),
                              hintText: 'WhatsApp number',
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            onSubmitted: (_) => _sendCode(),
                          )
                        else
                          TextField(
                            controller: _code,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                              hintText: '••••••',
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            onSubmitted: (_) => _verify(),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _busy ? null : (awaitingCode ? _verify : _sendCode),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: const StadiumBorder(),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(awaitingCode ? 'Verify' : 'Send code'),
                          ),
                        ),
                        if (awaitingCode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _confirmation = null;
                                        _code.clear();
                                        _error = null;
                                      }),
                              child: const Text('Use a different number', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'By continuing you agree to our Terms and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
