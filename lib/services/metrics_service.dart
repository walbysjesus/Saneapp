/// Servicio para mÃ©tricas e inteligencia interna en SaneApp
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_metrics.dart';

class MetricsService {
  static final _db = FirebaseFirestore.instance;

  // Obtener mÃ©tricas de una empresa
  static Future<CompanyMetrics?> getMetrics(String companyId) async {
    final doc = await _db.collection('company_metrics').doc(companyId).get();
    if (!doc.exists) return null;
    return CompanyMetrics.fromMap(doc.data()!);
  }

  // Guardar/actualizar mÃ©tricas
  static Future<void> saveMetrics(CompanyMetrics metrics) async {
    await _db.collection('company_metrics').doc(metrics.companyId).set(metrics.toMap());
  }
}

