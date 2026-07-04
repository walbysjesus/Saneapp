/// Modelo de mÃ©tricas e inteligencia interna para empresas en SaneApp
class CompanyMetrics {
  final String companyId;
  final double avgResponseTimeMinutes;
  final double acceptanceRate;
  final int totalQuotes;
  final int acceptedQuotes;
  final int completedServices;

  CompanyMetrics({
    required this.companyId,
    required this.avgResponseTimeMinutes,
    required this.acceptanceRate,
    required this.totalQuotes,
    required this.acceptedQuotes,
    required this.completedServices,
  });

  factory CompanyMetrics.fromMap(Map<String, dynamic> map) {
    return CompanyMetrics(
      companyId: map['companyId'] ?? '',
      avgResponseTimeMinutes: (map['avgResponseTimeMinutes'] as num?)?.toDouble() ?? 0.0,
      acceptanceRate: (map['acceptanceRate'] as num?)?.toDouble() ?? 0.0,
      totalQuotes: map['totalQuotes'] ?? 0,
      acceptedQuotes: map['acceptedQuotes'] ?? 0,
      completedServices: map['completedServices'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'avgResponseTimeMinutes': avgResponseTimeMinutes,
      'acceptanceRate': acceptanceRate,
      'totalQuotes': totalQuotes,
      'acceptedQuotes': acceptedQuotes,
      'completedServices': completedServices,
    };
  }
}

