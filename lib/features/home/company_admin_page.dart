import 'package:flutter/material.dart';

class CompanyAdminPage extends StatelessWidget {
  const CompanyAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administraciÃ³n'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified),
                title: const Text('VerificaciÃ³n y certificaciÃ³n'),
                subtitle: const Text('Solicita el sello de empresa verificada.'),
                onTap: () => Navigator.pushNamed(context, '/verification'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Gestionar servicios'),
                subtitle: const Text('Agrega, edita o elimina tus servicios.'),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('Solicitudes recibidas'),
                subtitle: const Text('Revisa y responde solicitudes de clientes.'),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Editar perfil empresa'),
                subtitle: const Text('Actualiza tu informaciÃ³n y datos de contacto.'),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Ver mÃ©tricas y reportes'),
                subtitle: const Text('Consulta estadÃ­sticas de tus servicios.'),
                onTap: () => Navigator.pushNamed(context, '/metrics'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
