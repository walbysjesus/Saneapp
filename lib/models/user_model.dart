/// Modelo de usuario corporativo para SaneApp
/// Incluye soporte para roles y empresa
library;
import 'company_verification.dart';

class UserModel {
  bool get verified => verificationStatus == CompanyVerificationStatus.verified;
  // Getter para logo de empresa o foto de usuario
  String? get logoUrl => photoUrl;

  // Estado de aprobaciÃ³n (mock, puedes adaptar a tu lÃ³gica real)
  String? get approvalStatus {
    if (verificationStatus == CompanyVerificationStatus.verified) {
      return 'Aprobado';
    }
    if (verificationStatus == CompanyVerificationStatus.rejected) {
      return 'Rechazado';
    }
    return 'Pendiente';
  }

  final String uid;
  final String email;
  final String? fullName;
  final String? photoUrl;
  final String? companyName;

  /// Rol del usuario: 'generador', 'proveedor', 'supervisor', 'admin'.
  final String? role; // 'generador', 'proveedor', 'supervisor', 'admin'
  final String? city;
  final String? entityType;
  final String? clientType;
  final String? status;
  final bool clientProfileCompleted;
  final bool supervisorProfileCompleted;
  final bool supervisorAssessmentPassed;
  final int? supervisorAssessmentScore;
  final CompanyVerificationStatus? verificationStatus;
  final DateTime? verifiedAt;
  final List<String> completedServiceIds;
  final bool? ofreceEmergencias24h;

  UserModel({
    required this.uid,
    required this.email,
    this.fullName,
    this.photoUrl,
    this.companyName,
    this.role,
    this.city,
    this.entityType,
    this.clientType,
    this.status,
    this.clientProfileCompleted = false,
    this.supervisorProfileCompleted = false,
    this.supervisorAssessmentPassed = false,
    this.supervisorAssessmentScore,
    this.verificationStatus,
    this.verifiedAt,
    this.completedServiceIds = const [],
    this.ofreceEmergencias24h,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'],
      photoUrl: map['photoUrl'],
      companyName: map['companyName'],
      role:
          map['role'], // Puede ser 'generador', 'proveedor', 'supervisor', 'admin'
      city: map['city'],
      entityType: map['entityType'],
      clientType: map['clientType'],
      status: map['status'],
      clientProfileCompleted: map['clientProfileCompleted'] as bool? ?? false,
      supervisorProfileCompleted:
          map['supervisorProfileCompleted'] as bool? ?? false,
      supervisorAssessmentPassed:
          map['supervisorAssessmentPassed'] as bool? ?? false,
      supervisorAssessmentScore: (map['supervisorAssessmentScore'] as num?)
          ?.toInt(),
      verificationStatus: map['verificationStatus'] != null
          ? CompanyVerificationStatus.values.firstWhere(
              (e) => e.name == map['verificationStatus'],
              orElse: () => CompanyVerificationStatus.pending,
            )
          : null,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'])
          : null,
      completedServiceIds: List<String>.from(map['completedServiceIds'] ?? []),
      ofreceEmergencias24h: map['ofreceEmergencias24h'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'companyName': companyName,
      'role': role, // Puede ser 'generador', 'proveedor', 'supervisor', 'admin'
      'city': city,
      'entityType': entityType,
      'clientType': clientType,
      'status': status,
      'clientProfileCompleted': clientProfileCompleted,
      'supervisorProfileCompleted': supervisorProfileCompleted,
      'supervisorAssessmentPassed': supervisorAssessmentPassed,
      'supervisorAssessmentScore': supervisorAssessmentScore,
      'verificationStatus': verificationStatus?.name,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'completedServiceIds': completedServiceIds,
      'ofreceEmergencias24h': ofreceEmergencias24h,
    };
  }
}
