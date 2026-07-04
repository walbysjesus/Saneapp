import 'package:flutter/material.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _confirm = false;
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _deleteAccount() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    // AquÃ­ va la lÃ³gica real de eliminaciÃ³n de cuenta
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _success = 'Cuenta eliminada correctamente';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Esta acciÃ³n es irreversible. Â¿EstÃ¡s seguro?'),
            CheckboxListTile(
              title: const Text('SÃ­, deseo eliminar mi cuenta'),
              value: _confirm,
              onChanged: (v) => setState(() => _confirm = v ?? false),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_success != null) Text(_success!, style: const TextStyle(color: Colors.green)),
            ElevatedButton(
              onPressed: _confirm && !_loading ? _deleteAccount : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

