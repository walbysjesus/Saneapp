import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:io';

class AnalyticsService {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static bool _hasInjectedAnalytics = false;

  /// Permite inyectar un mock para testing
  static void setAnalyticsInstance(FirebaseAnalytics analyticsInstance) {
    analytics = analyticsInstance;
    _hasInjectedAnalytics = true;
  }

  static Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    if (Platform.environment['FLUTTER_TEST'] == 'true' && !_hasInjectedAnalytics) {
      return;
    }
    await analytics.logEvent(name: name, parameters: params);
  }

  static Future<void> logScreen(String screenName) async {
    if (Platform.environment['FLUTTER_TEST'] == 'true' && !_hasInjectedAnalytics) {
      return;
    }
    await analytics.logScreenView(screenName: screenName);
  }
}

