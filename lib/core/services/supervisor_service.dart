import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/supervisor_model.dart';

/// Asigna un supervisor activo por zona de cobertura
Future<String?> asignarSupervisorPorZona(String zona) async {
  final query = await FirebaseFirestore.instance
      .collection('supervisors')
      .where('zonaCobertura', isEqualTo: zona)
      .where('activo', isEqualTo: true)
      .limit(1)
      .get();
  if (query.docs.isEmpty) return null;
  final supervisor = SupervisorModel.fromMap(query.docs.first.data());
  return supervisor.userId;
}

