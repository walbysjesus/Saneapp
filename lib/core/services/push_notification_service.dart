import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Inicializa notificaciones push y solicita permisos
  static Future<void> initialize(BuildContext context) async {
    try {
      await _messaging.requestPermission();

      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          final notification = message.notification!;
          debugPrint('NotificaciÃ³n recibida: '
              '${notification.title != null ? '${notification.title}: ' : ''}${notification.body ?? ''}');
        }
      });
    } catch (error, stackTrace) {
      debugPrint('PushNotificationService.initialize fallÃ³: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

