import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_exception.dart';
import '../auth_controller.dart';
import '../widgets/auth_widgets.dart';

/// Login — combined hero illustration on top + form below. Identifier field
/// auto-detects mobile vs email and shows a country-code dropdown for phone.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  String _countryCode = '+91';
  bool _showPw = false;
  bool _loading = false;
  String? _idErr;
  String? _pwErr;

  static const _countryCodes = ['+91', '+1', '+44', '+61', '+971', '+65'];

  bool get _isPhone => _id.text.isNotEmpty && RegExp(r'^\d').hasMatch(_id.text);

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _idErr = _id.text.trim().isEmpty ? 'Email or mobile is required' : null;
      _pwErr = _pw.text.isEmpty ? 'Password is required' : null;
    });
    if (_idErr != null || _pwErr != null) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            identifier: _id.text.trim(),
            password: _pw.text,
            countryCode: _isPhone ? _countryCode : '',
          );
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      setState(() {
        _idErr = e.errorFor('identifier') ?? e.message;
        _pwErr = e.errorFor('password');
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
          child: Column(
            children: [
              _Hero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome back 👋', style: AppText.screenTitle),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue to your job feed',
                      style: AppText.screenSubtitle,
                    ),
                    const SizedBox(height: 24),
                    _identifierRow(),
                    const SizedBox(height: 14),
                    AuthInput(
                      controller: _pw,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscure: !_showPw,
                      error: _pwErr,
                      onChanged: (_) => setState(() => _pwErr = null),
                      suffix: IconButton(
                        onPressed: () => setState(() => _showPw = !_showPw),
                        icon: Icon(
                          _showPw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 16,
                          color: AppColors.ink500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot/email'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: AppText.body.copyWith(
                            fontSize: 12,
                            color: AppColors.ink700,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AuthPrimaryButton(
                      label: 'Sign in',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppText.screenSubtitle,
                        ),
                        GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            'Create one',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _identifierRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email or mobile number', style: AppText.formLabel),
        const SizedBox(height: 6),
        Row(
          children: [
            if (_isPhone) ...[
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  border: Border.all(color: AppColors.outlineStrong, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _countryCode,
                    items: _countryCodes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _countryCode = v!),
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: AuthInput(
                controller: _id,
                hint: _isPhone ? '9876543210' : 'you@example.com or 9876543210',
                icon: _isPhone ? Icons.phone_outlined : Icons.mail_outline,
                error: _idErr,
                keyboardType:
                    _isPhone ? TextInputType.phone : TextInputType.emailAddress,
                inputFormatters: _isPhone
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                onChanged: (_) => setState(() => _idErr = null),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 20,
            child: RichText(
              text: TextSpan(
                style: AppText.h2.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02 * 18,
                ),
                children: [
                  const TextSpan(
                    text: 'Job',
                    style: TextStyle(color: AppColors.ink900),
                  ),
                  TextSpan(
                    text: 'Alert',
                    style: TextStyle(color: AppColors.blue500),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SvgPicture.asset(
              'assets/illustrations/illustration.svg',
              width: 220,
            ),
          ),
        ],
      ),
    );
  }
}
