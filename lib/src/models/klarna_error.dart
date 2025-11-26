/// Klarna error codes
enum KlarnaErrorCode {
  unknown,
  cancelled,
  invalidConfiguration,
  networkError,
  authorizationFailed,
  sessionExpired,
}

/// Klarna error model
class KlarnaError {
  final KlarnaErrorCode code;
  final String message;
  final bool isFatal;
  final String? debugMessage;

  KlarnaError({
    required this.code,
    required this.message,
    this.isFatal = false,
    this.debugMessage,
  });

  factory KlarnaError.fromMap(Map<dynamic, dynamic> map) {
    final codeString = map['code'] as String? ?? 'unknown';
    KlarnaErrorCode code;

    switch (codeString.toLowerCase()) {
      case 'cancelled':
        code = KlarnaErrorCode.cancelled;
        break;
      case 'invalidconfiguration':
        code = KlarnaErrorCode.invalidConfiguration;
        break;
      case 'networkerror':
        code = KlarnaErrorCode.networkError;
        break;
      case 'authorizationfailed':
        code = KlarnaErrorCode.authorizationFailed;
        break;
      case 'sessionexpired':
        code = KlarnaErrorCode.sessionExpired;
        break;
      default:
        code = KlarnaErrorCode.unknown;
    }

    return KlarnaError(
      code: code,
      message: map['message'] as String? ?? 'Unknown error',
      isFatal: map['isFatal'] as bool? ?? false,
      debugMessage: map['debugMessage'] as String?,
    );
  }

  @override
  String toString() {
    return 'KlarnaError(code: $code, message: $message, isFatal: $isFatal${debugMessage != null ? ', debugMessage: $debugMessage' : ''})';
  }
}
