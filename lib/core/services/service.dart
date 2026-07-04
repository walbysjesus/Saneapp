import 'package:saneapp_pro_nuevo/core/errors/app_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio centralizado para manejar servicios ambientales en SaneApp
/// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// âœ” Limpio, escalable y listo para producciÃ³n
/// âœ” Compatible con Firestore
/// âœ” Maneja excepciones de manera consistente

class EnvironmentalService {
  EnvironmentalService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Nombre de la colecciÃ³n en Firestore
  static const String _collection = 'environmental_services';

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // OBTENER TODOS LOS SERVICIOS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // OBTENER SERVICIO POR ID
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CREAR NUEVO SERVICIO
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> createService(Map<String, dynamic> data) async {
    try {
      // Inicializa flags de calificaciÃ³n
      data['clientRated'] = false;
      data['providerRated'] = false;
      await _firestore.collection(_collection).add(data);
    } catch (_) {
      throw UnknownException(message: 'Error al crear servicio ambiental');
    }
  }

  /// Actualiza el flag de calificaciÃ³n para un servicio
  static Future<void> setRatedFlag(String serviceId, String role) async {
    final flagField = role == 'client_to_provider' ? 'clientRated' : 'providerRated';
    try {
      await _firestore.collection(_collection).doc(serviceId).update({flagField: true});
    } catch (_) {
      throw UnknownException(message: 'Error al actualizar flag de calificaciÃ³n');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ACTUALIZAR SERVICIO EXISTENTE
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> updateService(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (_) {
      throw UnknownException(message: 'Error al actualizar servicio ambiental');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ELIMINAR SERVICIO
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> deleteService(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (_) {
      throw UnknownException(message: 'Error al eliminar servicio ambiental');
    }
  }
}

