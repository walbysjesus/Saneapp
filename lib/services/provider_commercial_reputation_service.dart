import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderCommercialSnapshot {
  const ProviderCommercialSnapshot({
    required this.score,
    required this.tier,
    required this.tierLabel,
    required this.avgResponseTimeMinutes,
    required this.acceptanceRate,
    required this.completedServices,
    required this.commercialWins,
    required this.disputeCount,
    required this.completedDocuments,
    required this.policyViolationCount,
  });

  final double score;
  final String tier;
  final String tierLabel;
  final double avgResponseTimeMinutes;
  final double acceptanceRate;
  final int completedServices;
  final int commercialWins;
  final int disputeCount;
  final int completedDocuments;
  final int policyViolationCount;

  String get formattedScore => score.toStringAsFixed(0);

  String get responseLabel {
    if (avgResponseTimeMinutes <= 0) {
      return 'SLA en aprendizaje';
    }
    if (avgResponseTimeMinutes < 60) {
      return '${avgResponseTimeMinutes.toStringAsFixed(0)} min';
    }
    final hours = avgResponseTimeMinutes / 60;
    return '${hours.toStringAsFixed(1)} h';
  }
}

class ProviderCommercialReputationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static double rankingIndex(
    Map<String, dynamic> providerData, {
    int activeServiceCount = 0,
  }) {
    final snapshot = fromProviderData(
      providerData,
      activeServiceCount: activeServiceCount,
    );
    final responseBoost =
        snapshot.avgResponseTimeMinutes > 0 &&
            snapshot.avgResponseTimeMinutes <= 60
        ? 6.0
        : snapshot.avgResponseTimeMinutes > 0 &&
              snapshot.avgResponseTimeMinutes <= 180
        ? 3.0
        : 0.0;
    final acceptanceBoost = (snapshot.acceptanceRate.clamp(0, 100) / 100) * 8;
    final completionBoost = snapshot.completedServices.clamp(0, 15) * 0.6;
    final disputePenalty = snapshot.disputeCount.clamp(0, 6) * 1.5;
    final violationPenalty = snapshot.policyViolationCount.clamp(0, 8) * 2.5;
    return snapshot.score +
        responseBoost +
        acceptanceBoost +
        completionBoost -
        disputePenalty -
        violationPenalty;
  }

  static String rankingBadge({
    required ProviderCommercialSnapshot snapshot,
    required int index,
  }) {
    if (index == 0 && snapshot.tier == 'A') {
      return 'Top match premium';
    }
    if (index < 3 && (snapshot.tier == 'A' || snapshot.tier == 'B')) {
      return 'Alta confianza';
    }
    if (snapshot.avgResponseTimeMinutes > 0 &&
        snapshot.avgResponseTimeMinutes <= 60) {
      return 'Respuesta ágil';
    }
    if (snapshot.acceptanceRate >= 70) {
      return 'Cierre consistente';
    }
    return 'Match comercial';
  }

  static ProviderCommercialSnapshot fromProviderData(
    Map<String, dynamic> providerData, {
    int activeServiceCount = 0,
  }) {
    final completedDocuments = _countCompletedDocuments(providerData);
    final ratingAverage =
        (providerData['ratingAverage'] as num?)?.toDouble() ?? 0;
    final ratingCount = (providerData['ratingCount'] as num?)?.toInt() ?? 0;
    final avgResponseTimeMinutes =
        (providerData['avgResponseTimeMinutes'] as num?)?.toDouble() ?? 0;
    final responseCount =
        (providerData['commercialResponseCount'] as num?)?.toInt() ?? 0;
    final commercialWins =
        (providerData['commercialWinsCount'] as num?)?.toInt() ?? 0;
    final completedServices =
        (providerData['completedServices'] as num?)?.toInt() ?? 0;
    final disputeCount = (providerData['disputeCount'] as num?)?.toInt() ?? 0;
    final policyViolationCount =
        (providerData['policyViolationCount'] as num?)?.toInt() ?? 0;
    final acceptanceRate = responseCount > 0
        ? (commercialWins / responseCount) * 100
        : ((providerData['acceptanceRate'] as num?)?.toDouble() ?? 0);

    final ratingScore = ratingCount > 0 ? (ratingAverage / 5) * 32 : 12.0;
    final documentScore = (completedDocuments / 4) * 14;
    final profileScore = providerData['profileCompleted'] == true ? 10.0 : 4.0;
    final responseScore = _responseScore(avgResponseTimeMinutes);
    final completionScore = (completedServices.clamp(0, 20) / 20) * 18;
    final winsScore = (commercialWins.clamp(0, 12) / 12) * 14;
    final portfolioScore = (activeServiceCount.clamp(0, 10) / 10) * 8;
    final disputePenalty = disputeCount.clamp(0, 6) * 3.0;

    final compliancePenalty = policyViolationCount.clamp(0, 8) * 4.0;
    final rawScore =
        ratingScore +
        documentScore +
        profileScore +
        responseScore +
        completionScore +
        winsScore +
        portfolioScore -
        disputePenalty -
        compliancePenalty;
    final score = rawScore.clamp(0, 100).toDouble();
    final tier = _tierFromScore(score);

    return ProviderCommercialSnapshot(
      score: score,
      tier: tier,
      tierLabel: _tierLabel(tier),
      avgResponseTimeMinutes: avgResponseTimeMinutes,
      acceptanceRate: acceptanceRate,
      completedServices: completedServices,
      commercialWins: commercialWins,
      disputeCount: disputeCount,
      completedDocuments: completedDocuments,
      policyViolationCount: policyViolationCount,
    );
  }

  static Future<void> registerPolicyViolation({
    required String providerId,
    String reason = 'contact_exchange_attempt',
  }) async {
    if (providerId.isEmpty) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final providerRef = _firestore.collection('providers').doc(providerId);
      final providerSnap = await transaction.get(providerRef);
      final providerData = providerSnap.data() ?? <String, dynamic>{};
      final policyViolationCount =
          (providerData['policyViolationCount'] as num?)?.toInt() ?? 0;
      final updated = <String, dynamic>{
        'policyViolationCount': policyViolationCount + 1,
        'lastPolicyViolationAt': FieldValue.serverTimestamp(),
        'lastPolicyViolationReason': reason,
      };
      updated.addAll(_buildReputationFields({...providerData, ...updated}));
      transaction.set(providerRef, updated, SetOptions(merge: true));
    });
  }

  static Future<void> registerCommercialResponse({
    required String providerId,
    required DateTime? requestCreatedAt,
    bool recordWin = false,
  }) async {
    if (providerId.isEmpty) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final providerRef = _firestore.collection('providers').doc(providerId);
      final providerSnap = await transaction.get(providerRef);
      final providerData = providerSnap.data() ?? <String, dynamic>{};
      final responseCount =
          (providerData['commercialResponseCount'] as num?)?.toInt() ?? 0;
      final previousAverage =
          (providerData['avgResponseTimeMinutes'] as num?)?.toDouble() ?? 0;
      final responseMinutes = requestCreatedAt == null
          ? 0.0
          : DateTime.now()
                .difference(requestCreatedAt)
                .inMinutes
                .clamp(0, 100000)
                .toDouble();
      final nextResponseCount = responseCount + 1;
      final nextAverage = responseMinutes > 0
          ? ((previousAverage * responseCount) + responseMinutes) /
                nextResponseCount
          : previousAverage;
      final nextWins =
          (providerData['commercialWinsCount'] as num?)?.toInt() ?? 0;

      final updated = <String, dynamic>{
        'commercialResponseCount': nextResponseCount,
        'avgResponseTimeMinutes': responseMinutes > 0
            ? nextAverage
            : previousAverage,
        'lastCommercialResponseAt': FieldValue.serverTimestamp(),
      };
      if (recordWin) {
        updated['commercialWinsCount'] = nextWins + 1;
      }
      updated.addAll(_buildReputationFields({...providerData, ...updated}));
      transaction.set(providerRef, updated, SetOptions(merge: true));
    });
  }

  static Future<void> registerCommercialWin({
    required String providerId,
  }) async {
    if (providerId.isEmpty) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final providerRef = _firestore.collection('providers').doc(providerId);
      final providerSnap = await transaction.get(providerRef);
      final providerData = providerSnap.data() ?? <String, dynamic>{};
      final wins = (providerData['commercialWinsCount'] as num?)?.toInt() ?? 0;
      final updated = <String, dynamic>{
        'commercialWinsCount': wins + 1,
        'lastCommercialWinAt': FieldValue.serverTimestamp(),
      };
      updated.addAll(_buildReputationFields({...providerData, ...updated}));
      transaction.set(providerRef, updated, SetOptions(merge: true));
    });
  }

  static Future<void> registerCompletedService({
    required String providerId,
  }) async {
    if (providerId.isEmpty) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final providerRef = _firestore.collection('providers').doc(providerId);
      final providerSnap = await transaction.get(providerRef);
      final providerData = providerSnap.data() ?? <String, dynamic>{};
      final completed =
          (providerData['completedServices'] as num?)?.toInt() ?? 0;
      final updated = <String, dynamic>{
        'completedServices': completed + 1,
        'lastCompletedServiceAt': FieldValue.serverTimestamp(),
      };
      updated.addAll(_buildReputationFields({...providerData, ...updated}));
      transaction.set(providerRef, updated, SetOptions(merge: true));
    });
  }

  static Future<void> registerDispute({required String providerId}) async {
    if (providerId.isEmpty) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final providerRef = _firestore.collection('providers').doc(providerId);
      final providerSnap = await transaction.get(providerRef);
      final providerData = providerSnap.data() ?? <String, dynamic>{};
      final disputes = (providerData['disputeCount'] as num?)?.toInt() ?? 0;
      final updated = <String, dynamic>{
        'disputeCount': disputes + 1,
        'lastDisputeAt': FieldValue.serverTimestamp(),
      };
      updated.addAll(_buildReputationFields({...providerData, ...updated}));
      transaction.set(providerRef, updated, SetOptions(merge: true));
    });
  }

  static Map<String, dynamic> _buildReputationFields(
    Map<String, dynamic> providerData,
  ) {
    final responseCount =
        (providerData['commercialResponseCount'] as num?)?.toInt() ?? 0;
    final wins = (providerData['commercialWinsCount'] as num?)?.toInt() ?? 0;
    final acceptanceRate = responseCount > 0 ? (wins / responseCount) * 100 : 0;
    final snapshot = fromProviderData(providerData);
    return {
      'acceptanceRate': acceptanceRate,
      'commercialScore': snapshot.score,
      'commercialTier': snapshot.tier,
      'commercialTierLabel': snapshot.tierLabel,
    };
  }

  static int _countCompletedDocuments(Map<String, dynamic> data) {
    const fields = [
      'rutUrl',
      'camaraComercioUrl',
      'cedulaUrl',
      'certificadoBancarioUrl',
    ];
    return fields
        .where((field) => data[field]?.toString().trim().isNotEmpty == true)
        .length;
  }

  static double _responseScore(double avgMinutes) {
    if (avgMinutes <= 0) {
      return 8;
    }
    if (avgMinutes <= 60) {
      return 18;
    }
    if (avgMinutes <= 180) {
      return 15;
    }
    if (avgMinutes <= 360) {
      return 12;
    }
    if (avgMinutes <= 720) {
      return 9;
    }
    return 5;
  }

  static String _tierFromScore(double score) {
    if (score >= 85) {
      return 'A';
    }
    if (score >= 72) {
      return 'B';
    }
    if (score >= 58) {
      return 'C';
    }
    return 'D';
  }

  static String _tierLabel(String tier) {
    switch (tier) {
      case 'A':
        return 'Premium verificado';
      case 'B':
        return 'Confiable';
      case 'C':
        return 'En desarrollo';
      default:
        return 'Por consolidar';
    }
  }
}
