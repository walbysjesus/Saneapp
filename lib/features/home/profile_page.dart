import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saneapp_pro_nuevo/state/app_state.dart';
import 'package:saneapp_pro_nuevo/features/home/edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    // Eliminados nameController y emailController porque no se usan
    // Eliminadas variables locales no usadas: company, photoUrl, role, formKey
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF388E3C),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Ajustes',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          (user?.logoUrl != null &&
                              (user?.logoUrl?.isNotEmpty ?? false))
                          ? NetworkImage(user!.logoUrl!)
                          : null,
                      backgroundColor: const Color(0xFF388E3C),
                      child:
                          (user?.logoUrl == null ||
                              (user?.logoUrl?.isEmpty ?? true))
                          ? const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.companyName ?? user?.fullName ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          if (user?.role == 'generador')
                            Text(
                              'Tipo de cliente: ${user?.clientType == 'empresa' ? 'Empresa' : 'Persona natural'}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          if (user?.role == 'generador')
                            Text(
                              'Teléfono: ${user?.toMap()['phone'] ?? ''}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          if (user?.role == 'proveedor')
                            Text(
                              'TelÃ©fono: ${user?.toMap()['phone'] ?? ''}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF388E3C)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              color: const Color(0xFF66BB6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.white),
                title: const Text(
                  'Estado de aprobaciÃ³n',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  user?.approvalStatus ?? 'Pendiente',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (user != null && user.role == 'proveedor') ...[
              Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servicios que ofrece',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if ((user.toMap()['services'] as List?)?.isNotEmpty ??
                          false)
                        Wrap(
                          spacing: 8,
                          children: List<Widget>.from(
                            (user.toMap()['services'] as List<dynamic>).map(
                              (s) => Chip(label: Text(s.toString())),
                            ),
                          ),
                        )
                      else
                        const Text('No ha especificado servicios.'),
                      const SizedBox(height: 16),
                      Text(
                        'DescripciÃ³n',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.toMap()['serviceDescription'] ??
                            'Sin descripciÃ³n',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Cerrar sesiÃ³n',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
