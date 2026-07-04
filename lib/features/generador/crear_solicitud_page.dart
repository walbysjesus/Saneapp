import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/image_upload_service.dart';
import '../../services/commercial_timeline_service.dart';
import '../../core/widgets/role_guard.dart';
import '../shared/request_image_gallery.dart';
import '../supervision/supervision_artifacts.dart';
import '../../models/user_model.dart';
import '../../state/app_state.dart';

class CrearSolicitudPage extends StatefulWidget {
  const CrearSolicitudPage({super.key});

  @override
  State<CrearSolicitudPage> createState() => _CrearSolicitudPageState();
}

class _CrearSolicitudPageState extends State<CrearSolicitudPage> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _alertColor = Color(0xFFC24E00);
  static const _surface = Color(0xFFF6FAF7);
  static const _urgencyOptions = <String>[
    'Programado',
    'En menos de 72 horas',
    'Urgente 24/7',
  ];
  static const _frequencyOptions = <String>[
    'Puntual',
    'Mensual',
    'Semanal',
    'Contrato permanente',
  ];
  static const _subcategoryPlaceholder = 'Sin subcategoría definida';

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _estimatedValueController = TextEditingController();
  final _notesController = TextEditingController();

  bool _profileLoading = true;
  bool _saving = false;
  bool _clientProfileCompleted = false;
  bool _supervisorRequested = false;
  String? _supervisorType = 'ninguno';
  double _supervisorCost = 0;
  String? _selectedServiceInterest;
  String? _selectedUrgency;
  String? _selectedFrequency;
  final List<String> _serviceInterests = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _categoryCatalog = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _subcategoryCatalog = [];
  UserModel? _currentUser;
  String? _contactName;
  String? _contactPhone;
  String? _billingEmail;
  bool _didLoadRouteArgs = false;
  String _requestMode = 'normal';
  String _requestIntent = 'open_marketplace';
  String? _requestSource;
  String? _preferredProviderId;
  String? _preferredProviderName;
  String? _preferredProviderServiceId;
  String? _preferredProviderServiceTitle;
  String? _preferredProviderServicePriceType;
  String? _selectedSubcategoryId;
  String? _selectedSubcategoryName;
  final List<String> _requestImageUrls = [];

  String get _commercialFlowMode {
    if (_supervisorRequested && _isPrequoteDiagnostic) {
      return 'assisted_quote';
    }
    if (_requestIntent == 'direct_service_request') {
      return 'direct_request';
    }
    if (_requestIntent == 'direct_quote_request') {
      return 'provider_quote';
    }
    return 'direct_request';
  }

  String get _commercialFlowLabel {
    switch (_commercialFlowMode) {
      case 'assisted_quote':
        return 'Cotización asistida';
      case 'provider_quote':
        return 'Cotización dirigida';
      default:
        return 'Solicitud directa';
    }
  }

  String get _commercialFlowDescription {
    switch (_commercialFlowMode) {
      case 'assisted_quote':
        return 'SaneApp acompaña el diagnóstico previo para reducir incertidumbre técnica antes de pedir propuesta económica.';
      case 'provider_quote':
        return 'El negocio se dirigirá a un proveedor o servicio publicado para recibir propuesta comercial dentro del expediente.';
      default:
        return 'La necesidad entra al marketplace para activar respuesta comercial o contratación directa dentro de SaneApp.';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategoryCatalog();
    _loadClientProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _estimatedValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClientProfile() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final fallbackUser = appState.currentUser;
    _currentUser = fallbackUser;

    if (Firebase.apps.isEmpty) {
      _applyFallbackUser(fallbackUser);
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
      return;
    }

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      _applyFallbackUser(fallbackUser);
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
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
        'photoUrl': data['photoUrl'] ?? fallbackUser?.photoUrl,
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
      _serviceInterests
        ..clear()
        ..addAll(
          (data['serviceInterests'] as List?)?.cast<String>() ?? const [],
        );
      _selectedServiceInterest =
          data['serviceInterests'] is List &&
              (data['serviceInterests'] as List).isNotEmpty
          ? (data['serviceInterests'] as List).first as String
          : null;
      _selectedUrgency = data['serviceUrgency'] as String?;
      _selectedFrequency = data['contractFrequency'] as String?;
      _cityController.text =
          (data['city'] as String?) ?? fallbackUser?.city ?? '';
      _addressController.text = (data['operationAddress'] as String?) ?? '';
      _contactName =
          data['contactName'] as String? ?? data['fullName'] as String?;
      _contactPhone = data['phone'] as String?;
      _billingEmail = data['billingEmail'] as String?;
      if (_titleController.text.isEmpty && _selectedServiceInterest != null) {
        _titleController.text = 'Solicitud de ${_selectedServiceInterest!}';
      }
      await _syncSubcategoriesForSelectedService();
    } catch (_) {
      _applyFallbackUser(fallbackUser);
    } finally {
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
    }
  }

  void _applyFallbackUser(UserModel? user) {
    _clientProfileCompleted = user?.clientProfileCompleted == true;
    _cityController.text = user?.city ?? '';
    _contactName = user?.fullName ?? user?.companyName;
  }

  Future<void> _loadCategoryCatalog() async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      if (!mounted) {
        return;
      }
      setState(() {
        _categoryCatalog = snapshot.docs;
      });
      await _syncSubcategoriesForSelectedService(
        preferredSubcategoryId: _selectedSubcategoryId,
        preferredSubcategoryName: _selectedSubcategoryName,
      );
    } catch (_) {}
  }

  Future<void> _syncSubcategoriesForSelectedService({
    String? preferredSubcategoryId,
    String? preferredSubcategoryName,
  }) async {
    final selectedCategory = _selectedServiceInterest?.trim();
    if (selectedCategory == null ||
        selectedCategory.isEmpty ||
        Firebase.apps.isEmpty ||
        _categoryCatalog.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _subcategoryCatalog = [];
        _selectedSubcategoryId = preferredSubcategoryId;
        _selectedSubcategoryName = preferredSubcategoryName;
      });
      return;
    }

    final matchedCategory = _findCategoryBySelection(selectedCategory);

    if (matchedCategory == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _subcategoryCatalog = [];
        _selectedSubcategoryId = preferredSubcategoryId;
        _selectedSubcategoryName = preferredSubcategoryName;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .doc(matchedCategory.id)
        .collection('subcategories')
        .get();
    if (!mounted) {
      return;
    }

    String? nextSubcategoryId =
        preferredSubcategoryId ?? _selectedSubcategoryId;
    String? nextSubcategoryName =
        preferredSubcategoryName ?? _selectedSubcategoryName;

    if (nextSubcategoryId != null && nextSubcategoryId.isNotEmpty) {
      final matches = snapshot.docs.where((doc) => doc.id == nextSubcategoryId);
      if (matches.isNotEmpty) {
        nextSubcategoryName =
            (matches.first.data()['name'] as String?)?.trim() ??
            nextSubcategoryName;
      } else {
        nextSubcategoryId = null;
        nextSubcategoryName = null;
      }
    } else if (nextSubcategoryName != null && nextSubcategoryName.isNotEmpty) {
      final matches = snapshot.docs.where((doc) {
        final name = (doc.data()['name'] as String?)?.trim() ?? '';
        return name == nextSubcategoryName;
      });
      if (matches.isNotEmpty) {
        nextSubcategoryId = matches.first.id;
        nextSubcategoryName =
            (matches.first.data()['name'] as String?)?.trim() ??
            nextSubcategoryName;
      }
    }

    setState(() {
      _subcategoryCatalog = snapshot.docs;
      _selectedSubcategoryId = nextSubcategoryId;
      _selectedSubcategoryName = nextSubcategoryName;
    });
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findCategoryBySelection(
    String selectedCategory,
  ) {
    for (final doc in _categoryCatalog) {
      final categoryName = (doc.data()['name'] as String?)?.trim() ?? '';
      if (doc.id == selectedCategory || categoryName == selectedCategory) {
        return doc;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _buildMatchingSummary() async {
    final selectedCategory = _selectedServiceInterest?.trim();
    final subcategoryId = _selectedSubcategoryId?.trim();
    final subcategoryName = _selectedSubcategoryName?.trim();
    if (Firebase.apps.isEmpty ||
        selectedCategory == null ||
        selectedCategory.isEmpty) {
      return const <String, dynamic>{};
    }

    final matchedCategory = _findCategoryBySelection(selectedCategory);
    final categoryId = matchedCategory?.id;
    final categoryName =
        (matchedCategory?.data()['name'] as String?)?.trim() ??
        selectedCategory;

    final servicesSnapshot = await FirebaseFirestore.instance
        .collection('provider_services')
        .get();

    String normalize(dynamic value) =>
        (value?.toString().trim().toLowerCase() ?? '');

    bool matchesAny(dynamic source, List<String> expectedValues) {
      final normalizedSource = normalize(source);
      if (normalizedSource.isEmpty) {
        return false;
      }
      for (final expected in expectedValues) {
        if (normalize(expected) == normalizedSource) {
          return true;
        }
      }
      return false;
    }

    bool isActiveService(Map<String, dynamic> service) {
      final isActive = service['isActive'];
      if (isActive is bool) {
        return isActive;
      }
      final status = normalize(service['status']);
      if (status.isEmpty) {
        return true;
      }
      return status == 'active' ||
          status == 'activo' ||
          status == 'published' ||
          status == 'publicado';
    }

    final matchedDocs = servicesSnapshot.docs.where((doc) {
      final data = doc.data();
      if (!isActiveService(data)) {
        return false;
      }

      final categoryCandidates = <dynamic>[
        data['categoryId'],
        data['serviceCategoryId'],
        data['categoryName'],
        data['serviceCategoryName'],
        data['serviceCategory'],
      ];

      final categoryTargets = <String>[
        if (categoryId != null && categoryId.isNotEmpty) categoryId,
        if (categoryName.isNotEmpty) categoryName,
        selectedCategory,
      ];

      final categoryMatches = categoryCandidates.any(
        (candidate) => matchesAny(candidate, categoryTargets),
      );
      if (!categoryMatches) {
        return false;
      }

      final hasSubcategoryFilter =
          (subcategoryId != null && subcategoryId.isNotEmpty) ||
          (subcategoryName != null && subcategoryName.isNotEmpty);
      if (!hasSubcategoryFilter) {
        return true;
      }

      final subcategoryCandidates = <dynamic>[
        data['subcategoryId'],
        data['serviceSubcategoryId'],
        data['subcategoryName'],
        data['serviceSubcategoryName'],
        data['serviceSubcategory'],
      ];

      final subcategoryTargets = <String>[
        if (subcategoryId != null && subcategoryId.isNotEmpty) subcategoryId,
        if (subcategoryName != null && subcategoryName.isNotEmpty)
          subcategoryName,
      ];

      return subcategoryCandidates.any(
        (candidate) => matchesAny(candidate, subcategoryTargets),
      );
    }).toList();

    final matchedServiceIds = matchedDocs.map((doc) => doc.id).toList();
    final matchedProviderIds = matchedDocs
        .map((doc) => doc.data()['providerId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    return {
      'matchedProviderIds': matchedProviderIds,
      'matchedServiceIds': matchedServiceIds,
      'matchedProvidersCount': matchedProviderIds.length,
      'matchedServicesCount': matchedServiceIds.length,
      'category': selectedCategory,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'matchingMode':
          (subcategoryId != null && subcategoryId.isNotEmpty) ||
              (subcategoryName != null && subcategoryName.isNotEmpty)
          ? 'subcategory_exact'
          : 'category_broad',
    };
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
    final requestedMode = args['requestMode'] as String?;
    final requestedUrgency = args['serviceUrgency'] as String?;
    final requestedCity = args['city'] as String?;
    final requestedSupervisor = args['supervisorRequested'] == true;
    final requestedSupervisorType = args['supervisorType'] as String?;
    final requestedTitle = args['requestTitle'] as String?;
    final requestedDescription = args['requestDescription'] as String?;
    final requestedNotes = args['requestNotes'] as String?;
    final requestedIntent = args['requestIntent'] as String?;
    final requestedSource = args['requestSource'] as String?;
    final requestedProviderId = args['preferredProviderId'] as String?;
    final requestedProviderName = args['preferredProviderName'] as String?;
    final requestedProviderServiceId =
        args['preferredProviderServiceId'] as String?;
    final requestedProviderServiceTitle =
        args['preferredProviderServiceTitle'] as String?;
    final requestedProviderServicePriceType =
        args['preferredProviderServicePriceType'] as String?;
    final requestedSubcategoryId = args['serviceSubcategoryId'] as String?;
    final requestedSubcategoryName = args['serviceSubcategoryName'] as String?;

    if (requestedService != null && requestedService.isNotEmpty) {
      _selectedServiceInterest = requestedService;
      if (!_serviceInterests.contains(requestedService)) {
        _serviceInterests.add(requestedService);
      }
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = 'Solicitud de $requestedService';
      }
    }

    if (requestedTitle != null && requestedTitle.trim().isNotEmpty) {
      _titleController.text = requestedTitle.trim();
    }

    if (requestedDescription != null &&
        requestedDescription.trim().isNotEmpty &&
        _descriptionController.text.trim().isEmpty) {
      _descriptionController.text = requestedDescription.trim();
    }

    if (requestedNotes != null &&
        requestedNotes.trim().isNotEmpty &&
        _notesController.text.trim().isEmpty) {
      _notesController.text = requestedNotes.trim();
    }

    if (requestedIntent != null && requestedIntent.trim().isNotEmpty) {
      _requestIntent = requestedIntent.trim();
    }

    if (requestedSource != null && requestedSource.trim().isNotEmpty) {
      _requestSource = requestedSource.trim();
    }

    _preferredProviderId = requestedProviderId;
    _preferredProviderName = requestedProviderName;
    _preferredProviderServiceId = requestedProviderServiceId;
    _preferredProviderServiceTitle = requestedProviderServiceTitle;
    _preferredProviderServicePriceType = requestedProviderServicePriceType;
    _selectedSubcategoryId = requestedSubcategoryId;
    _selectedSubcategoryName = requestedSubcategoryName;

    if (requestedMode != null && requestedMode.isNotEmpty) {
      _requestMode = requestedMode;
      if (_requestMode == 'emergency') {
        _selectedUrgency = requestedUrgency ?? 'Urgente 24/7';
        _supervisorRequested = true;
        _supervisorType = 'execution_traceability';
      }
    }

    if (requestedSupervisor) {
      _supervisorRequested = true;
      _supervisorType = requestedSupervisorType ?? 'prequote_diagnostic';
      _supervisorCost = _calculateSupervisorCost();
    }

    if ((requestedCity?.isNotEmpty ?? false) &&
        _cityController.text.trim().isEmpty) {
      _cityController.text = requestedCity!;
    }

    _syncSubcategoriesForSelectedService(
      preferredSubcategoryId: requestedSubcategoryId,
      preferredSubcategoryName: requestedSubcategoryName,
    );
  }

  double _calculateSupervisorCost() {
    final estimatedValue =
        double.tryParse(_estimatedValueController.text.replaceAll(',', '.')) ??
        0;
    if (_supervisorType == 'prequote_diagnostic' ||
        _supervisorType == 'puntual') {
      return 80000;
    }
    if (_supervisorType == 'execution_traceability' ||
        _supervisorType == 'completo') {
      if (estimatedValue > 0) {
        return (estimatedValue * 0.08).clamp(150000, double.infinity);
      }
      return 150000;
    }
    return 0;
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
      'request_images/$userId',
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
          content: Text(
            'Completa el perfil cliente antes de publicar solicitudes.',
          ),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedServiceInterest == null ||
        _selectedUrgency == null ||
        _selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona servicio, urgencia y frecuencia para continuar.',
          ),
        ),
      );
      return;
    }

    if (_subcategoryCatalog.isNotEmpty &&
        (_selectedSubcategoryId == null || _selectedSubcategoryId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona una subcategoría para continuar con el matching correcto.',
          ),
        ),
      );
      return;
    }

    final authUser = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final userId = authUser?.uid ?? _currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
      _supervisorCost = _calculateSupervisorCost();
    });

    try {
      final selectedCategory = _selectedServiceInterest?.trim() ?? '';
      final matchedCategory = selectedCategory.isEmpty
          ? null
          : _findCategoryBySelection(selectedCategory);
      final resolvedCategoryId = matchedCategory?.id;
      final resolvedCategoryName =
          (matchedCategory?.data()['name'] as String?)?.trim() ??
          _selectedServiceInterest;

      final estimatedValue =
          double.tryParse(
            _estimatedValueController.text.replaceAll(',', '.'),
          ) ??
          0;
      final matchingSummary = await _buildMatchingSummary();
      final commercialRouting = _buildCommercialRouting();
      final technicalSurveySeed = _supervisorRequested && _isPrequoteDiagnostic
          ? _buildTechnicalSurveySeed()
          : null;

      final requestRef = await FirebaseFirestore.instance
          .collection('solicitudes')
          .add({
            'titulo': _titleController.text.trim(),
            'descripcion': _descriptionController.text.trim(),
            'status': 'activa',
            'type': _requestMode,
            'requiresImmediateResponse': _requestMode == 'emergency',
            'serviceInterest': _selectedServiceInterest,
            'serviceCategory': resolvedCategoryName,
            'serviceCategoryId': resolvedCategoryId,
            'serviceCategoryName': resolvedCategoryName,
            'serviceSubcategoryId': _selectedSubcategoryId,
            'serviceSubcategory':
                _selectedSubcategoryName ?? _subcategoryPlaceholder,
            'serviceUrgency': _selectedUrgency,
            'contractFrequency': _selectedFrequency,
            'city': _cityController.text.trim(),
            'operationAddress': _addressController.text.trim(),
            'estimatedValue': estimatedValue,
            'requesterNotes': _notesController.text.trim(),
            'requestImageUrls': _requestImageUrls,
            'requestIntent': _requestIntent,
            'requestSource': _requestSource,
            'commercialFlowMode': _commercialFlowMode,
            'commercialFlowLabel': _commercialFlowLabel,
            'commercialEntryPoint': 'buyer_marketplace',
            'commercialDossierVersion': 'unified_v1',
            'commercialRouting': commercialRouting,
            'commercialMatching': matchingSummary,
            'commercialFlowStage': _buildCommercialFlowStage(),
            'commercialFlowUpdatedAt': FieldValue.serverTimestamp(),
            'contactVisibilityPolicy': 'saneapp_managed',
            'billingChannelPolicy': 'saneapp_only',
            'traceabilityMode': 'full_platform_traceability',
            'contactName': _contactName,
            'contactPhone': _contactPhone,
            'billingEmail': _billingEmail,
            'preferredProviderId': _preferredProviderId,
            'preferredProviderName': _preferredProviderName,
            'preferredProviderServiceId': _preferredProviderServiceId,
            'preferredProviderServiceTitle': _preferredProviderServiceTitle,
            'preferredProviderServicePriceType':
                _preferredProviderServicePriceType,
            'directedToProvider':
                _preferredProviderId != null &&
                _preferredProviderId!.isNotEmpty,
            'profileSnapshot': {
              'companyName': _currentUser?.companyName,
              'fullName': _currentUser?.fullName,
              'entityType': _currentUser?.entityType,
              'clientType': _currentUser?.clientType,
            },
            'generadorId': userId,
            'createdAt': FieldValue.serverTimestamp(),
            'supervisorRequested': _supervisorRequested,
            'supervisorType': _supervisorRequested ? _supervisorType : null,
            'supervisorCost': _supervisorRequested ? _supervisorCost : 0.0,
            'supervisorId': null,
            'supervisorName': null,
            'supervisorAssignedAt': null,
            'supervisorOrderCode': null,
            'supervisorStatus': _supervisorRequested
                ? 'pendiente_asignacion'
                : null,
            'supervisorDispatchMode': _supervisorRequested
                ? 'pending_auto_dispatch'
                : null,
            'supervisorDispatchReason': null,
            'supervisionJourney': _supervisorRequested ? _supervisorType : null,
            'supervisionProviderType': _supervisorRequested
                ? 'saneapp_staff'
                : null,
            'supervisionServiceSummary': _supervisorRequested
                ? _buildSupervisionSummary()
                : null,
            'prequoteTechnicalSurveyRequired':
                _supervisorRequested && _isPrequoteDiagnostic,
            'providerQualityEvaluationRequired':
                _supervisorRequested && _isExecutionTraceability,
            'providerQualityEvaluationStatus':
                _supervisorRequested && _isExecutionTraceability
                ? 'pendiente'
                : null,
            'technicalSurveySheet': technicalSurveySeed,
            'providerQualityEvaluation':
                _supervisorRequested && _isExecutionTraceability
                ? buildInitialProviderQualityEvaluation()
                : null,
            'supervisionDeliverables': _supervisorRequested
                ? _buildSupervisionDeliverables()
                : null,
          });
      await CommercialTimelineService.recordRequestCreated(
        requestId: requestRef.id,
        title: _titleController.text.trim(),
        generatorId: userId,
        category: _selectedServiceInterest ?? 'Sin categoría',
        subcategory: _selectedSubcategoryName,
        providerId: _preferredProviderId,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud creada correctamente.')),
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
        backgroundColor: _surface,
        appBar: AppBar(
          title: const Text('Crear solicitud'),
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
        ),
        body: _profileLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    _HeroCard(
                      clientProfileCompleted: _clientProfileCompleted,
                      companyName:
                          _currentUser?.companyName ??
                          _currentUser?.fullName ??
                          'Cliente SaneApp',
                      serviceInterest: _selectedServiceInterest,
                      city: _cityController.text,
                      onCompleteProfile: () {
                        Navigator.pushNamed(context, '/client-profile');
                      },
                      requestMode: _requestMode,
                    ),
                    if (_requestMode == 'emergency') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1E8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1C8B1)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: _alertColor,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Estás creando una emergencia ambiental. Esta solicitud se publicará con prioridad alta y acompañamiento sugerido de supervisión.',
                                style: TextStyle(color: Color(0xFF7A3710)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: _requestMode == 'emergency'
                          ? 'Incidente o servicio crítico'
                          : 'Servicio solicitado',
                      subtitle: _requestMode == 'emergency'
                          ? 'La categoría se precarga desde el flujo de emergencia, pero puedes ajustarla si el incidente requiere otra especialidad.'
                          : 'La categoría se precarga desde tu perfil cliente, pero puedes ajustarla para este requerimiento específico.',
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedServiceInterest,
                            decoration: _inputDecoration('Servicio principal'),
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
                                      _selectedSubcategoryId = null;
                                      _selectedSubcategoryName = null;
                                      if (value != null &&
                                          _titleController.text
                                              .trim()
                                              .isEmpty) {
                                        _titleController.text =
                                            'Solicitud de $value';
                                      }
                                    });
                                    _syncSubcategoriesForSelectedService();
                                  },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Selecciona un servicio.'
                                : null,
                          ),
                          if (_serviceInterests.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/client-profile',
                                  ),
                                  icon: const Icon(Icons.tune),
                                  label: const Text(
                                    'Completa tus intereses en el perfil cliente',
                                  ),
                                ),
                              ),
                            ),
                          if (_subcategoryCatalog.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSubcategoryId,
                              decoration: _inputDecoration('Subcategoría'),
                              items: _subcategoryCatalog
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item.id,
                                      child: Text(
                                        (item.data()['name'] as String?)
                                                ?.trim() ??
                                            item.id,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubcategoryId = value;
                                  _selectedSubcategoryName = value == null
                                      ? null
                                      : (_subcategoryCatalog
                                                    .firstWhere(
                                                      (doc) => doc.id == value,
                                                    )
                                                    .data()['name']
                                                as String?)
                                            ?.trim();
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Selecciona una subcategoría para afinar el matching.'
                                  : null,
                            ),
                            if (_selectedSubcategoryName != null &&
                                _selectedSubcategoryName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'El matching premium se hará por ${_selectedSubcategoryName!}.',
                                    style: const TextStyle(
                                      color: Color(0xFF5B6B63),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 12),
                          if (_preferredProviderId != null &&
                              _preferredProviderId!.isNotEmpty) ...[
                            _SectionCard(
                              title: 'Proveedor objetivo',
                              subtitle:
                                  'Esta solicitud quedará dirigida al proveedor que elegiste en el marketplace.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _preferredProviderName ??
                                        'Proveedor seleccionado',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _brandGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _preferredProviderServiceTitle ??
                                        _preferredProviderName ??
                                        'Servicio del marketplace',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _requestIntent == 'direct_quote_request'
                                        ? 'Modo: solicitud de cotización dirigida.'
                                        : _requestIntent == 'supervisor_request'
                                        ? 'Modo: solicitud dirigida con acompañamiento de supervisor.'
                                        : 'Modo: solicitud directa de servicio al proveedor seleccionado.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _titleController,
                            decoration: _inputDecoration(
                              'Título de la solicitud',
                            ),
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
                            decoration: _inputDecoration(
                              'Describe alcance, residuos, frecuencia y condicionantes',
                            ),
                            validator: (value) =>
                                value == null || value.trim().length < 20
                                ? 'Describe mejor el requerimiento.'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Ubicación y operación',
                      subtitle:
                          'Estos datos se precargan desde tu perfil para acelerar la publicación y mejorar el matching con proveedores.',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _cityController,
                            decoration: _inputDecoration('Ciudad'),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa la ciudad.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: _inputDecoration(
                              'Dirección o punto de atención',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa una ubicación operativa.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedFrequency,
                            decoration: _inputDecoration('Frecuencia esperada'),
                            items: _frequencyOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFrequency = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedUrgency,
                            decoration: _inputDecoration('Nivel de urgencia'),
                            items: _urgencyOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUrgency = value;
                                if (value == 'Urgente 24/7' &&
                                    _requestMode != 'emergency') {
                                  _requestMode = 'emergency';
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _estimatedValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration(
                              'Valor estimado del servicio (COP)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Notas para operación, acceso, seguridad o facturación',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Imágenes de referencia',
                      subtitle:
                          'Adjunta fotos del punto, residuos, accesos o contexto operativo para mejorar la evaluación del proveedor.',
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
                      title: 'Expediente comercial',
                      subtitle:
                          'Este negocio quedará trazado dentro del flujo comercial unificado de SaneApp, sin importar si entra como solicitud directa o cotización asistida.',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD5E6D8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _commercialFlowLabel,
                              style: const TextStyle(
                                color: _brandGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _commercialFlowDescription,
                              style: const TextStyle(height: 1.35),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _hasDirectedProvider
                                  ? 'Proveedor objetivo: ${_preferredProviderName ?? 'Seleccionado desde vitrina'}'
                                  : 'Cobertura: marketplace ambiental abierto',
                              style: const TextStyle(
                                color: Color(0xFF5F6D66),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Supervisión opcional de SaneApp',
                      subtitle:
                          'Añade verificación técnica para elevar control, trazabilidad y respaldo del servicio contratado.',
                      child: Column(
                        children: [
                          _SupervisorOptionTile(
                            title: 'No deseo supervisor',
                            selected: _supervisorType == 'ninguno',
                            onTap: () {
                              setState(() {
                                _supervisorType = 'ninguno';
                                _supervisorRequested = false;
                                _supervisorCost = 0;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _SupervisorOptionTile(
                            title: 'Diagnóstico técnico previo a cotización',
                            subtitle:
                                'Visita técnica al sitio, levantamiento de accesos, residuos, condiciones reales e informe para cotizar mejor.',
                            selected: _supervisorType == 'prequote_diagnostic',
                            onTap: () {
                              setState(() {
                                _supervisorType = 'prequote_diagnostic';
                                _supervisorRequested = true;
                                _supervisorCost = _calculateSupervisorCost();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          _SupervisorOptionTile(
                            title: 'Supervisión de ejecución y trazabilidad',
                            subtitle:
                                'Acompañamiento del servicio ejecutado por el proveedor, con buenas prácticas, evidencias y evaluación de calidad.',
                            selected:
                                _supervisorType == 'execution_traceability',
                            onTap: () {
                              setState(() {
                                _supervisorType = 'execution_traceability';
                                _supervisorRequested = true;
                                _supervisorCost = _calculateSupervisorCost();
                              });
                            },
                          ),
                          if (_supervisorRequested)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF5EE),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFCFE6D6),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Costo estimado de supervisión: ${_supervisorCost.toStringAsFixed(0)} COP',
                                    style: const TextStyle(
                                      color: _brandGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isPrequoteDiagnostic
                                        ? 'Incluye visita técnica, registro fotográfico, condiciones operativas y ficha técnica previa a cotización.'
                                        : 'Incluye seguimiento en sitio, evidencias, control de buenas prácticas y evaluación de calidad del proveedor.',
                                  ),
                                ],
                              ),
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
                : const Icon(Icons.send_outlined),
            label: Text(
              _saving
                  ? 'Publicando solicitud...'
                  : _requestMode == 'emergency'
                  ? 'Activar emergencia'
                  : 'Publicar solicitud',
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
        borderSide: const BorderSide(color: Color(0xFFD6E3DA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6E3DA)),
      ),
    );
  }
}

extension on _CrearSolicitudPageState {
  bool get _hasDirectedProvider =>
      _preferredProviderId != null && _preferredProviderId!.isNotEmpty;

  bool get _isPrequoteDiagnostic =>
      _supervisorType == 'prequote_diagnostic' || _supervisorType == 'puntual';

  bool get _isExecutionTraceability =>
      _supervisorType == 'execution_traceability' ||
      _supervisorType == 'completo';

  Map<String, dynamic>? _buildCommercialRouting() {
    if (!_hasDirectedProvider &&
        (_requestSource == null || _requestSource!.trim().isEmpty)) {
      return null;
    }

    return {
      'requestIntent': _requestIntent,
      'requestSource': _requestSource,
      'preferredProviderId': _preferredProviderId,
      'preferredProviderName': _preferredProviderName,
      'preferredProviderServiceId': _preferredProviderServiceId,
      'preferredProviderServiceTitle': _preferredProviderServiceTitle,
      'preferredProviderServicePriceType': _preferredProviderServicePriceType,
      'serviceCategory': _selectedServiceInterest,
      'serviceSubcategoryId': _selectedSubcategoryId,
      'serviceSubcategoryName': _selectedSubcategoryName,
      'supervisorJourney': _supervisorRequested ? _supervisorType : null,
      'directedToProvider': _hasDirectedProvider,
    };
  }

  String _buildCommercialFlowStage() {
    if (_supervisorRequested && _isPrequoteDiagnostic) {
      return _hasDirectedProvider
          ? 'awaiting_supervisor_visit_for_provider_quote'
          : 'awaiting_supervisor_visit';
    }
    if (_requestIntent == 'direct_quote_request' && _hasDirectedProvider) {
      return 'awaiting_provider_quote';
    }
    if (_requestIntent == 'direct_service_request' && _hasDirectedProvider) {
      return 'awaiting_provider_response';
    }
    if (_requestIntent == 'supervisor_request' && _hasDirectedProvider) {
      return 'awaiting_supervisor_visit_for_provider_quote';
    }
    return 'open_marketplace';
  }

  Map<String, dynamic> _buildTechnicalSurveySeed() {
    final sheet = buildInitialTechnicalSurveySheet(
      city: _cityController.text.trim(),
      address: _addressController.text.trim(),
      serviceCategory: _selectedServiceInterest,
      urgency: _selectedUrgency,
    );

    if (_hasDirectedProvider) {
      sheet['targetProvider'] = {
        'providerId': _preferredProviderId,
        'providerName': _preferredProviderName,
        'serviceId': _preferredProviderServiceId,
        'serviceTitle': _preferredProviderServiceTitle,
        'priceType': _preferredProviderServicePriceType,
      };
      sheet['providerGuidance'] =
          'La ficha técnica quedará visible para ${{'name': _preferredProviderName}['name'] ?? 'el proveedor seleccionado'} y soportará una cotización dirigida con mejores condiciones operativas.';
    }

    return sheet;
  }

  String _buildSupervisionSummary() {
    if (_isPrequoteDiagnostic) {
      return 'Personal técnico directo de SaneApp realizará visita previa, levantamiento técnico, registro fotográfico y ficha de condiciones reales para que el generador defina el servicio y el proveedor cotice con más precisión.';
    }

    return 'Personal técnico directo de SaneApp acompañará la ejecución del servicio, verificará buenas prácticas del proveedor, registrará evidencias y evaluará la calidad del servicio prestado.';
  }

  List<String> _buildSupervisionDeliverables() {
    if (_isPrequoteDiagnostic) {
      return const [
        'levantamiento_tecnico',
        'registro_fotografico',
        'condiciones_de_acceso',
        'clasificacion_preliminar_de_residuos',
        'ficha_tecnica_previa_a_cotizacion',
      ];
    }

    return const [
      'acta_de_inicio',
      'evidencias_de_ejecucion',
      'control_de_buenas_practicas',
      'incidencias_y_observaciones',
      'evaluacion_de_calidad_del_proveedor',
      'acta_de_cierre',
    ];
  }
}

class _HeroCard extends StatelessWidget {
  final bool clientProfileCompleted;
  final String companyName;
  final String? serviceInterest;
  final String city;
  final VoidCallback onCompleteProfile;
  final String requestMode;

  const _HeroCard({
    required this.clientProfileCompleted,
    required this.companyName,
    required this.serviceInterest,
    required this.city,
    required this.onCompleteProfile,
    required this.requestMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0C4F31), Color(0xFF1E7A4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            companyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            clientProfileCompleted
                ? 'Tu perfil cliente ya alimenta esta solicitud con datos de operación, ubicación y preferencias.'
                : 'Completa tu perfil cliente para publicar solicitudes con contexto operativo y mejor matching.',
            style: const TextStyle(color: Colors.white70),
          ),
          if (requestMode == 'emergency') ...[
            const SizedBox(height: 10),
            const Text(
              'Modo de publicación: Emergencia 24/7',
              style: TextStyle(
                color: Color(0xFFFFD6C2),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(label: serviceInterest ?? 'Sin servicio principal'),
              _HeroBadge(label: city.isEmpty ? 'Sin ciudad' : city),
              _HeroBadge(
                label: clientProfileCompleted
                    ? 'Perfil completo'
                    : 'Perfil pendiente',
              ),
            ],
          ),
          if (!clientProfileCompleted) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onCompleteProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Completar perfil cliente'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

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
          fontWeight: FontWeight.w600,
        ),
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

class _SupervisorOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SupervisorOptionTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF5EE) : const Color(0xFFF8FBF9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1E7A4B)
                  : const Color(0xFFDCE7DF),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? const Color(0xFF1E7A4B) : Colors.black38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
