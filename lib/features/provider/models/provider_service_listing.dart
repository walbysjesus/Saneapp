import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderServiceListing {
  final String id;
  final String providerId;
  final String providerName;
  final String providerLocation;
  final String providerLogoUrl;
  final String commercialImageUrl;
  final String commercialVideoUrl;
  final String serviceLineId;
  final String serviceLineLabel;
  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final String title;
  final String shortDescription;
  final String technicalDescription;
  final String coverage;
  final String serviceMode;
  final String priceType;
  final double priceFrom;
  final String responseTime;
  final String industries;
  final String requirements;
  final String deliverables;
  final Map<String, dynamic> dynamicAttributes;
  final bool emergencyAvailability;
  final bool requiresLicense;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProviderServiceListing({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.providerLocation,
    required this.providerLogoUrl,
    required this.commercialImageUrl,
    required this.commercialVideoUrl,
    required this.serviceLineId,
    required this.serviceLineLabel,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.title,
    required this.shortDescription,
    required this.technicalDescription,
    required this.coverage,
    required this.serviceMode,
    required this.priceType,
    required this.priceFrom,
    required this.responseTime,
    required this.industries,
    required this.requirements,
    required this.deliverables,
    this.dynamicAttributes = const <String, dynamic>{},
    required this.emergencyAvailability,
    required this.requiresLicense,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderServiceListing.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final dynamicAttributes =
        (data['dynamicAttributes'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    return ProviderServiceListing(
      id: doc.id,
      providerId: data['providerId'] as String? ?? '',
      providerName: data['providerName'] as String? ?? '',
      providerLocation: data['providerLocation'] as String? ?? '',
      providerLogoUrl: data['providerLogoUrl'] as String? ?? '',
      commercialImageUrl: data['commercialImageUrl'] as String? ?? '',
      commercialVideoUrl:
          data['commercialVideoUrl'] as String? ??
          dynamicAttributes['commercialVideoUrl'] as String? ??
          dynamicAttributes['videoUrl'] as String? ??
          '',
      serviceLineId: data['serviceLineId'] as String? ?? 'environmental_services',
      serviceLineLabel:
          data['serviceLineLabel'] as String? ?? 'Servicios ambientales',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      subcategoryId: data['subcategoryId'] as String? ?? '',
      subcategoryName: data['subcategoryName'] as String? ?? '',
      title: data['title'] as String? ?? '',
      shortDescription: data['shortDescription'] as String? ?? '',
      technicalDescription: data['technicalDescription'] as String? ?? '',
      coverage: data['coverage'] as String? ?? '',
      serviceMode: data['serviceMode'] as String? ?? '',
      priceType: data['priceType'] as String? ?? '',
      priceFrom: (data['priceFrom'] as num?)?.toDouble() ?? 0,
      responseTime: data['responseTime'] as String? ?? '',
      industries: data['industries'] as String? ?? '',
      requirements: data['requirements'] as String? ?? '',
      deliverables: data['deliverables'] as String? ?? '',
      dynamicAttributes:
          (data['dynamicAttributes'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
      emergencyAvailability: data['emergencyAvailability'] == true,
      requiresLicense: data['requiresLicense'] == true,
      isActive: data['isActive'] != false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'providerName': providerName,
      'providerLocation': providerLocation,
      'providerLogoUrl': providerLogoUrl,
      'commercialImageUrl': commercialImageUrl,
      'commercialVideoUrl': commercialVideoUrl,
      'serviceLineId': serviceLineId,
      'serviceLineLabel': serviceLineLabel,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'title': title,
      'shortDescription': shortDescription,
      'technicalDescription': technicalDescription,
      'coverage': coverage,
      'serviceMode': serviceMode,
      'priceType': priceType,
      'priceFrom': priceFrom,
      'responseTime': responseTime,
      'industries': industries,
      'requirements': requirements,
      'deliverables': deliverables,
      'dynamicAttributes': dynamicAttributes,
      'emergencyAvailability': emergencyAvailability,
      'requiresLicense': requiresLicense,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}