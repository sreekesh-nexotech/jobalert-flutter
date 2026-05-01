import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import 'models/auth_models.dart';

/// All auth-related HTTP calls live here. The repository is intentionally
/// thin — it normalizes payloads, persists tokens, and returns plain DTOs.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
    required String countryCode,
    required String mobileNumber,
  }) async {
    final names = _splitName(fullName);
    final res = await _api.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'password_confirm': password,
        'first_name': names.$1,
        'last_name': names.$2,
        'country_code': countryCode,
        'mobile_number': mobileNumber,
      },
      options: Options(extra: {'skipAuth': true}),
    );
    final data = res.data as Map<String, dynamic>;
    await _persistTokens(data);
    return AppUser.fromJson(_unwrapUser(data));
  }

  Future<AppUser> login({
    required String identifier,
    required String password,
    String countryCode = '',
  }) async {
    final res = await _api.post(
      ApiEndpoints.login,
      data: {
        'identifier': identifier,
        'country_code': countryCode,
        'password': password,
      },
      options: Options(extra: {'skipAuth': true}),
    );
    final data = res.data as Map<String, dynamic>;
    await _persistTokens(data);
    return AppUser.fromJson(_unwrapUser(data));
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {
      // Logout is best-effort: even if the server rejects, clear locally.
    }
    await _tokens.clear();
  }

  Future<void> sendOtp({required String identifier, required OtpPurpose purpose}) async {
    await _api.post(
      ApiEndpoints.otpSend,
      data: {'identifier': identifier, 'purpose': purpose.wire},
      options: Options(extra: {'skipAuth': purpose == OtpPurpose.passwordReset}),
    );
  }

  Future<void> verifyOtp({
    required String identifier,
    required OtpPurpose purpose,
    required String code,
  }) async {
    await _api.post(
      ApiEndpoints.otpVerify,
      data: {
        'identifier': identifier,
        'purpose': purpose.wire,
        'code': code,
      },
      options: Options(extra: {'skipAuth': purpose == OtpPurpose.passwordReset}),
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.post(
      ApiEndpoints.passwordResetRequest,
      data: {'email': email},
      options: Options(extra: {'skipAuth': true}),
    );
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.post(
      ApiEndpoints.passwordResetConfirm,
      data: {'email': email, 'code': code, 'new_password': newPassword},
      options: Options(extra: {'skipAuth': true}),
    );
  }

  Future<void> updateUserDetails({
    String? dateOfBirth,
    Gender? gender,
    String? state,
    String? city,
    List<String>? jobPreferences,
  }) async {
    await _api.post(
      ApiEndpoints.userDetails,
      data: {
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (gender != null) 'gender': gender.wire,
        if (state != null) 'state': state,
        if (city != null) 'city': city,
        if (jobPreferences != null) 'job_preferences': jobPreferences,
      },
    );
  }

  Future<AppUser> fetchMe() async {
    final res = await _api.get(ApiEndpoints.me);
    return AppUser.fromJson(res.data as Map<String, dynamic>);
  }

  // ── helpers ──

  Future<void> _persistTokens(Map<String, dynamic> body) async {
    final access = body['access'] as String?;
    final refresh = body['refresh'] as String?;
    if (access != null && refresh != null) {
      await _tokens.save(AuthTokens(access: access, refresh: refresh));
    }
  }

  Map<String, dynamic> _unwrapUser(Map<String, dynamic> body) {
    final user = body['user'];
    if (user is Map<String, dynamic>) return user;
    return body;
  }

  /// Split "Rahul Sharma" → ("Rahul", "Sharma"); trailing words go into last name.
  (String, String) _splitName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);
