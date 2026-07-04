import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  Future<String?> _getNextRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '/login';
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null || !data.containsKey('role')) {
      return '/role-selection';
    }
    switch (data['role']) {
      case 'generador':
        if (data['clientProfileCompleted'] != true) {
          return '/client-profile';
        }
        return '/home_generador';
      case 'proveedor':
        return '/provider_main';
      case 'supervisor':
        final profileCompleted = data['supervisorProfileCompleted'] == true;
        final status = data['status'] as String?;
        if ((status == 'active' || status == 'prequalified') &&
            profileCompleted) {
          return '/supervisor-dashboard';
        }
        if (profileCompleted) {
          return '/supervisor-application-status';
        }
        return '/supervisor-profile-setup';
      case 'admin':
        return '/admin-dashboard';
      default:
        return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getNextRoute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final route = snapshot.data;
        final currentRoute = ModalRoute.of(context)?.settings.name;
        // Si no hay usuario y estamos en '/', mostrar WelcomeScreen sin redirigir
        if (route == '/login' && currentRoute == '/') {
          return child;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentRoute != route) {
            Navigator.pushReplacementNamed(context, route!);
          }
        });
        return child;
      },
    );
  }
}
