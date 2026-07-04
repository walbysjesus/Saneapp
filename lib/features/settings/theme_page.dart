import 'package:flutter/material.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _success = 'Tema guardado';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tema de la app')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (v) => setState(() => _themeMode = v!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Oscuro'),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (v) => setState(() => _themeMode = v!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('SegÃºn sistema'),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (v) => setState(() => _themeMode = v!),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_success != null) Text(_success!, style: const TextStyle(color: Colors.green)),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

