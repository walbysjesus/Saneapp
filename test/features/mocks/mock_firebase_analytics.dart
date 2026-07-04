import 'package:mockito/mockito.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {
	@override
	Future<void> logScreenView({
		String? screenName,
		String? screenClass,
		Map<String, Object?>? parameters,
		AnalyticsCallOptions? callOptions,
	}) async {
		return Future.value();
	}

	@override
	Future<void> logEvent({
		required String name,
		Map<String, Object?>? parameters,
		AnalyticsCallOptions? callOptions,
	}) async {
		return Future.value();
	}
}

