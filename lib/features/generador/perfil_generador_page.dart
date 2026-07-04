import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/edit_profile_page.dart';
import '../../core/utils/adaptive_image_provider.dart';
import '../../core/widgets/role_guard.dart';
import '../../models/user_model.dart';
import '../../state/app_state.dart';

class PerfilGeneradorPage extends StatelessWidget {
  const PerfilGeneradorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: UserRole.generador,
      child: const _PerfilGeneradorContent(),
    );
  }
}

class _PerfilGeneradorContent extends StatelessWidget {
  const _PerfilGeneradorContent();

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _surface = Color(0xFFF6FAF7);

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final fallbackUser = appState.currentUser;
    final firebaseReady = Firebase.apps.isNotEmpty;
    final authUser = firebaseReady ? FirebaseAuth.instance.currentUser : null;
    final userId = authUser?.uid ?? fallbackUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Perfil cliente'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: firebaseReady
          ? FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final remoteData =
                    snapshot.data?.data() ?? const <String, dynamic>{};
                final user = _composeUserModel(
                  fallbackUser: fallbackUser,
                  authUser: authUser,
                  remoteData: remoteData,
                );

                return _ProfileBody(data: remoteData, user: user);
              },
            )
          : _ProfileBody(data: const <String, dynamic>{}, user: fallbackUser),
    );
  }

  UserModel? _composeUserModel({
    required UserModel? fallbackUser,
    required User? authUser,
    required Map<String, dynamic> remoteData,
  }) {
    if (fallbackUser == null && authUser == null && remoteData.isEmpty) {
      return null;
    }

    return UserModel.fromMap({
      'uid': authUser?.uid ?? fallbackUser?.uid ?? '',
      'email':
          authUser?.email ?? remoteData['email'] ?? fallbackUser?.email ?? '',
      'fullName': remoteData['fullName'] ?? fallbackUser?.fullName,
      'photoUrl': remoteData['photoUrl'] ?? fallbackUser?.photoUrl,
      'companyName': remoteData['companyName'] ?? fallbackUser?.companyName,
      'role': remoteData['role'] ?? fallbackUser?.role,
      'city': remoteData['city'] ?? fallbackUser?.city,
      'entityType': remoteData['entityType'] ?? fallbackUser?.entityType,
      'clientType': remoteData['clientType'] ?? fallbackUser?.clientType,
      'status': remoteData['status'] ?? fallbackUser?.status,
      'clientProfileCompleted':
          remoteData['clientProfileCompleted'] ??
          fallbackUser?.clientProfileCompleted,
      'verificationStatus':
          remoteData['verificationStatus'] ??
          fallbackUser?.verificationStatus?.name,
      'verifiedAt':
          remoteData['verifiedAt'] ??
          fallbackUser?.verifiedAt?.toIso8601String(),
    });
  }
}

