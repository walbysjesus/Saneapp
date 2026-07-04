import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Servicio para SaneApp
class Service {
    /// Devuelve la primera imagen del servicio o null si no hay imÃ¡genes
    String? get imageUrl => images.isNotEmpty ? images.first : null;

    /// Getter para saber si el servicio estÃ¡ certificado (asume campo en Firestore, fallback a false)
    bool? get isCertified {
      // Este getter es Ãºtil para la UI, pero requiere que el campo estÃ© en el doc original.
      // Si necesitas que sea persistente, agrega el campo en Firestore y en fromFirestore.
      // AquÃ­ solo retorna null para evitar errores si no estÃ¡ implementado.
      return null;
    }
  final String id;
  final String title;
  final String description;
  final String category;
  final String providerId; // Empresa o profesional que ofrece el servicio
  final double price;
  final List<String> images;
  final DateTime createdAt;
  final bool isActive;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.providerId,
    required this.price,
    required this.images,
    required this.createdAt,
    required this.isActive,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      providerId: data['providerId'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'providerId': providerId,
      'price': price,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}

/// Modelo de Solicitud de Servicio para SaneApp
class ServiceRequest {
  final String id;
  final String serviceId;
  final String clientId;
  final String providerId;
  final String status; // pending, accepted, rejected, completed, cancelled
  final String details;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final List<String> attachments;

  ServiceRequest({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.providerId,
    required this.status,
    required this.details,
    required this.requestedAt,
    this.completedAt,
    required this.attachments,
  });

  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequest(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      clientId: data['clientId'] ?? '',
      providerId: data['providerId'] ?? '',
      status: data['status'] ?? 'pending',
      details: data['details'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'clientId': clientId,
      'providerId': providerId,
      'status': status,
      'details': details,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'attachments': attachments,
    };
  }
}

