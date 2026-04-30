import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tiny session-only holder for the signup flow — passes the email and
/// password between Signup → OTP → Details so each screen does not need to
/// re-fetch them.
class SignupFlow {
  const SignupFlow({this.email = '', this.password = ''});
  final String email;
  final String password;
}

final signupFlowProvider = StateProvider<SignupFlow>((_) => const SignupFlow());

/// Mirror for the password-reset flow (email entered → OTP screen).
final forgotEmailProvider = StateProvider<String>((_) => '');
