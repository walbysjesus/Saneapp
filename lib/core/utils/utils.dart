import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Funciones utilitarias para SaneApp
/// ─────────────────────────────
/// ✔ Centraliza funciones reutilizables
/// ✔ Limpio, escalable y listo para producción

class Util {
  Util._();

  // ─────────────────────────────
  // Validaciones de texto
  // ─────────────────────────────

  /// Verifica si el email tiene formato válido
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  /// Verifica si la contraseña cumple longitud mínima
  static bool isValidPassword(String password, {int minLength = 8}) {
    return password.length >= minLength;
  }

  // ─────────────────────────────
  // Formateo de fechas
  // ─────────────────────────────

  /// Convierte DateTime a string legible (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  /// Convierte DateTime a string con hora (dd/MM/yyyy HH:mm)
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  // ─────────────────────────────
  // UI Helpers
  // ─────────────────────────────

  /// Muestra un SnackBar simple
  static void showSnackBar(BuildContext context, String message,
      {Color backgroundColor = Colors.green}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Espaciador vertical
  static Widget verticalSpace(double height) {
    return SizedBox(height: height);
  }

  /// Espaciador horizontal
  static Widget horizontalSpace(double width) {
    return SizedBox(width: width);
  }

  // ─────────────────────────────
  // Conversión de tipos
  // ─────────────────────────────

  /// Convierte dynamic a String seguro
  static String toStringSafe(dynamic value) {
    return value?.toString() ?? '';
  }

  /// Convierte dynamic a int seguro
  static int toIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Convierte dynamic a double seguro
  static double toDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}