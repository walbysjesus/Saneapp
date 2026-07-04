import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Locale? _selectedLocale;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: false);
    _selectedLocale = appState.locale;
  }

  void _changeLanguage(Locale? locale) async {
    if (locale == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.setLocale(locale);
      setState(() {
        _selectedLocale = locale;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)?.error ?? 'Error';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.settings ?? 'Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text(loc?.settings_language ?? 'Idioma'),
            leading: const Icon(Icons.language),
            subtitle: DropdownButton<Locale>(
              value: _selectedLocale,
              items: AppLocalizations.supportedLocales.map((locale) {
                String langName;
                switch (locale.languageCode) {
                  case 'es':
                    langName = 'EspaÃ±ol';
                    break;
                  case 'en':
                    langName = 'English';
                    break;
                  case 'pt':
                    langName = 'PortuguÃªs';
                    break;
                  default:
                    langName = locale.languageCode.toUpperCase();
                }
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Text(langName),
                );
              }).toList(),
              onChanged: _loading ? null : _changeLanguage,
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('InformaciÃ³n de la cuenta'),
            onTap: () => Navigator.pushNamed(context, '/account-info'),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar contraseÃ±a'),
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            onTap: () => Navigator.pushNamed(context, '/notification-preferences'),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Tema de la app'),
            onTap: () => Navigator.pushNamed(context, '/theme'),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Eliminar cuenta'),
            onTap: () => Navigator.pushNamed(context, '/delete-account'),
          ),
        ],
      ),
    );
  }
}

