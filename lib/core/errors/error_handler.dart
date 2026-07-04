import 'package:flutter/material.dart';
import 'app_exceptions.dart';

/// Manejo centralizado de errores en SaneApp
/// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// âœ” Muestra errores al usuario de forma clara
/// âœ” Compatible con Firebase, validaciones y red
/// âœ” Evita duplicaciÃ³n de lÃ³gica en pantallas

class ErrorHandler {
  ErrorHandler._();

  /// Muestra un mensaje de error en pantalla
  static void show(BuildContext context, AppException exception) {
    final message = _mapExceptionToMessage(exception);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Convierte excepciones a mensajes legibles para usuario
  static String _mapExceptionToMessage(AppException exception) {
    switch (exception) {
      case NetworkException _:
        return exception.message;
      case FirebaseAuthExceptionCustom _:
        return exception.message;
      case ValidationException _:
        return exception.message;
      case UnknownException _:
        return exception.message;
      default:
        return 'OcurriÃ³ un error inesperado';
    }
  }
}
