import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// ConfiguraciÃ³n de Firebase para SaneApp
/// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// âœ” Limpio, modular y listo para producciÃ³n
/// âœ” Compatible con Android, iOS y Web

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'This platform is not supported by Firebase yet.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBt7mmvrddA67asE0Bm3wUrIxGcm2lXY3g',
    appId: '1:626588374973:android:5b869f178afd9ec96364d4',
    messagingSenderId: '626588374973',
    projectId: 'saneapp-clean',
    storageBucket: 'saneapp-clean.firebasestorage.app',
  );

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ ANDROID â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAk-q8BjTaDVBm9DAX-yEKQVd3MrY5S5Qc',
    appId: '1:626588374973:ios:996cac6dd5cfeb236364d4',
    messagingSenderId: '626588374973',
    projectId: 'saneapp-clean',
    storageBucket: 'saneapp-clean.firebasestorage.app',
    iosBundleId: 'com.example.saneapp',
  );

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ IOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ WEB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_WEB_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET.appspot.com',
  );

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ MACOS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MACOS_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET.appspot.com',
    iosBundleId: 'com.yourcompany.saneapp.macos',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    androidClientId: 'YOUR_MACOS_ANDROID_CLIENT_ID',
  );
}
