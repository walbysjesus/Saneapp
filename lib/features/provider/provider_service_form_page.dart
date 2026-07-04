import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/image_upload_service.dart';
import 'models/provider_service_listing.dart';
import 'provider_profile_status.dart';
import 'provider_publication_matrix.dart';

class ProviderServiceFormPage extends StatefulWidget {
  const ProviderServiceFormPage({super.key});

  @override
  State<ProviderServiceFormPage> createState() =>
      _ProviderServiceFormPageState();
}

class _ProviderServiceFormPageState extends State<ProviderServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _technicalDescriptionController = TextEditingController();
  final _coverageController = TextEditingController();
  final _priceFromController = TextEditingController();
  final _responseTimeController = TextEditingController();
  final _industriesController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _deliverablesController = TextEditingController();

  final _profileStatusService = const ProviderProfileStatusService();
  final Map<String, TextEditingController> _dynamicControllers =
      <String, TextEditingController>{};
  final Map<String, dynamic> _dynamicValues = <String, dynamic>{};

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _categories = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _subcategories = [];
  int _currentStep = 0;
  bool _didLoadRouteArgs = false;
  String? _editingServiceId;
  String? _selectedServiceLineId;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String _serviceMode = 'Puntual';
  String _priceType = 'Precio desde';
  String? _commercialImageUrl;
  bool _emergencyAvailability = false;
  bool _requiresLicense = false;
  bool _loadingCatalog = true;
  bool _saving = false;

  MarketplacePublicationTemplate get _template {
    return mergeMarketplacePublicationTemplates(
      base: resolveMarketplacePublicationTemplate(
        serviceLineId: _selectedServiceLineId,
        categoryName: _selectedCategoryName,
        subcategoryName: _selectedSubcategoryName,
      ),
      extra: resolveMarketplacePriceTemplate(_priceType),
    );
  }

  bool get _isEditing => _editingServiceId != null && _editingServiceId!.isNotEmpty;

  MarketplaceServiceLine? get _selectedServiceLine {
    return findMarketplaceServiceLine(_selectedServiceLineId);
  }

  String get _selectedCategoryName {
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) {
        return (category.data()['name'] as String?) ?? category.id;
      }
    }
    return '';
  }

  String get _selectedSubcategoryName {
    for (final subcategory in _subcategories) {
      if (subcategory.id == _selectedSubcategoryId) {
        return (subcategory.data()['name'] as String?) ?? subcategory.id;
      }
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _technicalDescriptionController.dispose();
    _coverageController.dispose();
    _priceFromController.dispose();
    _responseTimeController.dispose();
    _industriesController.dispose();
    _requirementsController.dispose();
    _deliverablesController.dispose();
    for (final controller in _dynamicControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    if (!mounted) {
      return;
    }
    setState(() {
      _categories = snapshot.docs;
      _loadingCatalog = false;
    });
  }

  Future<void> _loadSubcategories(String categoryId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .doc(categoryId)
        .collection('subcategories')
        .get();
    if (!mounted) {
      return;
    }
    setState(() {
      _subcategories = snapshot.docs;
      _selectedSubcategoryId = null;
    });
    _syncDynamicFields();
  }

  void _syncDynamicFields() {
    final nextKeys = _template.fields.map((field) => field.key).toSet();
    final staleKeys = _dynamicControllers.keys
        .where((key) => !nextKeys.contains(key))
        .toList();

    for (final key in staleKeys) {
      _dynamicControllers.remove(key)?.dispose();
      _dynamicValues.remove(key);
    }

    for (final field in _template.fields) {
      if (field.kind == MarketplaceFieldKind.text ||
          field.kind == MarketplaceFieldKind.multiline ||
          field.kind == MarketplaceFieldKind.number) {
        _dynamicControllers.putIfAbsent(
          field.key,
          () => TextEditingController(
            text: _dynamicValues[field.key]?.toString() ?? '',
          ),
        );
      } else if (!_dynamicValues.containsKey(field.key)) {
        _dynamicValues[field.key] = field.kind == MarketplaceFieldKind.boolean
            ? false
            : (field.options.isNotEmpty ? field.options.first : null);
      }
    }

    if (mounted) {
      setState(() {});
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
    final serviceId = args['serviceId']?.toString();
    if (serviceId == null || serviceId.isEmpty) {
      return;
    }
    _loadExistingService(serviceId);
  }

  Future<void> _loadExistingService(String serviceId) async {
    setState(() => _loadingCatalog = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('provider_services')
          .doc(serviceId)
          .get();
      final data = snapshot.data();
      if (data == null) {
        return;
      }

      _editingServiceId = snapshot.id;
      _selectedServiceLineId = data['serviceLineId']?.toString().isNotEmpty == true
          ? data['serviceLineId']?.toString()
          : 'environmental_services';
      _selectedCategoryId = data['categoryId']?.toString();
      _priceType = data['priceType']?.toString().isNotEmpty == true
          ? data['priceType'].toString()
          : 'Precio fijo por servicio';
      _serviceMode = data['serviceMode']?.toString().isNotEmpty == true
          ? data['serviceMode'].toString()
          : 'Puntual';
      _commercialImageUrl = data['commercialImageUrl']?.toString();
      _emergencyAvailability = data['emergencyAvailability'] == true;
      _requiresLicense = data['requiresLicense'] == true;

      _titleController.text = data['title']?.toString() ?? '';
      _shortDescriptionController.text = data['shortDescription']?.toString() ?? '';
      _technicalDescriptionController.text = data['technicalDescription']?.toString() ?? '';
      _coverageController.text = data['coverage']?.toString() ?? '';
      _priceFromController.text = (data['priceFrom'] as num?)?.toString() ?? '';
      _responseTimeController.text = data['responseTime']?.toString() ?? '';
      _industriesController.text = data['industries']?.toString() ?? '';
      _requirementsController.text = data['requirements']?.toString() ?? '';
      _deliverablesController.text = data['deliverables']?.toString() ?? '';

      final dynamicAttributes =
          (data['dynamicAttributes'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      _dynamicValues
        ..clear()
        ..addAll(dynamicAttributes);

      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        final subcategorySnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .doc(_selectedCategoryId)
            .collection('subcategories')
            .get();
        _subcategories = subcategorySnapshot.docs;
      }
      _selectedSubcategoryId = data['subcategoryId']?.toString();
      _syncDynamicFields();
      for (final entry in dynamicAttributes.entries) {
        if (_dynamicControllers.containsKey(entry.key)) {
          _dynamicControllers[entry.key]!.text = entry.value?.toString() ?? '';
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCatalog = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateStep(int stepIndex) {
    if (stepIndex == 0) {
      if (_selectedServiceLineId == null) {
        _showMessage('Selecciona primero que tipo de servicio quieres publicar.');
        return false;
      }
      return true;
    }

    if (stepIndex == 1) {
      if (_selectedCategoryId == null || _selectedSubcategoryId == null) {
        _showMessage('Selecciona categoria y subcategoria antes de continuar.');
        return false;
      }
      return true;
    }

    if (stepIndex == 2) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        return false;
      }
      for (final field in _template.fields) {
        dynamic value;
        if (field.kind == MarketplaceFieldKind.text ||
            field.kind == MarketplaceFieldKind.multiline ||
            field.kind == MarketplaceFieldKind.number) {
          value = _dynamicControllers[field.key]?.text.trim() ?? '';
        } else {
          value = _dynamicValues[field.key];
        }
        if (!field.isRequired) {
          continue;
        }
        if (value == null) {
          _showMessage('Completa el campo ${field.label}.');
          return false;
        }
        if (value is String && value.trim().isEmpty) {
          _showMessage('Completa el campo ${field.label}.');
          return false;
        }
      }
    }

    return true;
  }

  void _continueStepper() {
    if (!_validateStep(_currentStep)) {
      return;
    }
    if (_currentStep == 3) {
      _saveService();
      return;
    }
    setState(() => _currentStep += 1);
  }

  void _cancelStepper() {
    if (_currentStep == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _currentStep -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Publicar servicio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Puedes explorar la marketplace sin credenciales, pero para vender debes registrarte como proveedor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SaneApp solo pide cuenta cuando realmente vas a publicar, vender o activar una compra.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/register',
                      arguments: const {'marketplaceIntent': 'sell'},
                    ),
                    child: const Text('Registrarme para vender'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<ProviderProfileStatus>(
      future: _profileStatusService.loadCurrentUserStatus(),
      builder: (context, snapshot) {
        final profileStatus = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (profileStatus == null || !profileStatus.canOperate) {
          return Scaffold(
            appBar: AppBar(title: const Text('Publicar servicio')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'Completa tu registro de proveedor antes de publicar servicios',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profileStatus?.detail ??
                            'Tu perfil aun no esta habilitado para publicar servicios.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          '/provider-profile-setup',
                        ),
                        child: const Text('Completar registro'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing ? 'Editar publicacion' : 'Iniciar nueva publicacion',
            ),
          ),
          body: _loadingCatalog
              ? const Center(child: CircularProgressIndicator())
              : Stepper(
                  currentStep: _currentStep,
                  onStepContinue: _saving ? null : _continueStepper,
                  onStepCancel: _saving ? null : _cancelStepper,
                  onStepTapped: (nextStep) {
                    if (nextStep <= _currentStep) {
                      setState(() => _currentStep = nextStep);
                      return;
                    }
                    for (var stepIndex = 0; stepIndex < nextStep; stepIndex += 1) {
                      if (!_validateStep(stepIndex)) {
                        return;
                      }
                    }
                    setState(() => _currentStep = nextStep);
                  },
                  controlsBuilder: (context, details) {
                    final isReviewStep = _currentStep == 3;
                    return Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _saving ? null : details.onStepContinue,
                            icon: _saving && isReviewStep
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(isReviewStep ? Icons.publish : Icons.arrow_forward),
                            label: Text(
                              isReviewStep
                                    ? (_saving
                                      ? (_isEditing ? 'Guardando...' : 'Publicando...')
                                      : (_isEditing ? 'Guardar cambios' : 'Publicar servicio'))
                                  : 'Continuar',
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _saving ? null : details.onStepCancel,
                            child: Text(_currentStep == 0 ? 'Cancelar' : 'Atras'),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Que quieres publicar'),
                      subtitle: const Text('Linea de servicio y enfoque comercial'),
                      isActive: _currentStep >= 0,
                      state: _selectedServiceLineId == null
                          ? StepState.indexed
                          : StepState.complete,
                      content: _buildServiceLineStep(),
                    ),
                    Step(
                      title: const Text('Categoria y subcategoria'),
                      subtitle: const Text('Define el mercado donde competir'),
                      isActive: _currentStep >= 1,
                      state: _selectedCategoryId != null && _selectedSubcategoryId != null
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildCategoryStep(),
                    ),
                    Step(
                      title: const Text('Ficha comercial y tecnica'),
                      subtitle: const Text('Precio desde, detalle y atributos dinamicos'),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                      content: _buildDetailsStep(user.uid),
                    ),
                    Step(
                      title: const Text('Revision y publicacion'),
                      subtitle: Text(
                        _isEditing
                            ? 'Confirma como quedara actualizada la publicacion'
                            : 'Confirma como se vera en la marketplace',
                      ),
                      isActive: _currentStep >= 3,
                      content: _buildReviewStep(),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildServiceLineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Arranca como una marketplace ambiental: primero eliges que linea de servicio vas a vender.',
          style: TextStyle(color: Color(0xFF5F6D66), height: 1.4),
        ),
        const SizedBox(height: 14),
        ...marketplaceServiceLines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ServiceLineChoiceCard(
              line: line,
              selected: _selectedServiceLineId == line.id,
              onTap: () {
                setState(() {
                  _selectedServiceLineId = line.id;
                });
                _syncDynamicFields();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Luego bajas a categoria y subcategoria para que SaneApp te pida los atributos correctos del servicio.',
          style: TextStyle(color: Color(0xFF5F6D66), height: 1.4),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: _categories
              .map(
                (doc) => DropdownMenuItem(
                  value: doc.id,
                  child: Text((doc.data()['name'] as String?) ?? doc.id),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _selectedCategoryId = value;
            });
            _loadSubcategories(value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedSubcategoryId,
          decoration: const InputDecoration(labelText: 'Subcategoria'),
          items: _subcategories
              .map(
                (doc) => DropdownMenuItem(
                  value: doc.id,
                  child: Text((doc.data()['name'] as String?) ?? doc.id),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedSubcategoryId = value);
            _syncDynamicFields();
          },
        ),
        if (_selectedSubcategoryId != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD5E6D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _template.title,
                  style: const TextStyle(
                    color: Color(0xFF0C4F31),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _template.description,
                  style: const TextStyle(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsStep(String userId) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Oferta comercial',
            subtitle:
                'Define con claridad que servicio prestas y por que tu operacion genera confianza.',
          ),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titulo comercial del servicio'),
            validator: (value) => value == null || value.trim().length < 8
                ? 'Ingresa un titulo mas claro.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shortDescriptionController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripcion corta'),
            validator: (value) => value == null || value.trim().length < 30
                ? 'Describe el valor del servicio en al menos 30 caracteres.'
                : null,
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            title: 'Imagen comercial',
            subtitle:
                'Sube una imagen representativa para que el generador la vea en el marketplace.',
          ),
          _OfferImageCard(
            imageUrl: _commercialImageUrl,
            onUpload: _saving
                ? null
                : () async {
                    final uploadedUrl =
                        await ImageUploadService.pickAndUploadImage(userId);
                    if (!mounted || uploadedUrl == null) {
                      return;
                    }
                    setState(() {
                      _commercialImageUrl = uploadedUrl;
                    });
                  },
            onRemove: _commercialImageUrl == null || _saving
                ? null
                : () {
                    setState(() {
                      _commercialImageUrl = null;
                    });
                  },
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Alcance tecnico',
            subtitle:
                'Especifica cobertura, modalidad, tiempos de respuesta y condiciones de ejecucion.',
          ),
          TextFormField(
            controller: _technicalDescriptionController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Descripcion tecnica'),
            validator: (value) => value == null || value.trim().length < 80
                ? 'Describe el alcance tecnico con mayor detalle.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _coverageController,
            decoration: const InputDecoration(labelText: 'Cobertura geografica'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Indica la cobertura geografica.'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _serviceMode,
            decoration: const InputDecoration(labelText: 'Modalidad'),
            items: const [
              DropdownMenuItem(value: 'Puntual', child: Text('Puntual')),
              DropdownMenuItem(value: 'Recurrente', child: Text('Recurrente')),
              DropdownMenuItem(
                value: 'Emergencia 24/7',
                child: Text('Emergencia 24/7'),
              ),
            ],
            onChanged: (value) => setState(() => _serviceMode = value ?? 'Puntual'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _responseTimeController,
            decoration: const InputDecoration(labelText: 'Tiempo de respuesta'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Indica el tiempo de respuesta.'
                : null,
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Condiciones comerciales',
            subtitle:
                'Publica una referencia economica y los entregables clave de tu servicio.',
          ),
          DropdownButtonFormField<String>(
            initialValue: _priceType,
            decoration: const InputDecoration(labelText: 'Tipo de precio'),
            items: const [
              DropdownMenuItem(
                value: 'Precio fijo por servicio',
                child: Text('Precio fijo por servicio'),
              ),
              DropdownMenuItem(value: 'Por horas', child: Text('Por horas')),
              DropdownMenuItem(
                value: 'Por metro cubico',
                child: Text('Por metro cubico'),
              ),
              DropdownMenuItem(
                value: 'Por tonelada',
                child: Text('Por tonelada'),
              ),
              DropdownMenuItem(
                value: 'Por metro lineal',
                child: Text('Por metro lineal'),
              ),
              DropdownMenuItem(value: 'Por viaje', child: Text('Por viaje')),
              DropdownMenuItem(value: 'Por flete', child: Text('Por flete')),
              DropdownMenuItem(
                value: 'Cotizacion personalizada',
                child: Text('Cotizacion personalizada'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _priceType = value ?? 'Precio fijo por servicio';
              });
              _syncDynamicFields();
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceFromController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Precio desde'),
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Ingresa un valor base valido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _industriesController,
            decoration: const InputDecoration(labelText: 'Industrias atendidas'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Indica sectores o industrias atendidas.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _requirementsController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Requisitos del cliente'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _deliverablesController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Entregables y evidencias'),
          ),
          const SizedBox(height: 20),
          _DynamicTemplatePanel(template: _template),
          const SizedBox(height: 12),
          ..._buildDynamicFieldInputs(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Disponible para emergencias'),
            value: _emergencyAvailability,
            onChanged: (value) => setState(() => _emergencyAvailability = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Requiere licencia o soporte regulatorio'),
            value: _requiresLicense,
            onChanged: (value) => setState(() => _requiresLicense = value),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFieldInputs() {
    return _template.fields.map((field) {
      Widget input;
      switch (field.kind) {
        case MarketplaceFieldKind.multiline:
          input = TextFormField(
            controller: _dynamicControllers[field.key],
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
            ),
          );
          break;
        case MarketplaceFieldKind.number:
          input = TextFormField(
            controller: _dynamicControllers[field.key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
            ),
          );
          break;
        case MarketplaceFieldKind.choice:
          input = DropdownButtonFormField<String>(
            initialValue: _dynamicValues[field.key] as String?,
            decoration: InputDecoration(
              labelText: field.label,
              helperText: field.hint,
            ),
            items: field.options
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _dynamicValues[field.key] = value),
          );
          break;
        case MarketplaceFieldKind.boolean:
          input = SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(field.label),
            subtitle: Text(field.hint),
            value: (_dynamicValues[field.key] as bool?) ?? false,
            onChanged: (value) => setState(() => _dynamicValues[field.key] = value),
          );
          break;
        case MarketplaceFieldKind.text:
          input = TextFormField(
            controller: _dynamicControllers[field.key],
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
            ),
          );
          break;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: input,
      );
    }).toList();
  }

  Widget _buildReviewStep() {
    final dynamicSummary = _collectDynamicAttributes();
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ReviewCard(
          title: 'Linea y posicionamiento',
          entries: [
            _ReviewEntry('Linea', _selectedServiceLine?.label ?? 'Sin definir'),
            _ReviewEntry('Categoria', _selectedCategoryName),
            _ReviewEntry('Subcategoria', _selectedSubcategoryName),
            _ReviewEntry('Tipo de precio', _priceType),
            _ReviewEntry('Precio desde', _priceFromController.text.trim()),
            _ReviewEntry('Modo', _isEditing ? 'Edicion de publicacion' : 'Nueva publicacion'),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: 'Ficha visible para el marketplace',
          entries: [
            _ReviewEntry('Titulo', _titleController.text.trim()),
            _ReviewEntry('Descripcion corta', _shortDescriptionController.text.trim()),
            _ReviewEntry('Cobertura', _coverageController.text.trim()),
            _ReviewEntry('Tiempo de respuesta', _responseTimeController.text.trim()),
            _ReviewEntry('Modalidad', _serviceMode),
          ],
        ),
        if (dynamicSummary.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ReviewCard(title: 'Atributos tecnicos por servicio', entries: dynamicSummary),
        ],
      ],
    );
  }

  List<_ReviewEntry> _collectDynamicAttributes() {
    final entries = <_ReviewEntry>[];
    for (final field in _template.fields) {
      dynamic value;
      if (field.kind == MarketplaceFieldKind.text ||
          field.kind == MarketplaceFieldKind.multiline ||
          field.kind == MarketplaceFieldKind.number) {
        value = _dynamicControllers[field.key]?.text.trim() ?? '';
      } else {
        value = _dynamicValues[field.key];
      }
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      entries.add(
        _ReviewEntry(
          field.label,
          value is bool ? (value ? 'Si' : 'No') : value.toString(),
        ),
      );
    }
    return entries;
  }

  Map<String, dynamic> _buildDynamicAttributesPayload() {
    final payload = <String, dynamic>{};
    for (final field in _template.fields) {
      if (field.kind == MarketplaceFieldKind.text ||
          field.kind == MarketplaceFieldKind.multiline ||
          field.kind == MarketplaceFieldKind.number) {
        final value = _dynamicControllers[field.key]?.text.trim() ?? '';
        if (value.isNotEmpty) {
          payload[field.key] = value;
        }
      } else {
        final value = _dynamicValues[field.key];
        if (value != null) {
          payload[field.key] = value;
        }
      }
    }
    return payload;
  }

  Future<void> _saveService() async {
    if (!(_validateStep(0) && _validateStep(1) && _validateStep(2))) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedCategoryId == null || _selectedSubcategoryId == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final category = _categories.firstWhere((doc) => doc.id == _selectedCategoryId);
      final subcategory = _subcategories.firstWhere((doc) => doc.id == _selectedSubcategoryId);
      final providerSnapshot = await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .get();
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final providerData = providerSnapshot.data() ?? <String, dynamic>{};
      final userData = userSnapshot.data() ?? <String, dynamic>{};
      final providerName =
          (providerData['companyName'] as String?)?.trim().isNotEmpty == true
              ? (providerData['companyName'] as String).trim()
              : ((userData['fullName'] as String?)?.trim() ?? 'Proveedor');
      final providerLocation =
          (providerData['operationAddress'] as String?)?.trim() ?? '';
      final providerLogoUrl = (providerData['logoUrl'] as String?) ??
          (userData['photoUrl'] as String?) ??
          '';

      final service = ProviderServiceListing(
        id: _editingServiceId ?? '',
        providerId: user.uid,
        providerName: providerName,
        providerLocation: providerLocation,
        providerLogoUrl: providerLogoUrl,
        commercialImageUrl: _commercialImageUrl ?? '',
        commercialVideoUrl: '',
        serviceLineId: _selectedServiceLine?.id ?? 'environmental_services',
        serviceLineLabel: _selectedServiceLine?.label ?? 'Servicios ambientales',
        categoryId: category.id,
        categoryName: (category.data()['name'] as String?) ?? category.id,
        subcategoryId: subcategory.id,
        subcategoryName: (subcategory.data()['name'] as String?) ?? subcategory.id,
        title: _titleController.text.trim(),
        shortDescription: _shortDescriptionController.text.trim(),
        technicalDescription: _technicalDescriptionController.text.trim(),
        coverage: _coverageController.text.trim(),
        serviceMode: _serviceMode,
        priceType: _priceType,
        priceFrom: double.parse(_priceFromController.text.trim()),
        responseTime: _responseTimeController.text.trim(),
        industries: _industriesController.text.trim(),
        requirements: _requirementsController.text.trim(),
        deliverables: _deliverablesController.text.trim(),
        dynamicAttributes: _buildDynamicAttributesPayload(),
        emergencyAvailability: _emergencyAvailability,
        requiresLicense: _requiresLicense,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final collection = FirebaseFirestore.instance.collection('provider_services');
      if (_isEditing) {
        await collection.doc(_editingServiceId).set(service.toMap(), SetOptions(merge: true));
      } else {
        await collection.add(service.toMap());
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Servicio actualizado correctamente.'
                : 'Servicio publicado correctamente.',
          ),
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ServiceLineChoiceCard extends StatelessWidget {
  final MarketplaceServiceLine line;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceLineChoiceCard({
    required this.line,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF8F2) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF0C4F31) : const Color(0xFFDCE7DF),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFD9EEDD) : const Color(0xFFEAF3ED),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(line.icon, color: const Color(0xFF1E7A4B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          line.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: Color(0xFF0C4F31)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF0C4F31),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    line.description,
                    style: const TextStyle(color: Color(0xFF63736C), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicTemplatePanel extends StatelessWidget {
  final MarketplacePublicationTemplate template;

  const _DynamicTemplatePanel({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E6D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template.title,
            style: const TextStyle(
              color: Color(0xFF0C4F31),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(template.description, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class _ReviewEntry {
  final String label;
  final String value;

  const _ReviewEntry(this.label, this.value);
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final List<_ReviewEntry> entries;

  const _ReviewCard({required this.title, required this.entries});

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
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 126,
                    child: Text(
                      entry.label,
                      style: const TextStyle(
                        color: Color(0xFF63736C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: Text(entry.value.isEmpty ? 'Sin definir' : entry.value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _OfferImageCard extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onUpload;
  final VoidCallback? onRemove;

  const _OfferImageCard({
    required this.imageUrl,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFF3F6F4),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 42,
                          color: Color(0xFF2B8A57),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aun no has subido imagen comercial',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    imageUrl != null && imageUrl!.isNotEmpty
                        ? 'Actualizar imagen'
                        : 'Subir imagen',
                  ),
                ),
              ),
              if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Eliminar imagen',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}