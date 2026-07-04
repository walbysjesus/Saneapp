import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/location_data.dart';
import '../../models/user_model.dart';
import '../../state/app_state.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _surfaceTint = Color(0xFFF3F8F4);
  static const _interestOptions = <String>[
    'Gestión de residuos',
    'Servicios Vactor',
    'Limpieza industrial',
    'Transporte de residuos',
    'Emergencias 24/7',
    'Tratamiento de aguas',
    'Consultoría ambiental',
  ];
  static const _frequencyOptions = <String>[
    'Puntual',
    'Mensual',
    'Semanal',
    'Contrato permanente',
  ];
  static const _urgencyOptions = <String>[
    'Programado',
    'En menos de 72 horas',
    'Urgente 24/7',
  ];
  static const _sectorOptions = <String>[
    'Industrial',
    'Construcción',
    'Hospitalario',
    'Oil & Gas',
    'Alimentos',
    'Retail',
    'Servicios',
    'Gobierno',
    'Otro',
  ];

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nitController = TextEditingController();
  final _operationAddressController = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _acceptedTerms = false;
  bool _loading = true;
  bool _saving = false;
  bool _hasUnsavedChanges = false;
  String? _termsError;
  String? _entityType;
  String? _selectedCountry;
  String? _selectedDepartment;
  String? _selectedCity;
  String? _selectedSector;
  String? _selectedFrequency;
  String? _selectedUrgency;
  final Set<String> _selectedInterests = <String>{};

  @override
  void initState() {
    super.initState();
    _attachDirtyListeners();
    _loadProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactNameController.dispose();
    _jobTitleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nitController.dispose();
    _operationAddressController.dispose();
    _billingEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _attachDirtyListeners() {
    for (final controller in [
      _companyNameController,
      _contactNameController,
      _jobTitleController,
      _phoneController,
      _emailController,
      _nitController,
      _operationAddressController,
      _billingEmailController,
      _notesController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_hasUnsavedChanges && mounted) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _loadProfile() async {
    final appStateUser = Provider.of<AppState>(
      context,
      listen: false,
    ).currentUser;
    final hasFirebase = Firebase.apps.isNotEmpty;
    final user = hasFirebase ? FirebaseAuth.instance.currentUser : null;
    if (user == null) {
      if (appStateUser != null) {
        _entityType =
            appStateUser.entityType ?? appStateUser.clientType ?? 'empresa';
        _companyNameController.text =
            appStateUser.companyName ?? appStateUser.fullName ?? '';
        _contactNameController.text = appStateUser.fullName ?? '';
        _emailController.text = appStateUser.email;
        _selectedCity = appStateUser.city;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      return;
    }

    final userDoc = await cf.FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data() ?? <String, dynamic>{};

    _entityType = (data['entityType'] as String?)?.isNotEmpty == true
        ? data['entityType'] as String
        : (data['clientType'] as String?)?.isNotEmpty == true
        ? data['clientType'] as String
        : 'empresa';
    _companyNameController.text =
        (data['companyName'] as String?) ?? (data['fullName'] as String?) ?? '';
    _contactNameController.text =
        (data['contactName'] as String?) ?? (data['fullName'] as String?) ?? '';
    _jobTitleController.text = (data['jobTitle'] as String?) ?? '';
    _phoneController.text = (data['phone'] as String?) ?? '';
    _emailController.text =
        (data['operationalEmail'] as String?) ?? user.email ?? '';
    _nitController.text = (data['nit'] as String?) ?? '';
    _operationAddressController.text =
        (data['operationAddress'] as String?) ?? '';
    _billingEmailController.text =
        (data['billingEmail'] as String?) ?? (data['email'] as String?) ?? '';
    _notesController.text = (data['serviceNotes'] as String?) ?? '';
    _selectedCountry = (data['country'] as String?) ?? 'Colombia';
    _selectedDepartment = data['department'] as String?;
    _selectedCity = data['city'] as String?;
    _selectedSector = data['sector'] as String?;
    _selectedFrequency = data['contractFrequency'] as String?;
    _selectedUrgency = data['serviceUrgency'] as String?;
    _acceptedTerms = data['termsAccepted'] == true;
    _selectedInterests
      ..clear()
      ..addAll((data['serviceInterests'] as List?)?.cast<String>() ?? const []);

    if (mounted) {
      setState(() {
        _loading = false;
        _hasUnsavedChanges = false;
      });
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hay cambios sin guardar'),
        content: const Text(
          'Si sales ahora perderás el avance reciente del perfil cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir editando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  Future<void> _openLegalDialog() async {
    final assets = DefaultAssetBundle.of(context);
    final contents = await Future.wait([
      assets.loadString('assets/legal/terminos_condiciones.txt'),
      assets.loadString('assets/legal/politica_privacidad.txt'),
    ]);

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Términos y privacidad'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Términos y condiciones',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(contents[0]),
                const SizedBox(height: 20),
                const Text(
                  'Política de privacidad',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(contents[1]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_acceptedTerms) {
      setState(() {
        _termsError = 'Debes aceptar los términos y la política de datos.';
      });
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedInterests.isEmpty ||
        _selectedFrequency == null ||
        _selectedUrgency == null ||
        _selectedCountry == null ||
        _selectedCity == null ||
        _selectedSector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa intereses, frecuencia, urgencia, sector y ubicación antes de continuar.',
          ),
        ),
      );
      return;
    }

    final hasFirebase = Firebase.apps.isNotEmpty;
    final user = hasFirebase ? FirebaseAuth.instance.currentUser : null;
    if (user == null) {
      return;
    }

    setState(() {
      _saving = true;
      _termsError = null;
    });

    final companyName = _entityType == 'empresa'
        ? _companyNameController.text.trim()
        : _contactNameController.text.trim();

    final payload = <String, dynamic>{
      'role': 'generador',
      'status': 'active',
      'entityType': _entityType,
      'clientType': _entityType,
      'clientProfileCompleted': true,
      'companyName': companyName,
      'fullName': _contactNameController.text.trim(),
      'contactName': _contactNameController.text.trim(),
      'jobTitle': _jobTitleController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': user.email,
      'operationalEmail': _emailController.text.trim(),
      'billingEmail': _billingEmailController.text.trim(),
      'nit': _entityType == 'empresa' ? _nitController.text.trim() : null,
      'operationAddress': _operationAddressController.text.trim(),
      'country': _selectedCountry,
      'department': _selectedDepartment,
      'city': _selectedCity,
      'sector': _selectedSector,
      'contractFrequency': _selectedFrequency,
      'serviceUrgency': _selectedUrgency,
      'serviceInterests': _selectedInterests.toList()..sort(),
      'serviceNotes': _notesController.text.trim(),
      'termsAccepted': true,
      'updatedAt': cf.FieldValue.serverTimestamp(),
    };

    try {
      await cf.FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(payload, cf.SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      Provider.of<AppState>(context, listen: false).setUser(
        UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: _contactNameController.text.trim(),
          photoUrl: user.photoURL,
          companyName: companyName,
          role: 'generador',
          city: _selectedCity,
          entityType: _entityType,
          clientType: _entityType,
          status: 'active',
          clientProfileCompleted: true,
        ),
        UserRole.generador,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Perfil cliente completado. Ya puedes contratar servicios.',
          ),
        ),
      );
      setState(() {
        _hasUnsavedChanges = false;
      });
      Navigator.pushReplacementNamed(context, '/buyer_main');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible guardar el perfil: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStateUser = Provider.of<AppState>(context).currentUser;
    final hasFirebase = Firebase.apps.isNotEmpty;
    final user = hasFirebase ? FirebaseAuth.instance.currentUser : null;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: _confirmDiscardChanges,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF8),
        appBar: AppBar(
          title: const Text('Onboarding del cliente'),
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                _HeroCard(
                  title: 'Configura tu perfil comprador en SaneApp',
                  subtitle:
                      'Déjanos tu operación lista para solicitar servicios, cotizar más rápido y recibir proveedores alineados a tu necesidad.',
                  email: user?.email ?? appStateUser?.email ?? '',
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Tipo de cliente',
                  subtitle:
                      'Define si compras como empresa o como persona natural para adaptar facturación y operación.',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ChoiceCard(
                        title: 'Empresa',
                        subtitle:
                            'Operación con razón social, NIT y contacto de contratación.',
                        selected: _entityType == 'empresa',
                        onTap: () {
                          setState(() {
                            _entityType = 'empresa';
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                      _ChoiceCard(
                        title: 'Persona natural',
                        subtitle:
                            'Contratación individual con flujo simplificado.',
                        selected: _entityType == 'persona',
                        onTap: () {
                          setState(() {
                            _entityType = 'persona';
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Identidad comercial y contacto',
                  subtitle:
                      'Estos datos se usan para asignación comercial, seguimiento operativo y futuras solicitudes.',
                  child: Column(
                    children: [
                      if (_entityType == 'empresa') ...[
                        _buildTextField(
                          controller: _companyNameController,
                          label: 'Razón social o nombre comercial',
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Ingresa una razón social válida.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildTextField(
                        controller: _contactNameController,
                        label: _entityType == 'empresa'
                            ? 'Nombre del responsable de contratación'
                            : 'Nombre completo',
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return 'Ingresa un nombre válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _jobTitleController,
                        label: 'Cargo o rol interno',
                        validator: _entityType == 'empresa'
                            ? (value) => value == null || value.trim().isEmpty
                                  ? 'Indica el cargo del contacto.'
                                  : null
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Teléfono principal',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final digits = (value ?? '').replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          if (digits.length < 7) {
                            return 'Ingresa un teléfono válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Correo operativo',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _billingEmailController,
                        label: 'Correo de facturación',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      if (_entityType == 'empresa') ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _nitController,
                          label: 'NIT',
                          validator: (value) {
                            if (_entityType == 'empresa' &&
                                (value == null || value.trim().length < 5)) {
                              return 'Ingresa un NIT válido.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Ubicación y operación',
                  subtitle:
                      'Necesitamos ubicar tu operación para sugerir proveedores, cobertura y tiempos de atención.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCountry,
                        decoration: _inputDecoration('País'),
                        items: countries
                            .map(
                              (country) => DropdownMenuItem<String>(
                                value: country,
                                child: Text(country),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            _selectedDepartment = null;
                            _selectedCity = null;
                            _hasUnsavedChanges = true;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Selecciona un país.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (_selectedCountry == 'Colombia') ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDepartment,
                          decoration: _inputDecoration('Departamento'),
                          items: colombiaDepartments
                              .map(
                                (department) => DropdownMenuItem<String>(
                                  value: department,
                                  child: Text(department),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDepartment = value;
                              _selectedCity = null;
                              _hasUnsavedChanges = true;
                            });
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Selecciona un departamento.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Autocomplete<String>(
                          initialValue: TextEditingValue(
                            text: _selectedCity ?? '',
                          ),
                          optionsBuilder: (textEditingValue) {
                            final cities =
                                colombiaCitiesByDepartment[_selectedDepartment] ??
                                const <String>[];
                            if (textEditingValue.text.isEmpty) {
                              return cities;
                            }
                            return cities.where(
                              (city) => city.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                          },
                          onSelected: (selection) {
                            setState(() {
                              _selectedCity = selection;
                              _hasUnsavedChanges = true;
                            });
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onEditingComplete,
                              ) {
                                controller.value = TextEditingValue(
                                  text: _selectedCity ?? controller.text,
                                  selection: TextSelection.collapsed(
                                    offset: (_selectedCity ?? controller.text)
                                        .length,
                                  ),
                                );
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: _inputDecoration(
                                    'Ciudad o municipio',
                                  ),
                                  onChanged: (value) {
                                    _selectedCity = value.trim();
                                    _markDirty();
                                  },
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Ingresa una ciudad.'
                                      : null,
                                  onEditingComplete: onEditingComplete,
                                );
                              },
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildTextField(
                        controller: _operationAddressController,
                        label: 'Dirección operativa o punto de servicio',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Ingresa una dirección operativa.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSector,
                        decoration: _inputDecoration('Sector o industria'),
                        items: _sectorOptions
                            .map(
                              (sector) => DropdownMenuItem<String>(
                                value: sector,
                                child: Text(sector),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSector = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Selecciona un sector.'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Demanda y preferencias',
                  subtitle:
                      'Esto mejora el matching con proveedores y acelera tus futuras solicitudes.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Servicios de interés',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interestOptions
                            .map(
                              (option) => FilterChip(
                                label: Text(option),
                                selected: _selectedInterests.contains(option),
                                selectedColor: const Color(0xFFD8F0E0),
                                checkmarkColor: _brandGreen,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedInterests.add(option);
                                    } else {
                                      _selectedInterests.remove(option);
                                    }
                                    _hasUnsavedChanges = true;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFrequency,
                        decoration: _inputDecoration(
                          'Frecuencia de contratación',
                        ),
                        items: _frequencyOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFrequency = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUrgency,
                        decoration: _inputDecoration(
                          'Nivel de urgencia habitual',
                        ),
                        items: _urgencyOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUrgency = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notas de operación o requerimientos especiales',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _surfaceTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8E9DD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cumplimiento y confianza',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _openLegalDialog,
                        child: const Text(
                          'Revisar términos y condiciones y política de privacidad',
                          style: TextStyle(
                            color: _brandGreenSoft,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        value: _acceptedTerms,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Acepto el tratamiento de datos y las condiciones de contratación de SaneApp.',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                            _termsError = null;
                            _hasUnsavedChanges = true;
                          });
                        },
                      ),
                      if (_termsError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _termsError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text(
              _saving
                  ? 'Guardando perfil...'
                  : _hasUnsavedChanges
                  ? 'Activar perfil cliente'
                  : 'Perfil listo para activar',
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD2E4D6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD2E4D6)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un correo válido.';
    }
    final emailRegExp = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Correo inválido.';
    }
    return null;
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String email;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C4F31), Color(0xFF1E7A4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.apartment_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 16),
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
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              email,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
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
        border: Border.all(color: const Color(0xFFDCE8DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? const Color(0xFFE7F4EB) : const Color(0xFFF7FAF8),
          border: Border.all(
            color: selected ? const Color(0xFF1E7A4B) : const Color(0xFFD8E5DB),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              title == 'Empresa'
                  ? Icons.business_rounded
                  : Icons.person_outline,
              color: const Color(0xFF0C4F31),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
