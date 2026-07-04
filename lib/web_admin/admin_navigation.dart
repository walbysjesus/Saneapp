import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';

class AdminNavigation extends StatelessWidget {
  const AdminNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      home: const AdminDashboardScreen(),
      routes: {
        '/dashboard': (_) => const AdminDashboardScreen(),
        // Agrega aquí más rutas para el panel admin
      },
    );
  }
}

