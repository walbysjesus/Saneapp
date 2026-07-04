/// Servicio de monetizaciÃ³n y planes premium para SaneApp
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_model.dart';

class MonetizationService {
  static final _db = FirebaseFirestore.instance;

  // Obtener todos los planes activos
  static Future<List<PlanModel>> getActivePlans() async {
    final snap = await _db.collection('plans').where('isActive', isEqualTo: true).get();
    return snap.docs.map((d) => PlanModel.fromMap(d.data(), d.id)).toList();
  }

  // Obtener plan de un usuario/empresa
  static Future<PlanModel?> getPlanForUser(String userId) async {
    final doc = await _db.collection('user_plans').doc(userId).get();
    if (!doc.exists) return null;
    final planId = doc.data()!['planId'];
    final planDoc = await _db.collection('plans').doc(planId).get();
    if (!planDoc.exists) return null;
    return PlanModel.fromMap(planDoc.data()!, planDoc.id);
  }

  // Guardar/actualizar plan de usuario/empresa
  static Future<void> setPlanForUser(String userId, String planId) async {
    await _db.collection('user_plans').doc(userId).set({'planId': planId});
  }

  // Definir comisiÃ³n por cotizaciÃ³n aceptada (puede ser global o por plan)
  // static const double commissionRate = 0.10; // 10%
}

