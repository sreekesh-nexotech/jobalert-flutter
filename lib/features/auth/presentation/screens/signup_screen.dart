import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_exception.dart';
import '../auth_controller.dart';
import '../widgets/auth_widgets.dart';
import 'signup_flow_state.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _cc = TextEditingController(text: '+91');
  bool _showPw = false;
  bool _loading = false;
  final Map<String, String?> _errs = {};

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _pw.dispose();
    _cc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errs.clear();
      if (_name.text.trim().isEmpty) _errs['name'] = 'Full name is required';
      if (_mobile.text.trim().isEmpty) {
        _errs['mobile'] = 'Mobile is required';
      } else if (!RegExp(r'^\d{10}$').hasMatch(_mobile.text.trim())) {
        _errs['mobile'] = 'Enter a valid 10-digit number';
      }
      if (_email.text.trim().isEmpty) {
        _errs['email'] = 'Email is required';
      } else if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.text.trim())) {
        _errs['email'] = 'Enter a valid email';
      }
      if (_pw.text.isEmpty) {
        _errs['pw'] = 'Password is required';
      } else if (_pw.text.length < 8) {
        _errs['pw'] = 'Minimum 8 characters';
      }
    });
    if (_errs.values.any((v) => v != null)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _email.text.trim(),
            password: _pw.text,
            fullName: _name.text.trim(),
            countryCode: _cc.text.trim(),
            mobileNumber: _mobile.text.trim(),
          );
      // Stash the email so the OTP screen can show it and call /otp/verify/.
      ref.read(signupFlowProvider.notifier).state = SignupFlow(
        email: _email.text.trim(),
        password: _pw.text,
      );
      // Trigger the email OTP send.
      await ref.read(authControllerProvider.notifier).sendSignupOtp(
            _email.text.trim(),
          );
      if (mounted) context.push('/signup/otp');
    } on ApiException catch (e) {
      setState(() {
        _errs['email'] = e.errorFor('email');
        _errs['mobile'] = e.errorFor('mobile_number');
        _errs['pw'] = e.errorFor('password');
        if (_errs.values.every((v) => v == null)) _errs['name'] = e.message;
      });
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
              const StepDots(total: 3, current: 0),
              Text('Create account', style: AppText.screenTitle),
              const SizedBox(height: 4),
              Text(
                "Let's get you set up in just a minute",
                style: AppText.screenSubtitle,
              ),
              const SizedBox(height: 24),
              AuthInput(
                controller: _name,
                label: 'Full name',
                hint: 'Rahul Sharma',
                icon: Icons.person_outline,
                error: _errs['name'],
                onChanged: (_) => setState(() => _errs['name'] = null),
              ),
              const SizedBox(height: 14),
              _mobileRow(),
              const SizedBox(height: 14),
              AuthInput(
                controller: _email,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                error: _errs['email'],
                onChanged: (_) => setState(() => _errs['email'] = null),
              ),
              const SizedBox(height: 14),
              AuthInput(
                controller: _pw,
                label: 'Password',
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
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'Continue',
                loading: _loading,
                onPressed: _submit,
                trailing: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: AppText.screenSubtitle),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Sign in',
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        color: AppColors.blue500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile number', style: AppText.formLabel),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 82,
              child: AuthInput(
                controller: _cc,
                icon: Icons.phone_outlined,
                hint: '+91',
                maxLength: 5,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AuthInput(
                controller: _mobile,
                hint: '9876543210',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                error: _errs['mobile'],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _errs['mobile'] = null),
                padLeft: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
