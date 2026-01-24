import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saneapp/core/errors/app_exceptions.dart';

/// Servicio centralizado para manejar servicios ambientales en SaneApp
/// ─────────────────────────────
/// ✔ Limpio, escalable y listo para producción
/// ✔ Compatible con Firestore
/// ✔ Maneja excepciones de manera consistente

class EnvironmentalService {
  EnvironmentalService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Nombre de la colección en Firestore
  static const String _collection = 'environmental_services';

  // ─────────────────────────────
  // OBTENER TODOS LOS SERVICIOS
  // ─────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllServices() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      throw UnknownException(message: 'Error al obtener servicios ambientales');
    }
  }

  // ─────────────────────────────
  // OBTENER SERVICIO POR ID
  // ─────────────────────────────
  static Future<Map<String, dynamic>> getServiceById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw UnknownException(message: 'Servicio no encontrado');
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (_) {
      throw UnknownException(message: 'Error al obtener servicio');
    }
  }

  // ─────────────────────────────
  // CREAR NUEVO SERVICIO
  // ─────────────────────────────
  static Future<void> createService(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).add(data);
    } catch (_) {
      throw UnknownException(message: 'Error al crear servicio ambiental');
    }
  }

  // ─────────────────────────────
  // ACTUALIZAR SERVICIO EXISTENTE
  // ─────────────────────────────
  static Future<void> updateService(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (_) {
      throw UnknownException(message: 'Error al actualizar servicio ambiental');
    }
  }

  // ─────────────────────────────
  // ELIMINAR SERVICIO
  // ─────────────────────────────
  static Future<void> deleteService(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (_) {
      throw UnknownException(message: 'Error al eliminar servicio ambiental');
    }
  }
}