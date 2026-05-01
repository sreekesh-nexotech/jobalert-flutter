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

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  Timer? _ticker;
  int _seconds = 30;
  String _code = '';
  String? _error;
  bool _loading = false;

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
    final email = ref.read(signupFlowProvider).email;
    try {
      await ref.read(authControllerProvider.notifier).sendSignupOtp(email);
      _startTimer();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _submit() async {
    if (_code.length < 6) {
      setState(() => _error = 'Enter all 6 digits');
      return;
    }
    final email = ref.read(signupFlowProvider).email;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).verifySignupOtp(email, _code);
      if (mounted) context.push('/signup/details');
    } on ApiException catch (e) {
      setState(() => _error = e.errorFor('code') ?? e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(signupFlowProvider).email;
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
              Text('Verify your email', style: AppText.screenTitle),
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
              Text('Enter OTP', style: AppText.formLabel),
              const SizedBox(height: 6),
              OtpInputRow(
                controllers: _controllers,
                onChanged: (v) => setState(() {
                  _code = v;
                  _error = null;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: AppText.captionMuted.copyWith(color: AppColors.danger, fontSize: 11),
                ),
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
                              'Resend OTP',
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
              AuthPrimaryButton(
                label: 'Verify & continue',
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
