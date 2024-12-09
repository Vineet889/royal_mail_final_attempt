class AddressNowException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AddressNowException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AddressNowException: $message${code != null ? ' (Code: $code)' : ''}';
}

class AddressNowInitializationException extends AddressNowException {
  AddressNowInitializationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class AddressNowNetworkException extends AddressNowException {
  AddressNowNetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
} 