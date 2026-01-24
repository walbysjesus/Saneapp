import 'package:flutter/material.dart';
import 'package:saneapp/features/welcome/welcome_page.dart';
// import 'package:saneapp/features/auth/register_page.dart';
import 'package:saneapp/features/auth/login_page.dart';
import 'package:saneapp/features/home/home_page.dart'; // Asegúrate de tener este archivo y widget
import 'features/auth/register_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/client_profile_screen.dart';
import 'features/auth/provider_profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(), // Ruta para la pantalla principal
          '/register': (context) => const RegisterScreen(),
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/client-profile': (context) => const ClientProfileScreen(),
          '/provider-profile': (context) => const ProviderProfileScreen(),
      },
    );
  }
}