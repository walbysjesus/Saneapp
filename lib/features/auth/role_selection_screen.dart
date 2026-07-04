import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../state/app_state.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);
const _cardBorder = Color(0xFFDCE7DF);

// Primero la función utilitaria
Color getRoleColor(String title) {
  switch (title.toLowerCase()) {
    case 'generador':
      return const Color(0xFF008037); // Verde corporativo
    case 'proveedor':
      return const Color(0xFF1976D2); // Azul
    case 'supervisor':
      return const Color(0xFFFF9800); // Naranja
    default:
      return _brandGreenSoft;
  }
}

// Luego el widget RoleCard
class RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  final Key? key;
  const RoleCard({
    this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleColor = getRoleColor(title);
    return Card(
      elevation: selected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? _brandGreen : _cardBorder,
          width: selected ? 1.8 : 1,
        ),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: Icon(icon, size: 30, color: roleColor)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 18,
                color: selected ? _brandGreen : roleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _loading = false;
  bool _showAllRoles = false;
  String? _selectedRole;
  String? _entityType; // 'empresa' o 'persona'

  String? _marketplaceIntent(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      return args['marketplaceIntent']?.toString();
    }
    return null;
  }

  Future<void> _selectRole(String role) async {
    setState(() {
      _selectedRole = role;
    });
    if (role == 'generador' || role == 'proveedor') {
      // Mostrar diálogo para empresa/persona
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Eres empresa o persona?'),
          content: Text('Selecciona el tipo de entidad para continuar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'empresa'),
              child: const Text('Empresa'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'persona'),
              child: const Text('Persona'),
            ),
          ],
        ),
      );
      setState(() {
        _entityType = result;
      });
    } else {
      setState(() {
        _entityType = null;
      });
    }
  }

  Future<void> _confirmRole() async {
    setState(() {
      _loading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedRole == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró una sesión activa. Vuelve a iniciar el registro.',
            ),
          ),
        );
        setState(() {
          _loading = false;
        });
      }
      return;
    }
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    Map<String, dynamic> data = {
      'role': _selectedRole,
      'status': _selectedRole == 'supervisor'
          ? 'pending_review'
          : (_selectedRole == 'proveedor' ? 'pending_documents' : 'active'),
      'entityType': _entityType ?? '',
      if (_selectedRole == 'generador') 'clientType': _entityType ?? '',
      if (_selectedRole == 'generador') 'clientProfileCompleted': false,
      if (_selectedRole == 'supervisor') 'supervisorProfileCompleted': false,
      if (_selectedRole == 'supervisor') 'supervisorAssessmentPassed': false,
      if (_selectedRole == 'supervisor') 'supervisorAssessmentScore': 0,
    };
    await userDoc.set(data, SetOptions(merge: true));
    if (!mounted) return;
    final selectedRole = roleFromString(_selectedRole);
    Provider.of<AppState>(context, listen: false).setUser(
      UserModel(
        uid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName,
        photoUrl: user.photoURL,
        role: _selectedRole,
        entityType: _entityType,
        clientType: _selectedRole == 'generador' ? _entityType : null,
        status: data['status'] as String?,
        clientProfileCompleted:
            data['clientProfileCompleted'] as bool? ?? false,
        supervisorProfileCompleted:
            data['supervisorProfileCompleted'] as bool? ?? false,
        supervisorAssessmentPassed:
            data['supervisorAssessmentPassed'] as bool? ?? false,
        supervisorAssessmentScore: (data['supervisorAssessmentScore'] as num?)
            ?.toInt(),
      ),
      selectedRole,
    );
    if (_selectedRole == 'supervisor') {
      Navigator.pushReplacementNamed(context, '/supervisor-profile-setup');
    } else if (_selectedRole == 'proveedor') {
      Navigator.pushReplacementNamed(context, '/provider-profile-setup');
    } else if (_selectedRole == 'generador') {
      Navigator.pushReplacementNamed(context, '/client-profile');
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceIntent = _marketplaceIntent(context);
    final contextualSelection =
        !_showAllRoles &&
        (marketplaceIntent == 'buy' || marketplaceIntent == 'sell');
    final title = marketplaceIntent == 'sell'
        ? 'Activa tu perfil de venta'
        : marketplaceIntent == 'buy'
        ? 'Activa tu perfil de compra'
        : 'Selecciona tu rol';
    final subtitle = marketplaceIntent == 'sell'
        ? 'Estás entrando por la ruta de vender en SaneApp. Configura tu cuenta de proveedor para publicar servicios y operar en la vitrina.'
        : marketplaceIntent == 'buy'
        ? 'Estás entrando por la ruta de compra. Configura tu cuenta de generador para publicar necesidades y contratar servicios.'
        : 'Elige el flujo adecuado y adaptaremos tu onboarding según el rol operativo que vayas a cumplir en la plataforma.';
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [_brandGreen, _brandGreenSoft],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (!contextualSelection || marketplaceIntent == 'buy') ...[
                  RoleCard(
                    title: 'Generador',
                    description: 'Solicito servicios ambientales.',
                    icon: Icons.person,
                    selected: _selectedRole == 'generador',
                    onTap: () => _selectRole('generador'),
                  ),
                  const SizedBox(height: 24),
                ],
                if (!contextualSelection || marketplaceIntent == 'sell') ...[
                  RoleCard(
                    title: 'Proveedor',
                    description: 'Ofrezco servicios ambientales.',
                    icon: Icons.business_center,
                    selected: _selectedRole == 'proveedor',
                    onTap: () => _selectRole('proveedor'),
                  ),
                  const SizedBox(height: 24),
                ],
                if (!contextualSelection) ...[
                  RoleCard(
                    title: 'Supervisor',
                    description: 'Superviso y verifico servicios.',
                    icon: Icons.shield,
                    selected: _selectedRole == 'supervisor',
                    onTap: () => _selectRole('supervisor'),
                  ),
                  const SizedBox(height: 24),
                ],
                if (contextualSelection)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showAllRoles = true),
                      icon: const Icon(Icons.tune_outlined),
                      label: const Text('Ver otros roles de la plataforma'),
                    ),
                  ),
                const SizedBox(height: 32),
                if (_selectedRole != null &&
                    (_selectedRole == 'supervisor' || _entityType != null))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirmRole,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Continuar'),
                    ),
                  ),
                const SizedBox(height: 32),
                // Botón para verificar correo
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.mark_email_read),
                    label: const Text('Ya verifiqué mi correo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brandGreen,
                      side: const BorderSide(color: _brandGreen),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      await user?.reload();
                      if (user != null && user.emailVerified) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Correo verificado correctamente!'),
                            backgroundColor: _brandGreenSoft,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tu correo aún no está verificado. Revisa tu bandeja de entrada.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
