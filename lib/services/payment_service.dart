import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/billing/billing_service.dart';
import '../core/config/commission.dart';
import 'commercial_timeline_service.dart';
import 'payment_gateway_client.dart';
import 'provider_commercial_reputation_service.dart';

enum PaymentMethod { mercadoPago, payu, stripe, paypal, sinpe }

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final PaymentGatewayClient _gatewayClient = PaymentGatewayClient();

  static Future<void> pay(
    PaymentMethod method,
    double amount, {
    String? description,
  }) async {
    switch (method) {
      case PaymentMethod.mercadoPago:
        // IntegraciÃ³n Mercado Pago
        // TODO: Implementar integraciÃ³n real con MercadoPago SDK aquÃ­.
        // Ejemplo de lÃ³gica:
        // final mp = MP('TU_ACCESS_TOKEN');
        // final paymentData = {...};
        // final result = await mp.createPayment(paymentData);
        // Manejar el resultado y mostrar feedback al usuario
        break;
      case PaymentMethod.payu:
        // IntegraciÃ³n PayU
        // TODO: Implementar integraciÃ³n real con PayU SDK aquÃ­.
        // Ejemplo de lÃ³gica:
        // final payuParams = PayUCheckoutProParams(...);
        // PayUCheckoutProFlutter.launchPayUCheckoutPro(payuParams, (result) { ... });
        break;
      case PaymentMethod.stripe:
        // IntegraciÃ³n Stripe
        // TODO: Implementar integraciÃ³n real con Stripe aquÃ­.
        break;
      case PaymentMethod.paypal:
        // IntegraciÃ³n PayPal
        // TODO: Implementar integraciÃ³n real con PayPal aquÃ­.
        break;
      case PaymentMethod.sinpe:
        // LÃ³gica para SINPE mÃ³vil (manual)
        // TODO: Implementar lÃ³gica para SINPE mÃ³vil aquÃ­.
        break;
    }
  }

  /// Calcula y retorna la comisiÃ³n y el payout para un pago dado
  static Map<String, int> calculateCommissionAndPayout(int totalAmount) {
    final commission = calculateSaneAppCommission(totalAmount);
    final payout = calculateProviderPayout(totalAmount);
    return {'commission': commission, 'payout': payout};
  }

  static String labelForMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mercadoPago:
        return 'Mercado Pago';
      case PaymentMethod.payu:
        return 'PayU';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.sinpe:
        return 'SINPE';
    }
  }

  static String buildReceiptNumber() {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'SAN-$stamp';
  }

  static Future<String> startEscrowPayment({
    required String solicitudId,
    required String generadorId,
    required String proveedorId,
    required double amount,
    required PaymentMethod method,
    String? selectedOfferId,
    String? requestTitle,
    String? providerName,
    String? description,
  }) async {
    final paymentRef = _firestore.collection('payments').doc(solicitudId);
    final requestRef = _firestore.collection('solicitudes').doc(solicitudId);
    final amountInt = amount.round();
    final commissionData = calculateCommissionAndPayout(amountInt);
    final receiptNumber = buildReceiptNumber();

    await _firestore.runTransaction((transaction) async {
      final existingPayment = await transaction.get(paymentRef);
      if (existingPayment.exists) {
        final existingData = existingPayment.data() as Map<String, dynamic>;
        final currentStatus =
            existingData['paymentStatus']?.toString().toLowerCase() ?? '';
        if (currentStatus == 'en_custodia' || currentStatus == 'liberado') {
          throw Exception('Esta solicitud ya tiene un pago premium activo.');
        }
      }

      transaction.set(paymentRef, {
        'solicitudId': solicitudId,
        'generadorId': generadorId,
        'proveedorId': proveedorId,
        'selectedOfferId': selectedOfferId,
        'requestTitle': requestTitle ?? 'Solicitud premium SaneApp',
        'providerName': providerName ?? 'Proveedor asignado',
        'descripcion': description ?? 'Pago premium en custodia SaneApp',
        'monto': amountInt,
        'currency': 'COP',
        'paymentMethod': method.name,
        'paymentMethodLabel': labelForMethod(method),
        'paymentStatus': 'pendiente_confirmacion_gateway',
        'gatewayStatus': 'session_created',
        'receiptNumber': receiptNumber,
        'invoiceNumber': 'FAC-$receiptNumber',
        'comision': commissionData['commission'],
        'payout': commissionData['payout'],
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'pendiente_confirmacion_gateway',
            'at': DateTime.now().toUtc().toIso8601String(),
            'source': 'client_start_escrow',
          },
        ]),
        'fecha': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'releasedAt': null,
        'disputeStatus': null,
        'disputeReason': null,
        'disputeDetails': null,
        'disputeEvidenceNote': null,
      }, SetOptions(merge: true));

      transaction.set(requestRef, {
        'selectedProveedorId': proveedorId,
        'selectedOfferId': selectedOfferId,
        'status': 'pago_iniciado',
        'paymentStatus': 'pendiente_confirmacion_gateway',
        'paymentId': solicitudId,
        'selectedAt': FieldValue.serverTimestamp(),
        'commercialFlowStage': 'payment_gateway_pending',
        'commercialFlowUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    final session = await _gatewayClient.createSession(
      paymentId: solicitudId,
      requestId: solicitudId,
      method: method,
      amount: amountInt,
      currency: 'COP',
      description:
          description ??
          'Pago premium para $solicitudId con proveedor $proveedorId',
    );

    await Future.wait([
      paymentRef.set({
        'gatewaySessionId': session.sessionId,
        'gatewayReference': session.gatewayReference,
        'gatewayCheckoutUrl': session.checkoutUrl,
        'gatewayRaw': session.raw,
        'gatewayStatus': 'checkout_ready',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      requestRef.set({
        'gatewaySessionId': session.sessionId,
        'paymentCheckoutUrl': session.checkoutUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    ]);

    await ProviderCommercialReputationService.registerCommercialWin(
      providerId: proveedorId,
    );
    await BillingService.upsertPaymentRecords(
      requestId: solicitudId,
      paymentId: solicitudId,
      clientId: generadorId,
      providerId: proveedorId,
      providerName: providerName ?? 'Proveedor asignado',
      amount: amountInt,
      invoiceNumber: 'FAC-$receiptNumber',
      receiptNumber: receiptNumber,
      currency: 'COP',
      paymentStatus: 'en_custodia',
    );
    await CommercialTimelineService.recordPaymentStarted(
      requestId: solicitudId,
      paymentId: solicitudId,
      providerId: proveedorId,
      providerName: providerName ?? 'Proveedor asignado',
      amount: amountInt,
      invoiceNumber: 'FAC-$receiptNumber',
      receiptNumber: receiptNumber,
    );

    return session.checkoutUrl;
  }

  static Future<void> releaseEscrowPayment({
    required String paymentId,
    required String releasedBy,
  }) async {
    final paymentRef = _firestore.collection('payments').doc(paymentId);
    final requestRef = _firestore.collection('solicitudes').doc(paymentId);
    String providerId = '';
    String providerName = 'Proveedor asignado';
    String generatorId = '';
    String invoiceNumber = '';
    String receiptNumber = '';
    int amount = 0;
    String currency = 'COP';

    await _firestore.runTransaction((transaction) async {
      final paymentSnap = await transaction.get(paymentRef);
      if (!paymentSnap.exists) {
        throw Exception('No existe el pago que se intenta liberar.');
      }
      providerId = paymentSnap.data()?['proveedorId']?.toString() ?? '';
      providerName =
          paymentSnap.data()?['providerName']?.toString() ??
          'Proveedor asignado';
      generatorId = paymentSnap.data()?['generadorId']?.toString() ?? '';
      invoiceNumber = paymentSnap.data()?['invoiceNumber']?.toString() ?? '';
      receiptNumber = paymentSnap.data()?['receiptNumber']?.toString() ?? '';
      amount = (paymentSnap.data()?['monto'] as num?)?.toInt() ?? 0;
      currency = paymentSnap.data()?['currency']?.toString() ?? 'COP';

      transaction.set(paymentRef, {
        'paymentStatus': 'liberado',
        'releasedAt': FieldValue.serverTimestamp(),
        'releasedBy': releasedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(requestRef, {
        'paymentStatus': 'liberado',
        'commercialFlowStage': 'payment_released',
        'commercialFlowUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await ProviderCommercialReputationService.registerCompletedService(
      providerId: providerId,
    );
    await BillingService.upsertPaymentRecords(
      requestId: paymentId,
      paymentId: paymentId,
      clientId: generatorId,
      providerId: providerId,
      providerName: providerName,
      amount: amount,
      invoiceNumber: invoiceNumber,
      receiptNumber: receiptNumber,
      currency: currency,
      paymentStatus: 'liberado',
    );
    await CommercialTimelineService.recordPaymentReleased(
      requestId: paymentId,
      paymentId: paymentId,
      releasedBy: releasedBy,
    );
  }

  static Future<void> openDispute({
    required String paymentId,
    required String openedBy,
    required String reason,
    required String details,
    String? evidenceNote,
  }) async {
    final paymentRef = _firestore.collection('payments').doc(paymentId);
    final requestRef = _firestore.collection('solicitudes').doc(paymentId);
    String providerId = '';
    String providerName = 'Proveedor asignado';
    String generatorId = '';
    String invoiceNumber = '';
    String receiptNumber = '';
    int amount = 0;
    String currency = 'COP';

    await _firestore.runTransaction((transaction) async {
      final paymentSnap = await transaction.get(paymentRef);
      if (!paymentSnap.exists) {
        throw Exception('No existe el pago que se quiere disputar.');
      }
      providerId = paymentSnap.data()?['proveedorId']?.toString() ?? '';
      providerName =
          paymentSnap.data()?['providerName']?.toString() ??
          'Proveedor asignado';
      generatorId = paymentSnap.data()?['generadorId']?.toString() ?? '';
      invoiceNumber = paymentSnap.data()?['invoiceNumber']?.toString() ?? '';
      receiptNumber = paymentSnap.data()?['receiptNumber']?.toString() ?? '';
      amount = (paymentSnap.data()?['monto'] as num?)?.toInt() ?? 0;
      currency = paymentSnap.data()?['currency']?.toString() ?? 'COP';

      transaction.set(paymentRef, {
        'paymentStatus': 'en_disputa',
        'disputeStatus': 'abierta',
        'disputeOpenedBy': openedBy,
        'disputeOpenedAt': FieldValue.serverTimestamp(),
        'disputeReason': reason,
        'disputeDetails': details,
        'disputeEvidenceNote': evidenceNote,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(requestRef, {
        'paymentStatus': 'en_disputa',
        'commercialFlowStage': 'payment_under_dispute',
        'commercialFlowUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await ProviderCommercialReputationService.registerDispute(
      providerId: providerId,
    );
    await BillingService.upsertPaymentRecords(
      requestId: paymentId,
      paymentId: paymentId,
      clientId: generatorId,
      providerId: providerId,
      providerName: providerName,
      amount: amount,
      invoiceNumber: invoiceNumber,
      receiptNumber: receiptNumber,
      currency: currency,
      paymentStatus: 'en_disputa',
    );
    await CommercialTimelineService.recordDisputeOpened(
      requestId: paymentId,
      paymentId: paymentId,
      openedBy: openedBy,
      reason: reason,
    );
  }
}
