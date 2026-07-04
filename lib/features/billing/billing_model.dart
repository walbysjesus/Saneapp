import 'package:cloud_firestore/cloud_firestore.dart';

class BillingRecord {
  final String id;
  final String requestId;
  final String paymentId;
  final String clientId;
  final String providerId;
  final String providerName;
  final String category;
  final String subcategory;
  final String documentType;
  final String audience;
  final String invoiceNumber;
  final String receiptNumber;
  final String currency;
  final double amount;
  final DateTime date;
  final String status;
  final String description;
  final bool visibleToClient;

  BillingRecord({
    required this.id,
    required this.requestId,
    required this.paymentId,
    required this.clientId,
    required this.providerId,
    required this.providerName,
    required this.category,
    required this.subcategory,
    required this.documentType,
    required this.audience,
    required this.invoiceNumber,
    required this.receiptNumber,
    required this.currency,
    required this.amount,
    required this.date,
    required this.status,
    required this.description,
    required this.visibleToClient,
  });

  factory BillingRecord.fromMap(String id, Map<String, dynamic> map) {
    return BillingRecord(
      id: id,
      requestId: map['requestId']?.toString() ?? '',
      paymentId: map['paymentId']?.toString() ?? '',
      clientId: map['clientId']?.toString() ?? '',
      providerId: map['providerId']?.toString() ?? '',
      providerName: map['providerName']?.toString() ?? 'Proveedor',
      category: map['category']?.toString() ?? 'Sin categoría',
      subcategory: map['subcategory']?.toString() ?? '',
      documentType: map['documentType']?.toString() ?? 'saneapp_invoice',
      audience: map['audience']?.toString() ?? 'generador',
      invoiceNumber: map['invoiceNumber']?.toString() ?? '-',
      receiptNumber: map['receiptNumber']?.toString() ?? '-',
      currency: map['currency']?.toString() ?? 'COP',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
      status: map['status']?.toString() ?? 'draft',
      description: map['description']?.toString() ?? '',
      visibleToClient: map['visibleToClient'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'paymentId': paymentId,
      'clientId': clientId,
      'providerId': providerId,
      'providerName': providerName,
      'category': category,
      'subcategory': subcategory,
      'documentType': documentType,
      'audience': audience,
      'invoiceNumber': invoiceNumber,
      'receiptNumber': receiptNumber,
      'currency': currency,
      'amount': amount,
      'status': status,
      'description': description,
      'visibleToClient': visibleToClient,
      'createdAt': Timestamp.fromDate(date),
    };
  }
}
