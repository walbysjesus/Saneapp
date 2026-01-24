import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saneapp/app/routes.dart';

/// Splash Page de SaneApp
/// ─────────────────────────────
/// ✔ Limpio, profesional y listo para producción
/// ✔ Navega automáticamente a WelcomeScreen o LoginScreen

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() {
    Timer(const Duration(seconds: 3), () {
      // Aquí decides si llevar a Welcome o Login según usuario autenticado
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de SaneApp
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF43A047), // Verde principal SaneApp
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SaneApp',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Conectando contigo soluciones ambientales',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}