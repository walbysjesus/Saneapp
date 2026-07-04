import 'package:flutter/material.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FacturaciÃ³n ElectrÃ³nica')),
      body: Center(
        child: Text('AquÃ­ irÃ¡ la gestiÃ³n de facturas electrÃ³nicas.'),
      ),
    );
  }
}

