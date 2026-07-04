import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class RoleGuard extends StatelessWidget {
  final UserRole requiredRole;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.role;
    if (userRole == requiredRole) {
      return child;
    }
    return fallback ?? Scaffold(
      body: Center(
        child: Text('Acceso denegado: solo para rol "${requiredRole.name}"'),
      ),
    );
  }
}
