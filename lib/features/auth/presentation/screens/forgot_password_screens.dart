import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_exception.dart';
import '../auth_controller.dart';
import '../widgets/auth_widgets.dart';
import 'signup_flow_state.dart';

/// Step 1 — collect the user's email and trigger the reset OTP send.
class FpEmailScreen extends ConsumerStatefulWidget {
  const FpEmailScreen({super.key});

  @override
  ConsumerState<FpEmailScreen> createState() => _FpEmailScreenState();
}

class _FpEmailScreenState extends ConsumerState<FpEmailScreen> {
  final _email = TextEditingController();
  String? _err;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _err = 'Email is required');
      return;
    }
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      setState(() => _err = 'Enter a valid email address');
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).requestPasswordReset(email);
      ref.read(forgotEmailProvider.notifier).state = email;
      if (mounted) context.push('/forgot/otp');
    } on ApiException catch (e) {
      setState(() => _err = e.errorFor('email') ?? e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackRow(onBack: () => context.pop(), label: 'Back to sign in'),
              const StepDots(total: 3, current: 0),
              Text('Forgot password?', style: AppText.screenTitle),
              const SizedBox(height: 4),
              Text(
                "Enter your registered email and we'll send a reset code",
                style: AppText.screenSubtitle,
              ),
              const SizedBox(height: 24),
              AuthInput(
                controller: _email,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                error: _err,
                onChanged: (_) => setState(() => _err = null),
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'Send reset code',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2 — collect the 6-digit reset code. Identical UX to signup OTP but
/// we hold the entered code in `forgotCodeProvider` so the next step (set new
/// password) can submit both together to `/auth/password-reset/confirm/`.
final forgotCodeProvider = StateProvider<String>((_) => '');

class FpOtpScreen extends ConsumerStatefulWidget {
  const FpOtpScreen({super.key});

  @override
  ConsumerState<FpOtpScreen> createState() => _FpOtpScreenState();
}

class _FpOtpScreenState extends ConsumerState<FpOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  Timer? _ticker;
  int _seconds = 30;
  String _code = '';
  String? _err;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _ticker?.cancel();
    setState(() => _seconds = 30);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _resend() async {
    final email = ref.read(forgotEmailProvider);
    try {
      await ref.read(authControllerProvider.notifier).requestPasswordReset(email);
      _startTimer();
    } on ApiException catch (e) {
      setState(() => _err = e.message);
    }
  }

  void _next() {
    if (_code.length < 6) {
      setState(() => _err = 'Enter all 6 digits');
      return;
    }
    ref.read(forgotCodeProvider.notifier).state = _code;
    context.push('/forgot/new');
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(forgotEmailProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackRow(onBack: () => context.pop()),
              const StepDots(total: 3, current: 1),
              Text('Check your email', style: AppText.screenTitle),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppText.screenSubtitle,
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: email.isEmpty ? 'your email' : email,
                      style: AppText.screenSubtitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Reset code', style: AppText.formLabel),
              const SizedBox(height: 6),
              OtpInputRow(
                controllers: _controllers,
                onChanged: (v) => setState(() {
                  _code = v;
                  _err = null;
                }),
              ),
              if (_err != null) ...[
                const SizedBox(height: 4),
                Text(_err!, style: AppText.captionMuted.copyWith(color: AppColors.danger, fontSize: 11)),
              ],
              const SizedBox(height: 14),
              Center(
                child: _seconds > 0
                    ? RichText(
                        text: TextSpan(
                          style: AppText.screenSubtitle,
                          children: [
                            const TextSpan(text: 'Resend code in '),
                            TextSpan(
                              text: '${_seconds}s',
                              style: AppText.screenSubtitle.copyWith(
                                color: AppColors.ink900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Didn't get it? ", style: AppText.screenSubtitle),
                          GestureDetector(
                            onTap: _resend,
                            child: Text(
                              'Resend code',
                              style: AppText.body.copyWith(
                                fontSize: 13,
                                color: AppColors.blue500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(label: 'Verify code', onPressed: _next),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 3 — collect & confirm the new password, then submit the bundle to
/// `/auth/password-reset/confirm/`.
class FpNewPwScreen extends ConsumerStatefulWidget {
  const FpNewPwScreen({super.key});

  @override
  ConsumerState<FpNewPwScreen> createState() => _FpNewPwScreenState();
}

class _FpNewPwScreenState extends ConsumerState<FpNewPwScreen> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPw = false;
  bool _showConfirm = false;
  bool _loading = false;
  final Map<String, String?> _errs = {};

  int get _strength {
    final l = _pw.text.length;
    if (l == 0) return 0;
    if (l < 6) return 1;
    if (l < 10) return 2;
    return 3;
  }

  static const _strengthLabels = ['', 'Weak', 'Good', 'Strong'];
  static const _strengthColors = [
    Colors.transparent,
    AppColors.danger,
    AppColors.warning,
    AppColors.success,
  ];

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errs.clear();
      if (_pw.text.isEmpty) {
        _errs['pw'] = 'New password is required';
      } else if (_pw.text.length < 8) {
        _errs['pw'] = 'Minimum 8 characters';
      }
      if (_confirm.text.isEmpty) {
        _errs['confirm'] = 'Please confirm your password';
      } else if (_pw.text != _confirm.text) {
        _errs['confirm'] = 'Passwords do not match';
      }
    });
    if (_errs.values.any((v) => v != null)) return;

    final email = ref.read(forgotEmailProvider);
    final code = ref.read(forgotCodeProvider);
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).confirmPasswordReset(
            email: email,
            code: code,
            newPassword: _pw.text,
          );
      if (mounted) context.go('/forgot/done');
    } on ApiException catch (e) {
      setState(() => _errs['pw'] = e.errorFor('new_password') ?? e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BackRow(onBack: () => context.pop()),
              const StepDots(total: 3, current: 2),
              Text('Set new password', style: AppText.screenTitle),
              const SizedBox(height: 4),
              Text(
                "Choose a strong password you haven't used before",
                style: AppText.screenSubtitle,
              ),
              const SizedBox(height: 24),
              AuthInput(
                controller: _pw,
                label: 'New password',
                hint: 'Min. 8 characters',
                icon: Icons.lock_outline,
                obscure: !_showPw,
                error: _errs['pw'],
                onChanged: (_) => setState(() => _errs['pw'] = null),
                suffix: IconButton(
                  onPressed: () => setState(() => _showPw = !_showPw),
                  icon: Icon(
                    _showPw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.ink500,
                  ),
                ),
              ),
              if (_pw.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              Container(height: 3, color: AppColors.outline),
                              FractionallySizedBox(
                                widthFactor: _strength / 3,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 3,
                                  color: _strengthColors[_strength],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _strengthLabels[_strength],
                        style: AppText.captionMuted.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _strengthColors[_strength],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              AuthInput(
                controller: _confirm,
                label: 'Confirm password',
                hint: 'Re-enter your password',
                icon: Icons.lock_outline,
                obscure: !_showConfirm,
                error: _errs['confirm'],
                onChanged: (_) => setState(() => _errs['confirm'] = null),
                suffix: IconButton(
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.ink500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'Reset password',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
