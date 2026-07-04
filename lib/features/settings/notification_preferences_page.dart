import 'package:flutter/material.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  bool _push = true;
  bool _email = false;
  bool _sms = false;
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
      _success = 'Preferencias guardadas';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Notificaciones push'),
              value: _push,
              onChanged: (v) => setState(() => _push = v),
            ),
            SwitchListTile(
              title: const Text('Notificaciones por email'),
              value: _email,
              onChanged: (v) => setState(() => _email = v),
            ),
            SwitchListTile(
              title: const Text('Notificaciones por SMS'),
              value: _sms,
              onChanged: (v) => setState(() => _sms = v),
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

