import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:saneapp_pro_nuevo/core/services/analytics_service.dart';


@GenerateMocks([FirebaseAnalytics])
import 'analytics_service_test.mocks.dart';

void main() {
  group('AnalyticsService', () {
    late MockFirebaseAnalytics mockAnalytics;
    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      // Reemplaza la instancia interna por el mock usando el setter pÃºblico
      AnalyticsService.setAnalyticsInstance(mockAnalytics);
    });

    test('logEvent llama a FirebaseAnalytics.logEvent con los parÃ¡metros correctos', () async {
      const eventName = 'test_event';
      final params = {'key': 'value'};
      when(mockAnalytics.logEvent(name: eventName, parameters: params)).thenAnswer((_) => Future.value());

      await AnalyticsService.logEvent(eventName, params: params);

      verify(mockAnalytics.logEvent(name: eventName, parameters: params)).called(1);
    });

    test('logScreen llama a FirebaseAnalytics.logScreenView con el nombre correcto', () async {
      const screenName = 'TestScreen';
      when(mockAnalytics.logScreenView(screenName: screenName)).thenAnswer((_) => Future.value());

      await AnalyticsService.logScreen(screenName);

      verify(mockAnalytics.logScreenView(screenName: screenName)).called(1);
    });
  });
}


