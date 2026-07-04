import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/image_upload_service.dart';
import '../../core/widgets/role_guard.dart';
import '../shared/request_image_gallery.dart';
import '../../models/user_model.dart';
import '../../state/app_state.dart';

class CrearSubastaPage extends StatefulWidget {
  const CrearSubastaPage({super.key});

  @override
  State<CrearSubastaPage> createState() => _CrearSubastaPageState();
}

class _CrearSubastaPageState extends State<CrearSubastaPage> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _budgetController = TextEditingController();
  final _minRequirementsController = TextEditingController();

  bool _loadingProfile = true;
  bool _saving = false;
  bool _clientProfileCompleted = false;
  bool _didLoadRouteArgs = false;
  DateTime? _deadline;
  String? _selectedServiceInterest;
  final List<String> _serviceInterests = [];
  final List<String> _requestImageUrls = [];
  UserModel? _currentUser;
  String? _requestSource;

  static const _commercialFlowMode = 'auction';

  String get _commercialFlowDescription =>
      'La subasta entra al mismo flujo comercial de SaneApp, pero abre competencia controlada entre proveedores con fecha límite y criterios comparables.';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _budgetController.dispose();
    _minRequirementsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final fallbackUser = appState.currentUser;
    _currentUser = fallbackUser;

    if (Firebase.apps.isEmpty) {
      _applyFallback(fallbackUser);
      return;
    }

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      _applyFallback(fallbackUser);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      _currentUser = UserModel.fromMap({
        'uid': authUser.uid,
        'email': authUser.email ?? fallbackUser?.email ?? '',
        'fullName': data['fullName'] ?? fallbackUser?.fullName,
        'companyName': data['companyName'] ?? fallbackUser?.companyName,
        'role': data['role'] ?? fallbackUser?.role,
        'city': data['city'] ?? fallbackUser?.city,
        'entityType': data['entityType'] ?? fallbackUser?.entityType,
        'clientType': data['clientType'] ?? fallbackUser?.clientType,
        'status': data['status'] ?? fallbackUser?.status,
        'clientProfileCompleted':
            data['clientProfileCompleted'] ??
            fallbackUser?.clientProfileCompleted,
      });
      _clientProfileCompleted = data['clientProfileCompleted'] == true;
      _cityController.text =
          (data['city'] as String?) ?? fallbackUser?.city ?? '';
      _serviceInterests
        ..clear()
        ..addAll(
          (data['serviceInterests'] as List?)?.cast<String>() ?? const [],
        );
      _selectedServiceInterest = _serviceInterests.isNotEmpty
          ? _serviceInterests.first
          : null;
      if (_selectedServiceInterest != null) {
        _titleController.text = 'Subasta de ${_selectedServiceInterest!}';
      }
    } catch (_) {
      _applyFallback(fallbackUser);
    }
  }

  void _applyFallback(UserModel? user) {
    _clientProfileCompleted = user?.clientProfileCompleted == true;
    _cityController.text = user?.city ?? '';
    if (mounted) {
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadRouteArgs) {
      return;
    }
    _didLoadRouteArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) {
      return;
    }

    final requestedService = args['serviceInterest'] as String?;
    final requestedTitle = args['requestTitle'] as String?;
    final requestedDescription = args['requestDescription'] as String?;
    final requestedCity = args['city'] as String?;
    final requestedBudget = args['budgetReference'];
    final requestedRequirements = args['minimumRequirements'] as String?;
    final requestedSource = args['requestSource'] as String?;

    if (requestedService != null && requestedService.trim().isNotEmpty) {
      _selectedServiceInterest = requestedService.trim();
      if (!_serviceInterests.contains(_selectedServiceInterest)) {
        _serviceInterests.add(_selectedServiceInterest!);
      }
    }
    if (requestedTitle != null && requestedTitle.trim().isNotEmpty) {
      _titleController.text = requestedTitle.trim();
    }
    if (requestedDescription != null &&
        requestedDescription.trim().isNotEmpty) {
      _descriptionController.text = requestedDescription.trim();
    }
    if (requestedCity != null && requestedCity.trim().isNotEmpty) {
      _cityController.text = requestedCity.trim();
    }
    if (requestedBudget != null && _budgetController.text.trim().isEmpty) {
      _budgetController.text = requestedBudget.toString();
    }
    if (requestedRequirements != null &&
        requestedRequirements.trim().isNotEmpty) {
      _minRequirementsController.text = requestedRequirements.trim();
    }
    if (requestedSource != null && requestedSource.trim().isNotEmpty) {
      _requestSource = requestedSource.trim();
    }
  }

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (pickedTime == null) {
      return;
    }
    setState(() {
      _deadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _addRequestImage() async {
    final authUser = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final userId = authUser?.uid ?? _currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final imageUrl = await ImageUploadService.pickAndUploadImageToFolder(
      'auction_images/$userId',
    );
    if (!mounted || imageUrl == null) {
      return;
    }

    setState(() {
      _requestImageUrls.add(imageUrl);
    });
  }

  Future<void> _submit() async {
    if (!_clientProfileCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa tu perfil cliente antes de crear subastas.'),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false) || _deadline == null) {
      return;
    }

    final authUser = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final uid = authUser?.uid ?? _currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('solicitudes').add({
        'titulo': _titleController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
        'status': 'activa',
        'type': 'subasta',
        'serviceInterest': _selectedServiceInterest,
        'city': _cityController.text.trim(),
        'budgetReference':
            double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 0,
        'minimumRequirements': _minRequirementsController.text.trim(),
        'requestImageUrls': _requestImageUrls,
        'requestSource': _requestSource,
        'commercialFlowMode': _commercialFlowMode,
        'commercialFlowLabel': 'Subasta de proveedores',
        'commercialEntryPoint': 'buyer_marketplace',
        'commercialDossierVersion': 'unified_v1',
        'commercialFlowStage': 'auction_open',
        'commercialFlowUpdatedAt': FieldValue.serverTimestamp(),
        'deadline': Timestamp.fromDate(_deadline!),
        'generadorId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subasta creada correctamente.')),
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
    return RoleGuard(
      requiredRole: UserRole.generador,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAF7),
        appBar: AppBar(
          title: const Text('Crear subasta'),
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
        ),
        body: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    const _AuctionHero(),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Expediente comercial',
                      subtitle:
                          'La subasta comparte trazabilidad con el resto del marketplace para que SaneApp consolide comparación, adjudicación y cierre en un mismo negocio.',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD5E6D8)),
                        ),
                        child: Text(
                          _commercialFlowDescription,
                          style: const TextStyle(height: 1.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Contexto de la subasta',
                      subtitle:
                          'Abre competencia controlada entre proveedores para acelerar precio y tiempo de respuesta.',
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedServiceInterest,
                            decoration: _decoration('Servicio principal'),
                            items: _serviceInterests
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: _serviceInterests.isEmpty
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedServiceInterest = value;
                                      if (value != null &&
                                          _titleController.text
                                              .trim()
                                              .isEmpty) {
                                        _titleController.text =
                                            'Subasta de $value';
                                      }
                                    });
                                  },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Selecciona un servicio.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleController,
                            decoration: _decoration('Título de la subasta'),
                            validator: (value) =>
                                value == null || value.trim().length < 5
                                ? 'Ingresa un título más claro.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 4,
                            maxLines: 6,
                            decoration: _decoration(
                              'Describe alcance, entregables, operación y reglas de adjudicación',
                            ),
                            validator: (value) =>
                                value == null || value.trim().length < 20
                                ? 'Describe mejor la subasta.'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Imágenes de referencia',
                      subtitle:
                          'Adjunta fotos del alcance, sitio o contexto operativo para que los proveedores dimensionen mejor la subasta.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RequestImageGallery(
                            imageUrls: _requestImageUrls,
                            title: 'Adjuntos cargados',
                          ),
                          if (_requestImageUrls.isNotEmpty)
                            const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saving ? null : _addRequestImage,
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                                label: const Text('Agregar imagen'),
                              ),
                              if (_requestImageUrls.isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () {
                                          setState(() {
                                            _requestImageUrls.removeLast();
                                          });
                                        },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Quitar última'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Condiciones comerciales',
                      subtitle:
                          'Define ciudad, referencia de presupuesto y requerimientos mínimos para comparar mejor.',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _cityController,
                            decoration: _decoration('Ciudad'),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa la ciudad.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _budgetController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _decoration(
                              'Presupuesto de referencia (COP)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _minRequirementsController,
                            minLines: 3,
                            maxLines: 4,
                            decoration: _decoration(
                              'Requisitos mínimos para participar',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFD6E3DA)),
                            ),
                            title: const Text('Cierre de la subasta'),
                            subtitle: Text(
                              _deadline == null
                                  ? 'Selecciona fecha y hora límite'
                                  : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year} ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}',
                            ),
                            trailing: const Icon(Icons.calendar_today_outlined),
                            onTap: _pickDeadline,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
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
                : const Icon(Icons.gavel_outlined),
            label: Text(_saving ? 'Publicando subasta...' : 'Publicar subasta'),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6E3DA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6E3DA)),
      ),
    );
  }
}

class _AuctionHero extends StatelessWidget {
  const _AuctionHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            _CrearSubastaPageState._brandGreen,
            _CrearSubastaPageState._brandGreenSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subasta operativa para conseguir mejores condiciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Usa subasta cuando quieras comparar múltiples propuestas bajo una fecha límite, reglas claras y un marco comercial consistente.',
            style: TextStyle(color: Colors.white70, height: 1.35),
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
        border: Border.all(color: const Color(0xFFDCE7DF)),
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
