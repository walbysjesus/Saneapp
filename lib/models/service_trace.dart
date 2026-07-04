/// Modelo de trazabilidad legal para servicios en SaneApp
class ServiceTrace {
  final String serviceId;
  final DateTime createdAt;
  final double? lat;
  final double? lng;
  final List<String> beforeEvidenceUrls;
  final List<String> afterEvidenceUrls;

  ServiceTrace({
    required this.serviceId,
    required this.createdAt,
    this.lat,
    this.lng,
    this.beforeEvidenceUrls = const [],
    this.afterEvidenceUrls = const [],
  });

  factory ServiceTrace.fromMap(Map<String, dynamic> map) {
    return ServiceTrace(
      serviceId: map['serviceId'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      beforeEvidenceUrls: List<String>.from(map['beforeEvidenceUrls'] ?? []),
      afterEvidenceUrls: List<String>.from(map['afterEvidenceUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'createdAt': createdAt.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'beforeEvidenceUrls': beforeEvidenceUrls,
      'afterEvidenceUrls': afterEvidenceUrls,
    };
  }
}

