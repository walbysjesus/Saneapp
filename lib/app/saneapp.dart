import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:saneapp/app/routes.dart';
import 'package:saneapp/shared/themes/app_theme.dart';

class SaneApp extends StatelessWidget {
  const SaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaneApp',
      debugShowCheckedModeBanner: false,

      // Tema global (profesional)
      theme: AppTheme.lightTheme,

      // Rutas centralizadas
      initialRoute: AppRoutes.initialRoute,
      routes: AppRoutes.routes,
    );
  }
}

/// Punto de entrada real de la app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización segura de Firebase
  await Firebase.initializeApp();

  runApp(const SaneApp());
}
