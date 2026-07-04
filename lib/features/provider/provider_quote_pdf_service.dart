import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProviderQuotePdfService {
  static String _normalizePricingUnit(String? rawValue) {
    final value = rawValue?.trim().toLowerCase();
    switch (value) {
      case 'por horas':
      case 'por hora':
        return 'Por horas';
      case 'por metro cubico':
      case 'por metro cúbico':
      case 'metro cubico':
      case 'metro cúbico':
        return 'Por metro cúbico';
      case 'por tonelada':
      case 'por toneladas':
      case 'tonelada':
      case 'toneladas':
        return 'Por toneladas';
      case 'por metro lineal':
      case 'metro lineal':
        return 'Por metro lineal';
      case 'por visita':
      case 'por viaje':
      case 'viaje':
        return 'Por viaje';
      case 'por flete':
      case 'flete':
        return 'Por flete';
      case 'precio desde':
      case 'cotización personalizada':
      case 'cotizacion personalizada':
      case 'precio fijo':
      case 'precio fijo por servicio':
      default:
        return 'Precio fijo por servicio';
    }
  }

  static String _pricingDescription(String pricingUnit) {
    switch (pricingUnit) {
      case 'Por horas':
        return 'Precio del servicio liquidado por horas';
      case 'Por metro cúbico':
        return 'Precio del servicio liquidado por metro cúbico';
      case 'Por toneladas':
        return 'Precio del servicio liquidado por toneladas';
      case 'Por metro lineal':
        return 'Precio del servicio liquidado por metro lineal';
      case 'Por viaje':
        return 'Precio del servicio liquidado por viaje';
      case 'Por flete':
        return 'Precio del servicio liquidado por flete';
      default:
        return 'Precio fijo por servicio';
    }
  }

  static String _formatNumericValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    var text = value.toStringAsFixed(2);
    while (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  static Future<Uint8List> buildQuotePdf({
    required Map<String, dynamic> offerData,
    Map<String, dynamic>? requestData,
  }) async {
    final pdf = pw.Document();
    final providerSnapshot =
        (offerData['providerSnapshot'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final quoteNumber = offerData['quoteNumber']?.toString() ?? 'COTIZACION';
    final providerName =
        providerSnapshot['companyName']?.toString() ?? 'Proveedor SaneApp';
    final operationEmail = providerSnapshot['operationEmail']?.toString();
    final operationPhone = providerSnapshot['operationPhone']?.toString();
    final billingEmail = providerSnapshot['billingEmail']?.toString();
    final requestTitle =
        requestData?['titulo']?.toString() ??
        offerData['requestTitle']?.toString() ??
        'Solicitud';
    final requestCity = requestData?['city']?.toString() ?? '-';
    final summary =
        offerData['summary']?.toString() ??
        offerData['message']?.toString() ??
        '-';
    final scope = offerData['scope']?.toString() ?? '-';
    final deliverables = offerData['deliverables']?.toString() ?? '-';
    final conditions = offerData['serviceConditions']?.toString() ?? '-';
    final exclusions = offerData['exclusions']?.toString() ?? '-';
    final timeline = offerData['tiempoEstimado']?.toString() ?? '-';
    final warranty = offerData['garantia']?.toString() ?? '-';
    final paymentTerms = offerData['paymentTerms']?.toString() ?? '-';
    final observations = offerData['observations']?.toString() ?? '-';
    final pricingUnit = _normalizePricingUnit(
      offerData['pricingUnit']?.toString() ??
          requestData?['preferredProviderServicePriceType']?.toString() ??
          requestData?['priceType']?.toString(),
    );
    final pricingDescription =
        offerData['pricingDescription']?.toString() ??
        _pricingDescription(pricingUnit);
    final subtotal =
        (offerData['subtotal'] as num?)?.toDouble() ??
        (offerData['price'] as num?)?.toDouble() ??
        0;
    final pricingBreakdown =
        offerData['pricingBreakdown']?.toString() ??
        '${_formatNumericValue((offerData['unitPrice'] as num?)?.toDouble() ?? subtotal)} COP';
    final serviceQuantity =
        (offerData['serviceQuantity'] as num?)?.toDouble() ?? 1;
    final quantityLabel = offerData['quantityLabel']?.toString() ?? 'servicio';
    final appliesIva = offerData['appliesIva'] == true;
    final ivaRate = (offerData['ivaRate'] as num?)?.toDouble() ?? 0;
    final taxAmount = (offerData['taxAmount'] as num?)?.toDouble() ?? 0;
    final totalAmount =
        (offerData['totalAmount'] as num?)?.toDouble() ??
        (offerData['price'] as num?)?.toDouble() ??
        0;
    final validityDays = offerData['validityDays']?.toString() ?? '-';
    final createdAt = offerData['createdAt'];
    final createdAtText = createdAt is DateTime
        ? DateFormat('dd/MM/yyyy').format(createdAt)
        : createdAt?.toString();
    final validUntil = offerData['validUntil'];
    String validUntilText = '-';
    if (validUntil is DateTime) {
      validUntilText = DateFormat('dd/MM/yyyy').format(validUntil);
    }
    final logoUrl = providerSnapshot['logoUrl']?.toString();
    pw.ImageProvider? logoProvider;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        logoProvider = await networkImage(logoUrl);
      } catch (_) {
        logoProvider = null;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 68,
                  height: 68,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: logoProvider != null
                      ? pw.ClipRRect(
                          horizontalRadius: 10,
                          verticalRadius: 10,
                          child: pw.Image(logoProvider, fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Text(
                            'LOGO',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green700,
                            ),
                          ),
                        ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        providerName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Cotización comercial'),
                      if (operationEmail != null && operationEmail.isNotEmpty)
                        pw.Text(operationEmail),
                      if (operationPhone != null && operationPhone.isNotEmpty)
                        pw.Text(operationPhone),
                      if (billingEmail != null && billingEmail.isNotEmpty)
                        pw.Text('Facturación: $billingEmail'),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      quoteNumber,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (createdAtText != null) pw.Text('Fecha: $createdAtText'),
                    pw.Text('Válida hasta: $validUntilText'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Referencia del requerimiento'),
          _lineItem('Solicitud', requestTitle),
          _lineItem('Ciudad', requestCity),
          _lineItem('Vigencia', '$validityDays días'),
          _lineItem('Tiempo estimado', timeline),
          _lineItem('Garantía', warranty),
          _lineItem('Precio del servicio', pricingDescription),
          _lineItem('Tarifa base', pricingBreakdown),
          _lineItem(
            'Cantidad facturable',
            '${_formatNumericValue(serviceQuantity)} $quantityLabel',
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Resumen ejecutivo'),
          pw.Text(summary),
          pw.SizedBox(height: 14),
          _sectionTitle('Alcance del servicio'),
          pw.Text(scope),
          pw.SizedBox(height: 14),
          _sectionTitle('Entregables'),
          pw.Text(deliverables),
          pw.SizedBox(height: 14),
          _sectionTitle('Condiciones de ejecución'),
          pw.Text(conditions),
          pw.SizedBox(height: 14),
          _sectionTitle('Exclusiones'),
          pw.Text(exclusions),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              children: [
                _moneyLine('Subtotal', subtotal),
                _moneyLine(
                  appliesIva
                      ? 'IVA (${ivaRate.toStringAsFixed(0)}%)'
                      : 'IVA no aplica',
                  taxAmount,
                ),
                pw.Divider(color: PdfColors.grey400),
                _moneyLine(
                  'Total cotizado ($pricingUnit)',
                  totalAmount,
                  emphasized: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Términos de pago'),
          pw.Text(paymentTerms),
          pw.SizedBox(height: 14),
          _sectionTitle('Observaciones'),
          pw.Text(observations),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.amber200),
            ),
            child: pw.Text(
              'Documento generado desde SaneApp. El logo visible corresponde únicamente al logo corporativo configurado por el proveedor.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> downloadQuotePdf({
    required Map<String, dynamic> offerData,
    Map<String, dynamic>? requestData,
  }) async {
    final bytes = await buildQuotePdf(
      offerData: offerData,
      requestData: requestData,
    );
    final quoteNumber = offerData['quoteNumber']?.toString() ?? 'cotizacion';
    await Printing.sharePdf(bytes: bytes, filename: '$quoteNumber.pdf');
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
    );
  }

  static pw.Widget _lineItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _moneyLine(
    String label,
    double value, {
    bool emphasized = false,
  }) {
    final style = pw.TextStyle(
      fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: emphasized ? 13 : 11,
      color: emphasized ? PdfColors.green900 : PdfColors.black,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.Text('${value.toStringAsFixed(0)} COP', style: style),
        ],
      ),
    );
  }
}
