import 'package:flutter/material.dart';

class AccountInfoPage extends StatelessWidget {
  const AccountInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // AquÃ­ deberÃ­as obtener los datos reales del usuario
    final String name = 'Nombre de usuario';
    final String email = 'usuario@email.com';
    return Scaffold(
      appBar: AppBar(title: const Text('InformaciÃ³n de la cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: $name', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Correo: $email', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navegar a editar perfil si lo deseas
              },
              child: const Text('Editar perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

