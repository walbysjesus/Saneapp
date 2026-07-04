import 'package:flutter_test/flutter_test.dart';
import 'package:saneapp_pro_nuevo/features/providers/provider_ranking.dart';

void main() {
  group('provider ranking', () {
    test('relevance puts stronger commercial profile first', () {
      final services = [
        {
          'id': 'slow-low',
          'rating': 3.8,
          'ratingCount': 4,
          'responseTimeMinutes': 180,
          'commercialTier': 'C',
        },
        {
          'id': 'fast-trusted',
          'rating': 4.9,
          'ratingCount': 70,
          'responseTimeMinutes': 25,
          'commercialTier': 'A',
          'emergencyAvailability': true,
        },
      ];

      final sorted = sortProviderServices(
        services,
        ProviderSortOption.relevance,
      );

      expect(sorted.first['id'], 'fast-trusted');
    });

    test('fastestResponse sorts by lower minutes', () {
      final services = [
        {'id': 's1', 'responseTimeMinutes': 90},
        {'id': 's2', 'responseTimeMinutes': 20},
        {'id': 's3', 'responseTimeMinutes': 45},
      ];

      final sorted = sortProviderServices(
        services,
        ProviderSortOption.fastestResponse,
      );

      expect(sorted.map((e) => e['id']).toList(), ['s2', 's3', 's1']);
    });

    test('priceLow sorts ascending by priceFrom fallback to price', () {
      final services = [
        {'id': 'a', 'price': 300},
        {'id': 'b', 'priceFrom': 120},
        {'id': 'c', 'priceFrom': 200},
      ];

      final sorted = sortProviderServices(
        services,
        ProviderSortOption.priceLow,
      );

      expect(sorted.map((e) => e['id']).toList(), ['b', 'c', 'a']);
    });
  });
}
