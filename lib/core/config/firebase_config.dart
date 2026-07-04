import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio central de Firebase para SaneApp
/// âœ” InicializaciÃ³n Ãºnica
/// âœ” Firebase Auth listo para producciÃ³n
/// âœ” Manejo seguro de errores
/// âœ” Escalable (Firestore, Storage, etc.)
///
/// NO contiene UI
/// NO contiene lÃ³gica de pantallas

class FirebaseService {
  FirebaseService._internal();

  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;

  static FirebaseApp? _app;
  static FirebaseAuth? _auth;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // InicializaciÃ³n de Firebase
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<void> initialize() async {
    if (_app != null) return;

    try {
      _app = await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;

      if (kDebugMode) {
        debugPrint('ðŸ”¥ Firebase inicializado correctamente');
      }
    } catch (e, stack) {
      debugPrint('âŒ Error inicializando Firebase');
      debugPrint(e.toString());
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Firebase Auth
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Auth helpers (limpios y reutilizables)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

