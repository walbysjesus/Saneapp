import 'package:cloud_firestore/cloud_firestore.dart';

class CommercialTimelineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> recordEvent({
    required String requestId,
    required String eventType,
    required String title,
    required String description,
    String? actorId,
    String? actorRole,
    Map<String, dynamic>? metadata,
  }) async {
    if (requestId.isEmpty) {
      return;
    }
    final eventRef = _firestore
        .collection('solicitudes')
        .doc(requestId)
        .collection('commercial_events')
        .doc();
    await eventRef.set({
      'requestId': requestId,
      'eventType': eventType,
      'title': title,
      'description': description,
      'actorId': actorId,
      'actorRole': actorRole,
      'metadata': metadata ?? <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordRequestCreated({
    required String requestId,
    required String title,
    required String generatorId,
    required String category,
    String? subcategory,
    String? providerId,
  }) {
    return recordEvent(
      requestId: requestId,
      eventType: 'request_created',
      title: 'Solicitud creada',
      description:
          'El expediente comercial nace en SaneApp y centraliza operación, cotización, custodia, facturación y cierre.',
      actorId: generatorId,
      actorRole: 'generador',
      metadata: {
        'requestTitle': title,
        'category': category,
        'subcategory': subcategory,
        'providerId': providerId,
      },
    );
  }

  static Future<void> recordQuoteSubmitted({
    required String requestId,
    required String providerId,
    required String providerName,
    required String quoteNumber,
    required double totalAmount,
  }) {
    return recordEvent(
      requestId: requestId,
      eventType: 'quote_submitted',
      title: 'Cotización emitida',
      description:
          '$providerName emitió una cotización formal dentro del expediente comercial.',
      actorId: providerId,
      actorRole: 'proveedor',
      metadata: {
        'providerName': providerName,
        'quoteNumber': quoteNumber,
        'totalAmount': totalAmount,
      },
    );
  }

  static Future<void> recordPaymentStarted({
    required String requestId,
    required String paymentId,
    required String providerId,
    required String providerName,
    required int amount,
    required String invoiceNumber,
    required String receiptNumber,
  }) {
    return recordEvent(
      requestId: requestId,
      eventType: 'payment_started',
      title: 'Pago en custodia',
      description:
          'SaneApp recibió el pago y lo dejó en custodia con comprobante e invoice ligados al mismo negocio.',
      actorId: providerId,
      actorRole: 'saneapp',
      metadata: {
        'paymentId': paymentId,
        'providerName': providerName,
        'amount': amount,
        'invoiceNumber': invoiceNumber,
        'receiptNumber': receiptNumber,
      },
    );
  }

  static Future<void> recordPaymentReleased({
    required String requestId,
    required String paymentId,
    required String releasedBy,
  }) {
    return recordEvent(
      requestId: requestId,
      eventType: 'payment_released',
      title: 'Pago liberado',
      description:
          'El pago fue validado y liberado dentro del expediente comercial de SaneApp.',
      actorId: releasedBy,
      actorRole: 'generador',
      metadata: {'paymentId': paymentId},
    );
  }

  static Future<void> recordDisputeOpened({
    required String requestId,
    required String paymentId,
    required String openedBy,
    required String reason,
  }) {
    return recordEvent(
      requestId: requestId,
      eventType: 'payment_dispute_opened',
      title: 'Disputa abierta',
      description:
          'SaneApp congeló el caso dentro del expediente comercial para revisión formal.',
      actorId: openedBy,
      actorRole: 'generador',
      metadata: {'paymentId': paymentId, 'reason': reason},
    );
  }

  static Future<void> recordPolicyViolation({
    required String requestId,
    required String senderId,
    required String senderRole,
    required List<String> reasons,
  }) {
    return recordEvent(
      requestId: requestId,
      eventType: 'policy_violation',
      title: 'Intento de desintermediación bloqueado',
      description:
          'SaneApp bloqueó un intento de compartir contacto o canal externo fuera del flujo protegido.',
      actorId: senderId,
      actorRole: senderRole,
      metadata: {'reasons': reasons},
    );
  }
}
