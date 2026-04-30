import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

/// Wraps Dio with auth + error normalization.
///
/// The interceptor:
/// 1. attaches the current access token on every request,
/// 2. catches 401 responses, swaps the access token via `/auth/refresh/`,
///    and retries the original request once,
/// 3. surfaces all other errors as [ApiException] with the DRF-style
///    `{code, message, errors}` envelope unpacked.
class ApiClient {
  ApiClient(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) =>
      _safe(() => _dio.get<dynamic>(path, queryParameters: query, options: options));

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) =>
      _safe(() => _dio.post<dynamic>(
            path,
            data: data,
            queryParameters: query,
            options: options,
          ));

  Future<Response<dynamic>> patch(String path, {Object? data}) =>
      _safe(() => _dio.patch<dynamic>(path, data: data));

  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _safe(() => _dio.put<dynamic>(path, data: data));

  Future<Response<dynamic>> delete(String path, {Object? data}) =>
      _safe(() => _dio.delete<dynamic>(path, data: data));

  Future<Response<dynamic>> _safe(Future<Response<dynamic>> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final res = e.response;
    if (res == null) {
      return ApiException(
        message: e.message ?? 'Network error. Please check your connection.',
      );
    }
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      Map<String, List<String>>? fieldErrors;
      if (errors is Map<String, dynamic>) {
        fieldErrors = errors.map(
          (k, v) => MapEntry(
            k,
            v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
          ),
        );
      } else if (data.values.every((v) => v is List || v is String)) {
        // Some endpoints return field errors at the top level.
        fieldErrors = data.map(
          (k, v) => MapEntry(
            k,
            v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
          ),
        );
      }
      return ApiException(
        message: (data['message'] as String?) ??
            fieldErrors?.values.first.first ??
            'Something went wrong.',
        statusCode: res.statusCode,
        code: data['code'] as int?,
        fieldErrors: fieldErrors,
      );
    }
    return ApiException(
      message: 'Request failed (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }
}

/// Provider for the bare Dio instance with the auth-refresh interceptor.
final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  final baseUrl = _resolveBaseUrl();
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skipAuth'] != true) {
          final t = await tokens.read();
          if (t != null) {
            options.headers['Authorization'] = 'Bearer ${t.access}';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 → try one refresh + retry
        final didRetry = error.requestOptions.extra['didRetry'] == true;
        if (error.response?.statusCode == 401 && !didRetry) {
          final t = await tokens.read();
          if (t != null) {
            try {
              final res = await Dio(
                BaseOptions(baseUrl: baseUrl),
              ).post<Map<String, dynamic>>(
                ApiEndpoints.refresh,
                data: {'refresh': t.refresh},
              );
              final newAccess = res.data?['access'] as String?;
              if (newAccess != null) {
                await tokens.save(
                  AuthTokens(access: newAccess, refresh: t.refresh),
                );
                final retry = error.requestOptions
                  ..headers['Authorization'] = 'Bearer $newAccess'
                  ..extra['didRetry'] = true;
                final response = await dio.fetch<dynamic>(retry);
                return handler.resolve(response);
              }
            } on DioException catch (_) {
              await tokens.clear();
            }
          }
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);

/// Allow overriding the base URL via `--dart-define=API_BASE_URL=…` at build
/// time. Defaults to the deployed JobAlert API on `jobalertapp.nexogms.com`.
const _kDefaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://jobalertapp.nexogms.com/api/v1',
);

String _resolveBaseUrl() => _kDefaultBaseUrl;
