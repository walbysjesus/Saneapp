import 'package:flutter/material.dart';

class ChatDialog extends StatelessWidget {
  final String requestId;
  final String currentUserId;

  const ChatDialog({super.key, required this.requestId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chat interno'),
      content: const Text('AquÃ­ irÃ¡ el chat interno gestionado por SaneApp.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

