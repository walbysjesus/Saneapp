import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'payment_service.dart';

class PaymentGatewaySession {
  const PaymentGatewaySession({
    required this.sessionId,
    required this.checkoutUrl,
    required this.gatewayReference,
    required this.raw,
  });

  final String sessionId;
  final String checkoutUrl;
  final String gatewayReference;
  final Map<String, dynamic> raw;
}

class PaymentGatewayClient {
  PaymentGatewayClient({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  String _resolveBaseUrl() {
    const fromDefine = String.fromEnvironment('PAYMENT_FUNCTIONS_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw Exception(
        'No se pudo resolver PAYMENT_FUNCTIONS_BASE_URL. Define --dart-define=PAYMENT_FUNCTIONS_BASE_URL.',
      );
    }
    return 'https://us-central1-$projectId.cloudfunctions.net';
  }

  Future<PaymentGatewaySession> createSession({
    required String paymentId,
    required String requestId,
    required PaymentMethod method,
    required int amount,
    required String currency,
    required String description,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Debes iniciar sesion para crear el pago.');
    }

    final idToken = await currentUser.getIdToken(true);
    final baseUrl = _resolveBaseUrl();
    final endpoint = Uri.parse('$baseUrl/createGatewayPaymentSession');

    final request = await _httpClient.postUrl(endpoint);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    request.add(
      utf8.encode(
        jsonEncode({
          'paymentId': paymentId,
          'requestId': requestId,
          'method': method.name,
          'amount': amount,
          'currency': currency,
          'description': description,
        }),
      ),
    );
    final response = await request.close();
    final responseBody = await utf8.decodeStream(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No fue posible crear la sesion de pago (${response.statusCode}): $responseBody',
      );
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta invalida al crear sesion de pago.');
    }

    final checkoutUrl = (decoded['checkoutUrl'] ?? '').toString().trim();
    final sessionId = (decoded['sessionId'] ?? '').toString().trim();
    final gatewayReference = (decoded['gatewayReference'] ?? '')
        .toString()
        .trim();
    if (checkoutUrl.isEmpty || sessionId.isEmpty) {
      throw Exception('La pasarela no devolvio checkoutUrl/sessionId validos.');
    }

    return PaymentGatewaySession(
      sessionId: sessionId,
      checkoutUrl: checkoutUrl,
      gatewayReference: gatewayReference,
      raw: decoded,
    );
  }
}
