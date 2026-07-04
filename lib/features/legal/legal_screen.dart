import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LegalScreen extends StatefulWidget {
  final String assetPath;
  final String title;
  const LegalScreen({required this.assetPath, required this.title, super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  String _content = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      final data = await rootBundle.loadString(widget.assetPath);
      setState(() {
        _content = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _content = 'Error al cargar el archivo.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  _content,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
    );
  }
}

