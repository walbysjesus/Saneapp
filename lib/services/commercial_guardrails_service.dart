import 'package:cloud_firestore/cloud_firestore.dart';

import 'commercial_timeline_service.dart';

class CommercialGuardrailResult {
  const CommercialGuardrailResult({
    required this.blocked,
    required this.reasons,
  });

  final bool blocked;
  final List<String> reasons;
}

class CommercialGuardrailsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final RegExp _emailPattern = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );
  static final RegExp _phonePattern = RegExp(
    r'(\+?\d[\d\s\-()]{7,}\d)',
    caseSensitive: false,
  );
  static final RegExp _whatsappPattern = RegExp(
    r'(whatsapp|wa\.me|telegram|t\.me|ll[aá]mame|escr[ií]beme)',
    caseSensitive: false,
  );
  static final RegExp _externalPattern = RegExp(
    r'(gmail|hotmail|outlook|yahoo|instagram|facebook|linkedin|http|www\.)',
    caseSensitive: false,
  );

  static CommercialGuardrailResult inspectMessage(String text) {
    final normalized = text.trim();
    final reasons = <String>[];
    if (_emailPattern.hasMatch(normalized)) {
      reasons.add('correo');
    }
    if (_phonePattern.hasMatch(normalized)) {
      reasons.add('teléfono');
    }
    if (_whatsappPattern.hasMatch(normalized)) {
      reasons.add('canal externo');
    }
    if (_externalPattern.hasMatch(normalized)) {
      reasons.add('red o enlace externo');
    }
    return CommercialGuardrailResult(
      blocked: reasons.isNotEmpty,
      reasons: reasons.toSet().toList(),
    );
  }

  static String protectedLabelForRole(String role, String fallback) {
    if (role == 'generador') {
      return 'Generador protegido por SaneApp';
    }
    return fallback;
  }

  static String get policyMessage =>
      'SaneApp mantiene el contacto del generador protegido. Facturación, trazabilidad, custodia y cierre se gestionan dentro de la plataforma.';

  static Future<void> registerBlockedAttempt({
    required String requestId,
    required String requestTitle,
    required String senderId,
    required String senderRole,
    required List<String> reasons,
    required String rawText,
  }) async {
    final chatRef = _firestore.collection('commercial_chats').doc(requestId);
    final policyRef = chatRef.collection('policy_events').doc();
    await _firestore.runTransaction((transaction) async {
      transaction.set(chatRef, {
        'contactExchangeBlockedCount': FieldValue.increment(1),
        'lastPolicyEventAt': FieldValue.serverTimestamp(),
        'lastPolicyEventType': 'contact_exchange_blocked',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(policyRef, {
        'type': 'contact_exchange_blocked',
        'requestId': requestId,
        'requestTitle': requestTitle,
        'senderId': senderId,
        'senderRole': senderRole,
        'reasons': reasons,
        'preview': rawText.length > 120
            ? '${rawText.substring(0, 120)}...'
            : rawText,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    await CommercialTimelineService.recordPolicyViolation(
      requestId: requestId,
      senderId: senderId,
      senderRole: senderRole,
      reasons: reasons,
    );
  }
}
