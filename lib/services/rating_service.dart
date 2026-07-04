import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de calificaciones para SaneApp
/// - Valida estado 'completed'
/// - Impide doble calificaciÃ³n por rol
/// - Guarda calificaciÃ³n y actualiza flags y promedios
class RatingService {
  static final _firestore = FirebaseFirestore.instance;
  static final _ratingsCol = _firestore.collection('ratings');
  static final _servicesCol = _firestore.collection('environmental_services');
  static final _usersCol = _firestore.collection('users');

  /// Crea una calificaciÃ³n para un servicio
  static Future<void> rateService({
    required String serviceId,
    required String fromUserId,
    required String toUserId,
    required String role, // 'client_to_provider' o 'provider_to_client'
    required int stars,
    String? comment,
  }) async {
    // Validar estrellas
    if (stars < 1 || stars > 5) {
      throw Exception('La calificaciÃ³n debe ser entre 1 y 5 estrellas.');
    }

    // Validar estado del servicio
    final serviceSnap = await _servicesCol.doc(serviceId).get();
    if (!serviceSnap.exists) {
      throw Exception('Servicio no encontrado.');
    }
    final service = serviceSnap.data()!;
    if (service['status'] != 'completed') {
      throw Exception('Solo puedes calificar servicios completados.');
    }

    // Impedir doble calificaciÃ³n por rol
    final existing = await _ratingsCol
        .where('serviceId', isEqualTo: serviceId)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('role', isEqualTo: role)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Ya has calificado este servicio.');
    }

    // Guardar calificaciÃ³n
    final ratingData = {
      'serviceId': serviceId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'role': role,
      'stars': stars,
      'comment': comment ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _ratingsCol.add(ratingData);

    // Actualizar flags en el servicio
    final flagField = role == 'client_to_provider' ? 'clientRated' : 'providerRated';
    await _servicesCol.doc(serviceId).update({flagField: true});

    // Actualizar rating promedio y cantidad en el usuario calificado
    final userRef = _usersCol.doc(toUserId);
    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final prevCount = (userSnap.data()?['ratingCount'] ?? 0) as int;
      final prevAvg = (userSnap.data()?['ratingAverage'] ?? 0.0) as num;
      final newCount = prevCount + 1;
      final newAvg = ((prevAvg * prevCount) + stars) / newCount;
      tx.update(userRef, {
        'ratingCount': newCount,
        'ratingAverage': newAvg,
      });
    });
  }
}