class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final UserModel? user;

  const _ProfileBody({required this.data, required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName =
        data['companyName']?.toString() ??
        user?.companyName ??
        user?.fullName ??
        'Cliente SaneApp';
    final email = data['email']?.toString() ?? user?.email ?? '';
    final city = data['city']?.toString() ?? user?.city ?? 'Sin ciudad base';
    final entityType =
        data['entityType']?.toString() ?? user?.entityType ?? 'persona';
    final clientType =
        data['clientType']?.toString() ?? user?.clientType ?? 'Sin segmento';
    final operationAddress =
        data['operationAddress']?.toString() ?? 'Sin dirección operativa';
    final phone = data['phone']?.toString() ?? 'Sin teléfono registrado';
    final contactName =
        data['contactName']?.toString() ?? user?.fullName ?? displayName;
    final billingEmail = data['billingEmail']?.toString() ?? email;
    final serviceUrgency =
        data['serviceUrgency']?.toString() ?? 'Sin urgencia definida';
    final contractFrequency =
        data['contractFrequency']?.toString() ?? 'Sin frecuencia definida';
    final serviceInterests =
        (data['serviceInterests'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final profileCompleted =
        data['clientProfileCompleted'] == true ||
        user?.clientProfileCompleted == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ProfileHero(
          displayName: displayName,
          email: email,
          city: city,
          entityType: entityType,
          profileCompleted: profileCompleted,
          photoUrl: data['photoUrl']?.toString() ?? user?.photoUrl,
        ),
        const SizedBox(height: 16),
        _ActionStrip(
          onEdit: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
          },
          onRequests: () => Navigator.of(context).pushNamed('/mis_solicitudes'),
          onSupervision: () =>
              Navigator.of(context).pushNamed('/supervision_generador'),
        ),
        const SizedBox(height: 16),
        _InfoSectionCard(
          title: 'Estado de cuenta',
          child: Column(
            children: [
              _InfoRow(
                label: 'Estado de perfil',
                value: profileCompleted
                    ? 'Operativo'
                    : 'Pendiente por completar',
              ),
              _InfoRow(label: 'Tipo de cliente', value: clientType),
              _InfoRow(
                label: 'Entidad',
                value: entityType == 'empresa' ? 'Empresa' : 'Persona',
              ),
              _InfoRow(
                label: 'Verificación',
                value: user?.verified == true
                    ? 'Verificado'
                    : (user?.approvalStatus ?? 'Pendiente'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoSectionCard(
          title: 'Contacto operativo',
          child: Column(
            children: [
              _InfoRow(label: 'Responsable', value: contactName),
              _InfoRow(
                label: 'Correo principal',
                value: email.isEmpty ? 'Sin correo' : email,
              ),
              _InfoRow(label: 'Teléfono', value: phone),
              _InfoRow(
                label: 'Correo facturación',
                value: billingEmail.isEmpty
                    ? 'Sin correo de facturación'
                    : billingEmail,
              ),
              _InfoRow(label: 'Ciudad', value: city),
              _InfoRow(label: 'Dirección operativa', value: operationAddress),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoSectionCard(
          title: 'Preferencias de demanda',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: serviceInterests.isEmpty
                    ? const [
                        _SoftPill(label: 'Configura intereses prioritarios'),
                      ]
                    : serviceInterests
                          .map((item) => _SoftPill(label: item))
                          .toList(),
              ),
              const SizedBox(height: 14),
              _InfoRow(label: 'Urgencia habitual', value: serviceUrgency),
              _InfoRow(label: 'Frecuencia', value: contractFrequency),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoSectionCard(
          title: 'Acciones recomendadas',
          child: Column(
            children: [
              _RecommendationTile(
                title: profileCompleted
                    ? 'Perfil listo para operar'
                    : 'Completa tu perfil cliente',
                subtitle: profileCompleted
                    ? 'Ya puedes publicar con mejor precarga y trazabilidad.'
                    : 'Te falta cerrar la configuración operativa para publicar mejor.',
                icon: profileCompleted
                    ? Icons.verified_user_outlined
                    : Icons.assignment_late_outlined,
                accentColor: profileCompleted
                    ? const Color(0xFF1E7A4B)
                    : const Color(0xFFC24E00),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
              ),
              const SizedBox(height: 10),
              _RecommendationTile(
                title: 'Revisar solicitudes y supervisión',
                subtitle:
                    'Monitorea estado, ofertas y servicios con acompañamiento.',
                icon: Icons.dashboard_customize_outlined,
                accentColor: const Color(0xFF0C4F31),
                onTap: () =>
                    Navigator.of(context).pushNamed('/mis_solicitudes'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String displayName;
  final String email;
  final String city;
  final String entityType;
  final bool profileCompleted;
  final String? photoUrl;

  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.city,
    required this.entityType,
    required this.profileCompleted,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = resolveAdaptiveImageProvider(photoUrl);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            _PerfilGeneradorContent._brandGreen,
            _PerfilGeneradorContent._brandGreenSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(
                        Icons.person,
                        size: 34,
                        color: _PerfilGeneradorContent._brandGreen,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPillProfile(label: city),
              _HeroPillProfile(
                label: entityType == 'empresa'
                    ? 'Cliente empresa'
                    : 'Cliente persona',
              ),
              _HeroPillProfile(
                label: profileCompleted
                    ? 'Perfil operativo completo'
                    : 'Perfil pendiente',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPillProfile extends StatelessWidget {
  final String label;

  const _HeroPillProfile({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onRequests;
  final VoidCallback onSupervision;

  const _ActionStrip({
    required this.onEdit,
    required this.onRequests,
    required this.onSupervision,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Editar',
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Solicitudes',
            icon: Icons.assignment_outlined,
            onPressed: onRequests,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Supervisión',
            icon: Icons.verified_user_outlined,
            onPressed: onSupervision,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _PerfilGeneradorContent._brandGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;

  const _SoftPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _PerfilGeneradorContent._brandGreenSoft,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _RecommendationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FBF9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE7DF)),
          ),
          child: Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
