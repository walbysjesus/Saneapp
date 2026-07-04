import 'package:flutter/material.dart';

import 'provider_profile_status.dart';

Future<bool> ensureProviderCanOperate(
  BuildContext context, {
  String message = 'Debes completar tu registro de proveedor para realizar esta acción.',
}) async {
  const profileStatusService = ProviderProfileStatusService();
  final status = await profileStatusService.loadCurrentUserStatus();
  if (status.canOperate) {
    return true;
  }

  if (!context.mounted) {
    return false;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Registro incompleto'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pushReplacementNamed('/provider-profile-setup');
          },
          child: const Text('Ir a registro'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
  return false;
}

class ProviderProfileRequiredView extends StatelessWidget {
  final String message;

  const ProviderProfileRequiredView({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed('/provider-profile-setup'),
                child: const Text('Completar registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProviderOfflineView extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  const ProviderOfflineView({
    super.key,
    this.title = 'Sin conexión con la plataforma',
    this.message =
        'No fue posible consultar tu estado ni cargar información en tiempo real. Verifica tu conexión e inténtalo nuevamente.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Color(0xFFC27A00),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry == null
                    ? null
                    : () async {
                        await onRetry!.call();
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}