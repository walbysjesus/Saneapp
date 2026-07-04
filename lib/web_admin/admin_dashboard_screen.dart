import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Web Admin')),
      body: Center(
        child: Text('Bienvenido al panel administrativo web.'),
      ),
    );
  }
}

