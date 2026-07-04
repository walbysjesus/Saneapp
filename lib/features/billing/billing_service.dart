import 'package:cloud_firestore/cloud_firestore.dart';

import 'billing_model.dart';
import '../../services/commercial_timeline_service.dart';

class BillingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<BillingRecord>> fetchRecords(String clientId) async {
    final snapshot = await _firestore
        .collection('billing_records')
        .where('clientId', isEqualTo: clientId)
        .get();
    final records =
        snapshot.docs
            .map((doc) => BillingRecord.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<void> createRecord(BillingRecord record) async {
    await _firestore
        .collection('billing_records')
        .doc(record.id)
        .set(record.toMap(), SetOptions(merge: true));
  }

  static Future<void> upsertPaymentRecords({
    required String requestId,
    required String paymentId,
    required String clientId,
    required String providerId,
    required String providerName,
    required int amount,
    required String invoiceNumber,
    required String receiptNumber,
    required String currency,
    required String paymentStatus,
  }) async {
    final service = BillingService();
    final now = DateTime.now();
    final requestSnapshot = await _firestore
        .collection('solicitudes')
        .doc(requestId)
        .get();
    final requestData = requestSnapshot.data() ?? const <String, dynamic>{};
    final category =
        requestData['serviceCategory']?.toString() ??
        requestData['serviceInterest']?.toString() ??
        'Sin categoría';
    final subcategory = requestData['serviceSubcategory']?.toString() ?? '';
    final clientRecord = BillingRecord(
      id: 'generator-$paymentId',
      requestId: requestId,
      paymentId: paymentId,
      clientId: clientId,
      providerId: providerId,
      providerName: providerName,
      category: category,
      subcategory: subcategory,
      documentType: 'saneapp_invoice',
      audience: 'generador',
      invoiceNumber: invoiceNumber,
      receiptNumber: receiptNumber,
      currency: currency,
      amount: amount.toDouble(),
      date: now,
      status: paymentStatus,
      description:
          'Documento visible al generador emitido por SaneApp dentro del expediente comercial.',
      visibleToClient: true,
    );
    final providerRecord = BillingRecord(
      id: 'provider-support-$paymentId',
      requestId: requestId,
      paymentId: paymentId,
      clientId: clientId,
      providerId: providerId,
      providerName: providerName,
      category: category,
      subcategory: subcategory,
      documentType: 'provider_support_document',
      audience: 'saneapp',
      invoiceNumber: 'SOP-$invoiceNumber',
      receiptNumber: receiptNumber,
      currency: currency,
      amount: amount.toDouble(),
      date: now,
      status: paymentStatus,
      description:
          'Soporte tributario y comercial del proveedor hacia SaneApp para el mismo negocio.',
      visibleToClient: false,
    );
    await Future.wait([
      service.createRecord(clientRecord),
      service.createRecord(providerRecord),
    ]);
    await CommercialTimelineService.recordEvent(
      requestId: requestId,
      eventType: 'billing_documents_updated',
      title: 'Facturación vinculada al negocio',
      description:
          'SaneApp actualizó los documentos de facturación ligados al pago y a la solicitud.',
      actorRole: 'saneapp',
      metadata: {
        'paymentId': paymentId,
        'invoiceNumber': invoiceNumber,
        'paymentStatus': paymentStatus,
        'category': category,
        'subcategory': subcategory,
      },
    );
  }
}
