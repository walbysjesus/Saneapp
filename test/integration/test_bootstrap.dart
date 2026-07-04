import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';

import 'package:saneapp_pro_nuevo/firebase_options.dart';

Future<void> ensureFirebaseInitializedForTests() async {
  setupFirebaseCoreMocks();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    // Ignore repeated/mocked initialization errors in test environment.
  }
}
