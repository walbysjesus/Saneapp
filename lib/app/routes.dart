import 'package:flutter/material.dart';

// Screens
import 'package:saneapp/features/welcome/welcome_page.dart';
import 'package:saneapp/features/auth/login_page.dart';
import 'package:saneapp/features/auth/register_page.dart';
import 'package:saneapp/features/home/home_page.dart';

class AppRoutes {
  // Nombres de rutas (constantes)
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  // Ruta inicial (ajústala según tu lógica de auth)
  static const String initialRoute = welcome;

  // Mapa de rutas
  static Map<String, WidgetBuilder> routes = {
    welcome: (context) => const WelcomeScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
  };

  // Navegación segura por nombre (opcional pero pro)
  static void navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  static void navigateAndReplace(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  static void navigateAndClear(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
    );
  }
}
