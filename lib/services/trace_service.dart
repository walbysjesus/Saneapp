/// Servicio para trazabilidad legal en SaneApp
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_trace.dart';

class TraceService {
  static final _db = FirebaseFirestore.instance;

  // Guardar trazabilidad de servicio
  static Future<void> saveTrace(ServiceTrace trace) async {
    await _db.collection('service_traces').doc(trace.serviceId).set(trace.toMap());
  }

  // Obtener trazabilidad de un servicio
  static Future<ServiceTrace?> getTrace(String serviceId) async {
    final doc = await _db.collection('service_traces').doc(serviceId).get();
    if (!doc.exists) return null;
    return ServiceTrace.fromMap(doc.data()!);
  }
}

