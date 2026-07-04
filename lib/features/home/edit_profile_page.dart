import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saneapp_pro_nuevo/state/app_state.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/adaptive_image_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _surface = Color(0xFFF6FAF7);

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _logoUrl = image.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Logo cargado')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar imagen: $e')));
      }
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  String? _clientType;
  String? _logoUrl;

  ImageProvider<Object>? get _logoImageProvider {
    return resolveAdaptiveImageProvider(_logoUrl);
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _nameController.text = user?.fullName ?? user?.companyName ?? '';
    _phoneController.text = user?.toMap()['phone'] ?? '';
    _companyController.text = user?.companyName ?? '';
    _clientType = user?.toMap()['clientType'];
    _logoUrl = user?.logoUrl;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = <String, dynamic>{};
    if (_clientType != null) data['clientType'] = _clientType;
    data['entityType'] = _clientType;
    if (_nameController.text.trim().isNotEmpty) {
      data['fullName'] = _nameController.text.trim();
    }
    if (_companyController.text.trim().isNotEmpty) {
      data['companyName'] = _companyController.text.trim();
    }
    if (_phoneController.text.trim().isNotEmpty) {
      data['phone'] = _phoneController.text.trim();
    }
    if (_logoUrl != null) data['logoUrl'] = _logoUrl;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppState>(context).currentUser;
    final isGenerador = user?.role == 'generador';
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _EditProfileHero(
              title: isGenerador
                  ? 'Perfil cliente en edición'
                  : 'Perfil profesional en edición',
              subtitle: isGenerador
                  ? 'Actualiza identidad, contacto y datos base con el mismo estándar visual de tu cuenta.'
                  : 'Ajusta tu identidad comercial y datos operativos desde un panel más sólido.',
              logoUrl: _logoUrl,
            ),
            const SizedBox(height: 16),
            _EditSectionCard(
              title: 'Resumen de edición',
              subtitle:
                  'Los cambios que guardes aquí alimentan tu perfil operativo y mejoran la experiencia en solicitudes y supervisión.',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusPill(label: isGenerador ? 'Cliente' : 'Proveedor'),
                  _StatusPill(
                    label: _clientType == 'empresa'
                        ? 'Empresa'
                        : (_clientType == 'persona'
                              ? 'Persona natural'
                              : 'Sin clasificar'),
                  ),
                  _StatusPill(
                    label: _phoneController.text.trim().isEmpty
                        ? 'Falta teléfono'
                        : 'Contacto listo',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _EditSectionCard(
              title: 'Información base',
              subtitle:
                  'Define cómo quieres presentarte dentro del marketplace y en tu operación diaria.',
              child: Column(
                children: [
                  if (isGenerador) ...[
                    _StyledField(
                      controller: _nameController,
                      label: 'Nombre completo o empresa',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Campo requerido';
                        }
                        if (v.trim().length < 3) {
                          return 'Debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _clientType,
                      decoration: _fieldDecoration('Tipo de cliente'),
                      items: const [
                        DropdownMenuItem(
                          value: 'empresa',
                          child: Text('Empresa'),
                        ),
                        DropdownMenuItem(
                          value: 'persona',
                          child: Text('Persona natural'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _clientType = v),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                    ),
                  ] else ...[
                    _StyledField(
                      controller: _companyController,
                      label: 'Nombre de empresa',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Campo requerido'
                          : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _EditSectionCard(
              title: 'Contacto operativo',
              subtitle:
                  'Estos datos se usan para coordinación, seguimiento y comunicación principal.',
              child: Column(
                children: [
                  _StyledField(
                    controller: _phoneController,
                    label: 'Teléfono de contacto',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      final phone = v.replaceAll(RegExp(r'[^0-9]'), '');
                      if (phone.length < 7) {
                        return 'Debe tener al menos 7 dígitos';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
                        return 'Solo se permiten números';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _EditSectionCard(
              title: 'Identidad visual',
              subtitle:
                  'Mantén tu foto o logo consistente con la experiencia del perfil cliente.',
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFFEAF5EE),
                    backgroundImage: _logoImageProvider,
                    child: _logoImageProvider == null
                        ? const Icon(
                            Icons.person_outline,
                            size: 32,
                            color: _brandGreen,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foto o logo principal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Usa una imagen clara para reforzar tu identidad dentro de la cuenta.',
                          style: TextStyle(color: Colors.black54, height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: _pickLogo,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFEAF5EE),
                            foregroundColor: _brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Actualizar imagen'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _brandGreenSoft, width: 1.4),
      ),
    );
  }
}

class _EditProfileHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? logoUrl;

  const _EditProfileHero({
    required this.title,
    required this.subtitle,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = resolveAdaptiveImageProvider(logoUrl);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            _EditProfilePageState._brandGreen,
            _EditProfilePageState._brandGreenSoft,
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
                radius: 32,
                backgroundColor: Colors.white,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(
                        Icons.edit_note_outlined,
                        size: 30,
                        color: _EditProfilePageState._brandGreen,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Edición operativa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EditSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _EditSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

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
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _StyledField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _EditProfilePageState._brandGreenSoft,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _EditProfilePageState._brandGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
