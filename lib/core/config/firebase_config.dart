import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio central de Firebase para SaneApp
/// ✔ Inicialización única
/// ✔ Firebase Auth listo para producción
/// ✔ Manejo seguro de errores
/// ✔ Escalable (Firestore, Storage, etc.)
///
/// NO contiene UI
/// NO contiene lógica de pantallas

class FirebaseService {
  FirebaseService._internal();

  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;

  static FirebaseApp? _app;
  static FirebaseAuth? _auth;

  // ─────────────────────────────────────────────
  // Inicialización de Firebase
  // ─────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_app != null) return;

    try {
      _app = await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;

      if (kDebugMode) {
        debugPrint('🔥 Firebase inicializado correctamente');
      }
    } catch (e, stack) {
      debugPrint('❌ Error inicializando Firebase');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // Firebase Auth
  // ─────────────────────────────────────────────

  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception(
        'Firebase no inicializado. Llama a FirebaseService.initialize() primero.',
      );
    }
    return _auth!;
  }

  static User? get currentUser => auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  // ─────────────────────────────────────────────
  // Auth helpers (limpios y reutilizables)
  // ─────────────────────────────────────────────

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() async {
    await auth.signOut();
  }
}
