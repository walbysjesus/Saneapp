/// Modelo de Solicitud para SaneApp
/// Listo para integraciÃ³n con Firestore y lÃ³gica de negocio
library;
import 'package:flutter/foundation.dart';
import '../state/app_state.dart';

class RequestModel {
  /// ID Ãºnico de la solicitud
  final String id;
  /// ID del usuario generador
  final String userId;
  /// ID de la empresa (opcional)
  final String? companyId;
  /// Tipo de servicio solicitado
  final String service;
  /// Fecha de creaciÃ³n o solicitud
  final DateTime date;
  /// Estado principal de la solicitud
  final RequestStatus status;

  // --- Supervisor y estados avanzados ---
  /// Â¿SolicitÃ³ supervisor?
  final bool supervisorRequested;
  /// Tipo de supervisiÃ³n: puntual | completo
  final String? supervisorType;
  /// Costo de la supervisiÃ³n
  final double supervisorCost;
  /// Estado del supervisor (ver solicitud_status.dart)
  final String? supervisorStatus;
  /// ID del supervisor asignado
  final String? supervisorId;
  /// URL del informe/firma/foto del supervisor
  final String? supervisorReportUrl;

  /// Constructor principal del modelo de solicitud
  RequestModel({
    required this.id,
    required this.userId,
    this.companyId,
    required this.service,
    required this.date,
    required this.status,
    this.supervisorRequested = false,
    this.supervisorType,
    this.supervisorCost = 0.0,
    this.supervisorStatus,
    this.supervisorId,
    this.supervisorReportUrl,
  });

  /// Crea una instancia desde un Map (Firestore/JSON)
  /// Permite valores nulos para compatibilidad retroactiva
  factory RequestModel.fromMap(Map<String, dynamic> map, String id) {
    return RequestModel(
      id: id,
      userId: map['userId'] ?? '',
      companyId: map['companyId'],
      service: map['service'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      status: RequestStatus.values.firstWhere(
        (e) => describeEnum(e) == map['status'],
        orElse: () => RequestStatus.enviada,
      ),
      supervisorRequested: map['supervisorRequested'] ?? false,
      supervisorType: map['supervisorType'],
      supervisorCost: (map['supervisorCost'] ?? 0).toDouble(),
      supervisorStatus: map['supervisorStatus'],
      supervisorId: map['supervisorId'],
      supervisorReportUrl: map['supervisorReportUrl'],
    );
  }

  /// Convierte la instancia a Map para Firestore/JSON
  /// Incluye los nuevos campos solo si existen
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'companyId': companyId,
      'service': service,
      'date': date.toIso8601String(),
      'status': describeEnum(status),
    };
    // --- Supervisor ---
    map['supervisorRequested'] = supervisorRequested;
    if (supervisorType != null) map['supervisorType'] = supervisorType;
    map['supervisorCost'] = supervisorCost;
    if (supervisorStatus != null) map['supervisorStatus'] = supervisorStatus;
    if (supervisorId != null) map['supervisorId'] = supervisorId;
    if (supervisorReportUrl != null) map['supervisorReportUrl'] = supervisorReportUrl;
    return map;
  }
}

