import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    return SimpleDialog(
      title: Text(AppLocalizations.of(context)?.appTitle ?? 'Idioma'),
      children: [
        ...AppLocalizations.supportedLocales.map((locale) {
          final isSelected = locale == currentLocale;
          return ListTile(
            title: Text(_getLanguageName(locale.languageCode)),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              Provider.of<AppState>(context, listen: false).setLocale(locale);
              Navigator.of(context).pop();
            },
          );
        }),
      ],
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      default:
        return code;
    }
  }
}

