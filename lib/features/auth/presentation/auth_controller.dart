import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';
export '../data/models/auth_models.dart' show AppUser, OtpPurpose, Gender;

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user});

  final AuthStatus status;
  final AppUser? user;

  AuthState copyWith({AuthStatus? status, AppUser? user}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._tokens) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthRepository _repo;
  final TokenStorage _tokens;

  Future<void> _bootstrap() async {
    final t = await _tokens.read();
    if (t == null) {
      state = const AuthState(status: AuthStatus.signedOut);
      return;
    }
    try {
      final user = await _repo.fetchMe();
      state = AuthState(status: AuthStatus.signedIn, user: user);
    } catch (_) {
      await _tokens.clear();
      state = const AuthState(status: AuthStatus.signedOut);
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
    String countryCode = '',
  }) async {
    final user = await _repo.login(
      identifier: identifier,
      password: password,
      countryCode: countryCode,
    );
    state = AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String countryCode,
    required String mobileNumber,
  }) async {
    final user = await _repo.register(
      email: email,
      password: password,
      fullName: fullName,
      countryCode: countryCode,
      mobileNumber: mobileNumber,
    );
    state = AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  Future<void> sendSignupOtp(String email) =>
      _repo.sendOtp(identifier: email, purpose: OtpPurpose.signupVerify);

  Future<void> verifySignupOtp(String email, String code) =>
      _repo.verifyOtp(identifier: email, purpose: OtpPurpose.signupVerify, code: code);

  Future<void> requestPasswordReset(String email) =>
      _repo.requestPasswordReset(email);

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _repo.confirmPasswordReset(email: email, code: code, newPassword: newPassword);

  Future<void> updateUserDetails({
    String? dateOfBirth,
    Gender? gender,
    String? state,
  }) =>
      _repo.updateUserDetails(
        dateOfBirth: dateOfBirth,
        gender: gender,
        state: state,
      );
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});
