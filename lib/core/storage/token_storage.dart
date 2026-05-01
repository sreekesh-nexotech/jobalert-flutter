import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT token pair persisted in encrypted secure storage.
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _kAccess = 'ja_access';
  static const _kRefresh = 'ja_refresh';

  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;
    return AuthTokens(access: access, refresh: refresh);
  }

  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.access);
    await _storage.write(key: _kRefresh, value: tokens.refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (_) => TokenStorage(const FlutterSecureStorage()),
);
