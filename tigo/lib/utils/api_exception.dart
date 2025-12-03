class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: (Status Code: $statusCode) $message';
    }
    return 'ApiException: $message';
  }
}
