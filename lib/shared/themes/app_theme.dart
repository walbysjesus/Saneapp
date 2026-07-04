import 'package:flutter/material.dart';

/// Tema central de SaneApp
/// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// âœ” Limpio, profesional y listo para producciÃ³n
/// âœ” Centraliza colores, tipografÃ­a y estilos de la app
/// âœ” Facilita mantener coherencia visual en todas las pantallas

class AppTheme {
  AppTheme._(); // Constructor privado, solo acceso estÃ¡tico

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ COLORES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const Color primary = Color(0xFF43A047); // Verde principal
  static const Color secondary = Color(0xFF81C784); // Verde claro
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black87;
  static const Color onBackground = Colors.black87;
  static const Color onSurface = Colors.black87;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ TIPOGRAFÃA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String fontFamily = 'Roboto';

  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: onBackground),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onBackground),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: onBackground),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: onBackground),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: onBackground),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onBackground),
    bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: onBackground),
    bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: onBackground),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onPrimary),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black54),
  );

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ THEME DATA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    fontFamily: fontFamily,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 2,
      centerTitle: true,
    ),
    buttonTheme: const ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      buttonColor: primary,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    // Puedes agregar mÃ¡s parÃ¡metros de ThemeData aquÃ­ si lo necesitas.
  );
}
