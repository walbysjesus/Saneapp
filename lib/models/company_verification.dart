/// Modelo de verificaciÃ³n y confianza para empresas en SaneApp
enum CompanyVerificationStatus { verified, pending, rejected }

class CompanyTrust {
  final String companyId;
  final CompanyVerificationStatus status;
  final DateTime? verifiedAt;
  final List<String> completedServiceIds;

  CompanyTrust({
    required this.companyId,
    required this.status,
    this.verifiedAt,
    this.completedServiceIds = const [],
  });

  factory CompanyTrust.fromMap(Map<String, dynamic> map) {
    return CompanyTrust(
      companyId: map['companyId'] ?? '',
      status: CompanyVerificationStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => CompanyVerificationStatus.pending,
      ),
      verifiedAt: map['verifiedAt'] != null ? DateTime.parse(map['verifiedAt']) : null,
      completedServiceIds: List<String>.from(map['completedServiceIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'status': status.name,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'completedServiceIds': completedServiceIds,
    };
  }
}

