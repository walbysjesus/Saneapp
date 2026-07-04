import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class MercadoPagoWebView extends StatefulWidget {
  final String preferenceUrl;
  const MercadoPagoWebView({required this.preferenceUrl, super.key});

  @override
  State<MercadoPagoWebView> createState() => _MercadoPagoWebViewState();
}

class _MercadoPagoWebViewState extends State<MercadoPagoWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.preferenceUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago MercadoPago')),
      body: WebViewWidget(controller: _controller),
    );
  }
}

