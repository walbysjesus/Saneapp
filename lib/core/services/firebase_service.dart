import 'package:saneapp_pro_nuevo/core/errors/app_exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio centralizado de Firebase para SaneApp
/// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// âœ” Maneja Auth y Firestore
/// âœ” Excepciones centralizadas
/// âœ” Limpio y listo para producciÃ³n

class FirebaseService {
  FirebaseService._();

  // Firebase Auth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore instance
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // AUTH
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Registra un usuario con email y password
  static Future<User> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionCustom(message: e.message ?? 'Error Firebase', code: e.code);
    } catch (_) {
      throw UnknownException();
    }
  }

  /// Inicia sesiÃ³n con email y password
  static Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptionCustom(message: e.message ?? 'Error Firebase', code: e.code);
    } catch (_) {
      throw UnknownException();
    }
  }

  /// Cierra sesiÃ³n del usuario actual
  static Future<void> logoutUser() async {
    try {
      await _auth.signOut();
    } catch (_) {
      throw UnknownException(message: 'Error al cerrar sesiÃ³n');
    }
  }

  /// Devuelve el usuario actualmente logueado
  static User? get currentUser => _auth.currentUser;

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // FIRESTORE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Crea un documento en Firestore
  static Future<void> createDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (_) {
      throw UnknownException(message: 'Error al guardar informaciÃ³n');
    }
  }

  /// Obtiene un documento de Firestore
  static Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (_) {
      throw UnknownException(message: 'Error al obtener informaciÃ³n');
    }
  }

  /// Actualiza un documento en Firestore
  static Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (_) {
      throw UnknownException(message: 'Error al actualizar informaciÃ³n');
    }
  }
}

