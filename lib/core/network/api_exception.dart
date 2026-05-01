/// Normalized error returned by the API client.
///
/// The DRF backend wraps errors as `{code, message, errors?}`; this class
/// captures the same shape so the UI layer can render a single message and
/// optionally render per-field validation errors.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors,
  });

  final String message;
  final int? statusCode;
  final int? code;

  /// `field -> [errors]` map, if the server returned per-field validation.
  final Map<String, List<String>>? fieldErrors;

  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isValidation => statusCode == 400 && fieldErrors != null;

  /// Returns the first error string for [field], or `null`.
  String? errorFor(String field) => fieldErrors?[field]?.first;

  @override
  String toString() => message;
}
