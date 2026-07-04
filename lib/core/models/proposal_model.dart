import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de CotizaciÃ³n/Propuesta para SaneApp
class Proposal {
  final String id;
  final String requestId; // ID de la solicitud de servicio
  final String providerId; // Empresa que cotiza
  final String clientId; // Usuario solicitante
  final double price;
  final String description;
  final DateTime sentAt;
  final String status; // pending, accepted, rejected

  Proposal({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.clientId,
    required this.price,
    required this.description,
    required this.sentAt,
    required this.status,
  });

  factory Proposal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Proposal(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      providerId: data['providerId'] ?? '',
      clientId: data['clientId'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'providerId': providerId,
      'clientId': clientId,
      'price': price,
      'description': description,
      'sentAt': Timestamp.fromDate(sentAt),
      'status': status,
    };
  }
}

