import 'package:flutter/material.dart';
import 'package:saneapp/features/auth/models/user_model.dart';

/// Estado global de SaneApp
/// ─────────────────────────────
/// ✔ Maneja información compartida de la app
/// ✔ Compatible con Provider, Riverpod o setState
/// ✔ Limpio y listo para producción

class AppState extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  // ──────────────── GETTERS ────────────────
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // ──────────────── SETTERS ────────────────
  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ──────────────── MÉTODOS ADICIONALES ────────────────
  bool get isAuthenticated => _currentUser != null;

  void updateUser(UserModel updatedUser) {
    if (_currentUser != null) {
      _currentUser = updatedUser;
      notifyListeners();
    }
  }
}