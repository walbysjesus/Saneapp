
/// Manejo de excepciones personalizadas para SaneApp
/// ──────────────────────────────
/// ✔ Centraliza errores de la app
/// ✔ Facilita mensajes claros al usuario
/// ✔ Compatible con Firebase, red y validaciones
/// ✔ Listo para producción


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

// ─────────────────────────────
// Errores comunes de la app
// ─────────────────────────────

class NetworkException extends AppException {
  NetworkException({String message = 'Sin conexión a internet'})
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
  UnknownException({String message = 'Ocurrió un error inesperado'})
      : super(message, code: 'UNKNOWN');
}

// ─────────────────────────────
// Uso recomendado
// ─────────────────────────────

// try {
//   await someFirebaseCall();
// } catch (e) {
//   if (e is FirebaseAuthException) {
//     throw FirebaseAuthExceptionCustom(message: e.message ?? 'Error Firebase');
//   } else {
//     throw UnknownException();
//   }
// }