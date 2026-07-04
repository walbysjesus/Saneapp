import 'package:flutter_test/flutter_test.dart';
import 'package:saneapp_pro_nuevo/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    test('labelForMethod retorna etiqueta legible', () {
      expect(
        PaymentService.labelForMethod(PaymentMethod.mercadoPago),
        'Mercado Pago',
      );
      expect(PaymentService.labelForMethod(PaymentMethod.payu), 'PayU');
    });

    test('calculateCommissionAndPayout conserva suma de montos', () {
      const total = 100000;
      final result = PaymentService.calculateCommissionAndPayout(total);
      expect(result['commission'], isNotNull);
      expect(result['payout'], isNotNull);
      expect(result['commission']! + result['payout']!, total);
    });

    test('buildReceiptNumber usa prefijo SAN-', () {
      final receipt = PaymentService.buildReceiptNumber();
      expect(receipt.startsWith('SAN-'), isTrue);
      expect(receipt.length, greaterThan(8));
    });
  });
}
