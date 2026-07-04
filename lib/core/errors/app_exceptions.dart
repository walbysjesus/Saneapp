



class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() {
    if (code != null) {
      return 'AppException($code): $message';
    }
    return 'AppException: $message';
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Errores comunes de la app
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class NetworkException extends AppException {
  NetworkException({String message = 'Sin conexiÃ³n a internet'})
      : super(message, code: 'NETWORK');
}

class FirebaseAuthExceptionCustom extends AppException {
  FirebaseAuthExceptionCustom({required String message, String? code})
      : super(message, code: code ?? 'FIREBASE_AUTH');
}

class ValidationException extends AppException {
  ValidationException({required String message})
      : super(message, code: 'VALIDATION');
}

class UnknownException extends AppException {
  UnknownException({String message = 'OcurriÃ³ un error inesperado'})
      : super(message, code: 'UNKNOWN');
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Uso recomendado
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// try {
//   await someFirebaseCall();
// } catch (e) {
//   if (e is FirebaseAuthException) {
//     throw FirebaseAuthExceptionCustom(message: e.message ?? 'Error Firebase');
//   } else {
//     throw UnknownException();
//   }
// }
