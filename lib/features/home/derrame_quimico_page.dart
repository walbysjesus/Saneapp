import 'package:flutter/material.dart';

class DerrameQuimicoPage extends StatelessWidget {
  const DerrameQuimicoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Derrames QuÃ­micos'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: const Center(
        child: Text('Pantalla de atenciÃ³n a derrames quÃ­micos.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

