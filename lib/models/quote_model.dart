/// Modelo de CotizaciÃ³n para SaneApp
/// Asociada a una solicitud, enviada por empresa
library;


import 'company_verification.dart';

class QuoteModel {
  final String id;
  final String requestId;
  final String companyId;
  final double price;
  final String description;
  final String estimatedTime;
  final DateTime date;
  final CompanyVerificationStatus? companyVerificationStatus;

  QuoteModel({
    required this.id,
    required this.requestId,
    required this.companyId,
    required this.price,
    required this.description,
    required this.estimatedTime,
    required this.date,
    this.companyVerificationStatus,
  });

  factory QuoteModel.fromMap(Map<String, dynamic> map, String id) {
    return QuoteModel(
      id: id,
      requestId: map['requestId'] ?? '',
      companyId: map['companyId'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      estimatedTime: map['estimatedTime'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      companyVerificationStatus: map['companyVerificationStatus'] != null
          ? CompanyVerificationStatus.values.firstWhere(
              (e) => e.name == map['companyVerificationStatus'],
              orElse: () => CompanyVerificationStatus.pending,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'companyId': companyId,
      'price': price,
      'description': description,
      'estimatedTime': estimatedTime,
      'date': date.toIso8601String(),
      'companyVerificationStatus': companyVerificationStatus?.name,
    };
  }
}

