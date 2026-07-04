import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/quote_model.dart';

/// Enum para roles RBAC
/// Enum de roles estandarizados para SaneApp
enum UserRole {
  generador,
  proveedor,
  supervisor,
  admin,
}

/// Helper para convertir string Firestore a UserRole seguro
UserRole? roleFromString(String? role) {
  switch (role) {
    case 'generador':
      return UserRole.generador;
    case 'proveedor':
      return UserRole.proveedor;
    case 'supervisor':
      return UserRole.supervisor;
    case 'admin':
      return UserRole.admin;
    default:
      return null;
  }
}

/// Enum para estados de solicitud
enum RequestStatus {
  enviada,
  enRevision,
  cotizada,
  enEjecucion,
  finalizada,
}

/// AppState global centralizado para SaneApp
class AppState extends ChangeNotifier {

  UserModel? _currentUser;
  UserRole? _role;
  bool _isLoading = false;
  String? _error;
  final List<RequestModel> _requests = [];
  final Map<String, List<QuoteModel>> _quotesByRequest = {};
  // Locale para internacionalización
  Locale? _locale = const Locale('es');
  Locale? get locale => _locale;
  set locale(Locale? value) {
    _locale = value;
    notifyListeners();
  }
  Future<void> setLocale(Locale? locale) async {
    // Aquí podrías guardar la preferencia en SharedPreferences si quieres persistencia
    _locale = locale;
    notifyListeners();
  }


  // Getters
  UserModel? get currentUser => _currentUser;
  UserRole? get role => _role;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<RequestModel> get requests => _requests;
  Map<String, List<QuoteModel>> get quotesByRequest => _quotesByRequest;
  bool get isAuthenticated => _currentUser != null;
  // Locale getter ya arriba

  // Estado
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Usuario
  void setUser(UserModel? user, UserRole? role) {
    _currentUser = user;
    _role = role;
    _error = null;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _role = null;
    _requests.clear();
    _quotesByRequest.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> fetchQuotesForRequest(String requestId) async {
    if (requestId.isEmpty) return;
    _quotesByRequest.putIfAbsent(requestId, () => <QuoteModel>[]);
    notifyListeners();
  }

  // Helpers RBAC
    bool canCreateRequest() => _role == UserRole.generador;
    bool canViewOwnRequests() =>
      _role == UserRole.generador || _role == UserRole.proveedor;
    bool canQuote() => _role == UserRole.proveedor;
  bool canModerate() => _role == UserRole.admin;
  bool canViewAll() => _role == UserRole.admin;
}
