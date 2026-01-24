import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saneapp/core/services/firebase_service.dart';
import 'package:saneapp/core/utils/validators.dart';
import '../../core/errors/app_exceptions.dart';

/// Controlador de autenticación para SaneApp
/// ─────────────────────────────
/// ✔ Centraliza lógica de Register, Login y Logout
/// ✔ Limpio, modular y listo para producción
/// ✔ Preparado para integración con Firebase

class AuthController with ChangeNotifier {
  AuthController._privateConstructor();
  static final AuthController instance = AuthController._privateConstructor();

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Actualiza el estado de carga
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ─────────────────────────────
  // REGISTRAR USUARIO
  // ─────────────────────────────
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      Validators.validateFullName(fullName);
      Validators.validateEmail(email);
      Validators.validatePassword(password);

      final newUser = await FirebaseService.registerUser(
        email: email,
        password: password,
      );

      _user = newUser;

      // Opcional: guardar info adicional en Firestore
      await FirebaseService.createDocument(
        collection: 'users',
        docId: newUser.uid,
        data: {
          'fullName': fullName,
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppException {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────
  // LOGIN USUARIO
  // ─────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      Validators.validateEmail(email);
      Validators.validatePassword(password);

      final loggedUser = await FirebaseService.loginUser(
        email: email,
        password: password,
      );

      _user = loggedUser;
    } on AppException {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────
  // LOGOUT
  // ─────────────────────────────
  Future<void> logout() async {
    _setLoading(true);
    try {
      await FirebaseService.logoutUser();
      _user = null;
    } on AppException {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────
  // VERIFICAR USUARIO ACTUAL
  // ─────────────────────────────
  void checkCurrentUser() {
    _user = FirebaseService.currentUser;
    notifyListeners();
  }
}