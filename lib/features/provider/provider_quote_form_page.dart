import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/commercial_timeline_service.dart';
import '../../services/provider_commercial_reputation_service.dart';

class ProviderQuoteFormPage extends StatefulWidget {
  const ProviderQuoteFormPage({
    super.key,
    required this.solicitudId,
    required this.requestData,
  });

  final String solicitudId;
  final Map<String, dynamic> requestData;

  @override
  State<ProviderQuoteFormPage> createState() => _ProviderQuoteFormPageState();
}

class _ProviderQuoteFormPageState extends State<ProviderQuoteFormPage> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _pricingUnitOptions = <String>[
    'Precio fijo por servicio',
    'Por horas',
    'Por metro cúbico',
    'Por toneladas',
    'Por metro lineal',
    'Por viaje',
    'Por flete',
  ];

  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _scopeController = TextEditingController();
  final _deliverablesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _exclusionsController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _validityDaysController = TextEditingController(text: '15');
  final _timelineController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _observationsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _applyIva = true;
  double _ivaRate = 19;
  String _pricingUnit = 'Precio fijo por servicio';
  Map<String, dynamic> _providerData = const <String, dynamic>{};
  Map<String, dynamic> _userData = const <String, dynamic>{};

  String get _requestCategory =>
      widget.requestData['serviceCategory']?.toString() ??
      widget.requestData['serviceInterest']?.toString() ??
      'Sin categoría';

  String get _requestSubcategory =>
      widget.requestData['serviceSubcategory']?.toString() ?? '';

  _PricingGuidance get _pricingGuidance {
    final category = _requestCategory.toLowerCase();
    final subcategory = _requestSubcategory.toLowerCase();

    if (subcategory.contains('emerg') || category.contains('emerg')) {
      return const _PricingGuidance(
        recommendedUnit: 'Por horas',
        suggestedRange: '280000 - 450000 COP / hora',
        positioning:
            'Posiciónate por disponibilidad inmediata, cuadrilla y ventana de reacción 24/7.',
        paymentTerms:
            '50% para activación operativa y saldo contra cierre documentado en SaneApp.',
        warranty: 'Garantía operativa de contingencia por 15 días.',
      );
    }

    if (subcategory.contains('recole') || category.contains('residu')) {
      return const _PricingGuidance(
        recommendedUnit: 'Por viaje',
        suggestedRange: '900000 - 1800000 COP / viaje',
        positioning:
            'Ancla el valor en trazabilidad, manifiestos, transporte y soporte de disposición final.',
        paymentTerms:
            'Pago contra evidencias de transporte y cierre formal del expediente comercial.',
        warranty: 'Garantía documental y de trazabilidad por 30 días.',
      );
    }

    if (subcategory.contains('limpieza') || category.contains('limpieza')) {
      return const _PricingGuidance(
        recommendedUnit: 'Por metro cúbico',
        suggestedRange: '180000 - 320000 COP / m3',
        positioning:
            'Sustenta la tarifa por volumen, complejidad operativa, acceso y protocolo de seguridad.',
        paymentTerms:
            'Anticipo operativo y saldo contra acta de cierre con evidencias.',
        warranty: 'Garantía de ejecución por 30 días.',
      );
    }

    return const _PricingGuidance(
      recommendedUnit: 'Precio fijo por servicio',
      suggestedRange: 'Definir según alcance validado y expediente técnico.',
      positioning:
          'Usa un precio fijo cuando el alcance ya esté cerrado y el entregable sea claramente verificable.',
      paymentTerms:
          'Condiciones comerciales dentro de SaneApp con hitos verificables.',
      warranty: 'Garantía de acuerdo con el alcance comprometido.',
    );
  }

  List<_QuotePlaybookItem> get _quotePlaybookItems {
    final normalizedSubcategory = _requestSubcategory.toLowerCase();
    final normalizedCategory = _requestCategory.toLowerCase();
    final items = <_QuotePlaybookItem>[
      _QuotePlaybookItem(
        title: 'Alcance por expediente',
        detail:
            'Usa el contexto de ${_requestCategory.toLowerCase()} para amarrar alcance, entregables, exclusiones y tiempos al mismo negocio.',
        actionLabel: 'Cargar alcance sugerido',
        onApply: () {
          _scopeController.text =
              widget.requestData['descripcion']?.toString() ??
              'El alcance se ejecutará sobre el expediente comercial creado en SaneApp, con trazabilidad completa desde cotización hasta cierre.';
          _deliverablesController.text =
              'Plan de trabajo, ejecución del servicio, evidencias de cumplimiento y cierre operativo dentro del expediente comercial.';
        },
      ),
      _QuotePlaybookItem(
        title: 'SLA y respuesta premium',
        detail:
            'Declara tiempo de respuesta, ventana de arranque y reglas de escalamiento. Eso protege tu ranking comercial.',
        actionLabel: 'Aplicar SLA premium',
        onApply: () {
          _timelineController.text = _timelineController.text.trim().isEmpty
              ? 'Inicio en menos de 24 horas después de aprobación'
              : _timelineController.text;
          _conditionsController.text =
              '${_conditionsController.text.trim()}\nSLA premium: confirmación de arranque, actualización por hitos y canal transaccional dentro de SaneApp.'
                  .trim();
        },
      ),
      _QuotePlaybookItem(
        title: 'Cierre y soporte formal',
        detail:
            'Anticipa evidencias, actas y soportes necesarios para liberar pago o defender una disputa.',
        actionLabel: 'Añadir cierre formal',
        onApply: () {
          _deliverablesController.text =
              '${_deliverablesController.text.trim()}\nActa de ejecución, evidencias fotográficas y soportes comerciales para liberación.'
                  .trim();
          _observationsController.text =
              '${_observationsController.text.trim()}\nLa propuesta contempla cierre documentado y soportes del proveedor ligados al expediente SaneApp.'
                  .trim();
        },
      ),
    ];

    if (normalizedSubcategory.contains('emerg') ||
        normalizedCategory.contains('emerg')) {
      items.add(
        _QuotePlaybookItem(
          title: 'Modo contingencia',
          detail:
              'La oportunidad tiene perfil crítico. Expón disponibilidad, cuadrilla y ventana de reacción inmediata.',
          actionLabel: 'Aplicar contingencia',
          onApply: () {
            _summaryController.text =
                'Presentamos propuesta prioritaria para atención crítica con disponibilidad operativa y trazabilidad continua en SaneApp.';
            _timelineController.text = 'Respuesta operativa inmediata 24/7';
          },
        ),
      );
    }

    if (normalizedSubcategory.contains('recole') ||
        normalizedCategory.contains('residu')) {
      items.add(
        _QuotePlaybookItem(
          title: 'Trazabilidad de residuos',
          detail:
              'Refuerza manifiestos, transporte, disposición y evidencias del flujo ambiental.',
          actionLabel: 'Aplicar trazabilidad',
          onApply: () {
            _deliverablesController.text =
                '${_deliverablesController.text.trim()}\nManifiesto, registro de transporte, evidencia de entrega y soporte de disposición final.'
                    .trim();
          },
        ),
      );
    }

    return items;
  }

  List<TextEditingController> get _draftControllers => [
    _summaryController,
    _scopeController,
    _deliverablesController,
    _conditionsController,
    _exclusionsController,
    _unitPriceController,
    _quantityController,
    _validityDaysController,
    _timelineController,
    _warrantyController,
    _paymentTermsController,
    _observationsController,
  ];

  @override
  void initState() {
    super.initState();
    _hydrateDefaults();
    for (final controller in _draftControllers) {
      controller.addListener(_handleDraftChanged);
    }
    _loadProviderData();
  }

  @override
  void dispose() {
    for (final controller in _draftControllers) {
      controller.removeListener(_handleDraftChanged);
    }
    _summaryController.dispose();
    _scopeController.dispose();
    _deliverablesController.dispose();
    _conditionsController.dispose();
    _exclusionsController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    _validityDaysController.dispose();
    _timelineController.dispose();
    _warrantyController.dispose();
    _paymentTermsController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _handleDraftChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _hydrateDefaults() {
    final title =
        widget.requestData['titulo']?.toString() ?? 'servicio solicitado';
    final description = widget.requestData['descripcion']?.toString() ?? '';
    _pricingUnit = _normalizePricingUnit(
      widget.requestData['preferredProviderServicePriceType']?.toString() ??
          widget.requestData['pricingUnit']?.toString() ??
          widget.requestData['priceType']?.toString(),
    );
    _summaryController.text =
        'Presentamos propuesta económica y técnica para "$title". Nuestra oferta contempla atención operativa, coordinación del servicio y cumplimiento de condiciones acordadas.';
    _scopeController.text = description;
    _deliverablesController.text =
        'Ejecución del servicio, soporte operativo, evidencias y cierre de actividad según alcance acordado.';
    _conditionsController.text =
        'La ejecución queda sujeta a accesos, validación del sitio, disponibilidad operativa y condiciones de seguridad industrial.';
    _exclusionsController.text =
        'No incluye actividades adicionales no descritas en el alcance aprobado ni sobrecostos por novedades no reportadas previamente.';
    _timelineController.text = '3 a 5 días hábiles';
    _warrantyController.text = '30 días sobre la ejecución realizada';
  }

  String _normalizePricingUnit(String? rawValue) {
    final value = rawValue?.trim().toLowerCase();
    switch (value) {
      case 'por horas':
      case 'por hora':
        return 'Por horas';
      case 'por metro cubico':
      case 'por metro cúbico':
      case 'metro cubico':
      case 'metro cúbico':
        return 'Por metro cúbico';
      case 'por tonelada':
      case 'por toneladas':
      case 'tonelada':
      case 'toneladas':
        return 'Por toneladas';
      case 'por metro lineal':
      case 'metro lineal':
        return 'Por metro lineal';
      case 'por visita':
      case 'por viaje':
      case 'viaje':
        return 'Por viaje';
      case 'por flete':
      case 'flete':
        return 'Por flete';
      case 'precio desde':
      case 'cotización personalizada':
      case 'cotizacion personalizada':
      case 'precio fijo':
      case 'precio fijo por servicio':
      default:
        return 'Precio fijo por servicio';
    }
  }

  String get _pricingDescription {
    switch (_pricingUnit) {
      case 'Por horas':
        return 'Precio del servicio liquidado por horas';
      case 'Por metro cúbico':
        return 'Precio del servicio liquidado por metro cúbico';
      case 'Por toneladas':
        return 'Precio del servicio liquidado por toneladas';
      case 'Por metro lineal':
        return 'Precio del servicio liquidado por metro lineal';
      case 'Por viaje':
        return 'Precio del servicio liquidado por viaje';
      case 'Por flete':
        return 'Precio del servicio liquidado por flete';
      default:
        return 'Precio fijo por servicio';
    }
  }

  Future<void> _loadProviderData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final futures = await Future.wait([
      FirebaseFirestore.instance.collection('providers').doc(user.uid).get(),
      FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
    ]);

    _providerData = futures[0].data() ?? const <String, dynamic>{};
    _userData = futures[1].data() ?? const <String, dynamic>{};
    final paymentTerms =
        (_providerData['paymentTerms'] as String?)?.trim() ?? '';
    if (paymentTerms.isNotEmpty) {
      _paymentTermsController.text = paymentTerms;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  bool get _requiresQuantityInput => _pricingUnit != 'Precio fijo por servicio';

  double get _unitPrice =>
      double.tryParse(_unitPriceController.text.replaceAll(',', '.')) ?? 0;

  double get _serviceQuantity {
    if (!_requiresQuantityInput) {
      return 1;
    }
    return double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0;
  }

  double get _subtotal => _unitPrice * _serviceQuantity;

  double get _taxAmount => _applyIva ? _subtotal * (_ivaRate / 100) : 0;

  double get _totalAmount => _subtotal + _taxAmount;

  String get _unitPriceLabel {
    switch (_pricingUnit) {
      case 'Por horas':
        return 'Valor por hora';
      case 'Por metro cúbico':
        return 'Valor por metro cúbico';
      case 'Por toneladas':
        return 'Valor por tonelada';
      case 'Por metro lineal':
        return 'Valor por metro lineal';
      case 'Por viaje':
        return 'Valor por viaje';
      case 'Por flete':
        return 'Valor por flete';
      default:
        return 'Valor del servicio';
    }
  }

  String get _quantityLabel {
    switch (_pricingUnit) {
      case 'Por horas':
        return 'horas';
      case 'Por metro cúbico':
        return 'metros cúbicos';
      case 'Por toneladas':
        return 'toneladas';
      case 'Por metro lineal':
        return 'metros lineales';
      case 'Por viaje':
        return 'viajes';
      case 'Por flete':
        return 'fletes';
      default:
        return 'servicio';
    }
  }

  String get _quantityFieldLabel {
    switch (_pricingUnit) {
      case 'Por horas':
        return 'Cantidad de horas';
      case 'Por metro cúbico':
        return 'Cantidad de metros cúbicos';
      case 'Por toneladas':
        return 'Cantidad de toneladas';
      case 'Por metro lineal':
        return 'Cantidad de metros lineales';
      case 'Por viaje':
        return 'Cantidad de viajes';
      case 'Por flete':
        return 'Cantidad de fletes';
      default:
        return 'Cantidad';
    }
  }

  String get _pricingBreakdown {
    if (!_requiresQuantityInput) {
      return '${formatNumericValue(_unitPrice)} COP por servicio';
    }
    return '${formatNumericValue(_unitPrice)} COP x ${formatNumericValue(_serviceQuantity)} $_quantityLabel';
  }

  static String formatNumericValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    var text = value.toStringAsFixed(2);
    while (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  String get _providerName {
    final providerName = (_providerData['companyName'] as String?)?.trim();
    if (providerName != null && providerName.isNotEmpty) {
      return providerName;
    }
    final userCompany = (_userData['companyName'] as String?)?.trim();
    if (userCompany != null && userCompany.isNotEmpty) {
      return userCompany;
    }
    final fullName = (_userData['fullName'] as String?)?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    return 'Proveedor SaneApp';
  }

  String? get _logoUrl {
    final providerLogo = (_providerData['logoUrl'] as String?)?.trim();
    if (providerLogo != null && providerLogo.isNotEmpty) {
      return providerLogo;
    }
    final userLogo = (_userData['photoUrl'] as String?)?.trim();
    if (userLogo != null && userLogo.isNotEmpty) {
      return userLogo;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final quoteNumber =
          'COT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${widget.solicitudId.substring(0, 4).toUpperCase()}-${user.uid.substring(0, 4).toUpperCase()}';
      final validityDays =
          int.tryParse(_validityDaysController.text.trim()) ?? 15;
      final data = {
        'solicitudId': widget.solicitudId,
        'proveedorId': user.uid,
        'providerName': _providerName,
        'quoteNumber': quoteNumber,
        'serviceCategory': _requestCategory,
        'serviceSubcategory': _requestSubcategory,
        'quoteTemplateVersion': 'premium_v2',
        'pricingGuidance': {
          'recommendedUnit': _pricingGuidance.recommendedUnit,
          'suggestedRange': _pricingGuidance.suggestedRange,
          'positioning': _pricingGuidance.positioning,
        },
        'providerSnapshot': {
          'companyName': _providerName,
          'logoUrl': _logoUrl,
          'operationEmail':
              (_providerData['operationEmail'] as String?) ??
              (_providerData['email'] as String?) ??
              (_userData['email'] as String?),
          'operationPhone':
              (_providerData['operationPhone'] as String?) ??
              (_providerData['phoneNumber'] as String?),
          'billingEmail':
              (_providerData['billingEmail'] as String?) ??
              (_userData['email'] as String?),
        },
        'summary': _summaryController.text.trim(),
        'scope': _scopeController.text.trim(),
        'deliverables': _deliverablesController.text.trim(),
        'serviceConditions': _conditionsController.text.trim(),
        'exclusions': _exclusionsController.text.trim(),
        'pricingUnit': _pricingUnit,
        'pricingDescription': _pricingDescription,
        'unitPrice': _unitPrice,
        'serviceQuantity': _serviceQuantity,
        'quantityLabel': _quantityLabel,
        'pricingBreakdown': _pricingBreakdown,
        'subtotal': _subtotal,
        'appliesIva': _applyIva,
        'ivaRate': _applyIva ? _ivaRate : 0,
        'taxAmount': _taxAmount,
        'totalAmount': _totalAmount,
        'price': _totalAmount,
        'message': _summaryController.text.trim(),
        'tiempoEstimado': _timelineController.text.trim(),
        'garantia': _warrantyController.text.trim(),
        'paymentTerms': _paymentTermsController.text.trim(),
        'validityDays': validityDays,
        'validUntil': Timestamp.fromDate(now.add(Duration(days: validityDays))),
        'observations': _observationsController.text.trim(),
        'status': 'evaluacion',
        'respondedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('ofertas').add(data);
      await ProviderCommercialReputationService.registerCommercialResponse(
        providerId: user.uid,
        requestCreatedAt: (widget.requestData['createdAt'] as Timestamp?)
            ?.toDate(),
      );
      await CommercialTimelineService.recordQuoteSubmitted(
        requestId: widget.solicitudId,
        providerId: user.uid,
        providerName: _providerName,
        quoteNumber: quoteNumber,
        totalAmount: _totalAmount,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización enviada correctamente.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Emitir cotización'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  _HeaderCard(
                    providerName: _providerName,
                    logoUrl: _logoUrl,
                    requestTitle:
                        widget.requestData['titulo']?.toString() ?? 'Solicitud',
                    requestCity: widget.requestData['city']?.toString(),
                    onEditLogo: () async {
                      await Navigator.of(
                        context,
                      ).pushNamed('/perfil_proveedor');
                      await _loadProviderData();
                    },
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Playbook premium de cotización',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _requestSubcategory.trim().isNotEmpty
                              ? 'Esta cotización se está emitiendo para $_requestCategory · $_requestSubcategory.'
                              : 'Esta cotización se está emitiendo para $_requestCategory.',
                          style: const TextStyle(
                            color: Color(0xFF55665E),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._quotePlaybookItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PlaybookTile(item: item),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Presentación de la oferta',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _summaryController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Resumen ejecutivo de la cotización',
                          ),
                          validator: (value) =>
                              value == null || value.trim().length < 40
                              ? 'Explica mejor la propuesta comercial.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _scopeController,
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Alcance del servicio',
                          ),
                          validator: (value) =>
                              value == null || value.trim().length < 30
                              ? 'Detalla el alcance del servicio.'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Condiciones técnicas y comerciales',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _deliverablesController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Entregables incluidos',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _conditionsController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Condiciones de ejecución',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _exclusionsController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Exclusiones o supuestos',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _timelineController,
                                decoration: const InputDecoration(
                                  labelText: 'Tiempo estimado',
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Indica el tiempo estimado.'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _warrantyController,
                                decoration: const InputDecoration(
                                  labelText: 'Garantía',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _paymentTermsController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Términos de pago',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _validityDaysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Vigencia de la cotización (días)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Valores',
                    child: Column(
                      children: [
                        _PricingGuidanceCard(
                          guidance: _pricingGuidance,
                          currentUnit: _pricingUnit,
                          onApply: () {
                            setState(() {
                              _pricingUnit = _pricingGuidance.recommendedUnit;
                              if (!_requiresQuantityInput) {
                                _quantityController.text = '1';
                              }
                              if (_paymentTermsController.text.trim().isEmpty) {
                                _paymentTermsController.text =
                                    _pricingGuidance.paymentTerms;
                              }
                              if (_warrantyController.text.trim().isEmpty) {
                                _warrantyController.text =
                                    _pricingGuidance.warranty;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _pricingUnit,
                          decoration: const InputDecoration(
                            labelText: 'Modalidad de cobro del servicio',
                            helperText:
                                'Indica si el precio aplica por horas, metro cúbico, toneladas, metro lineal, viaje o flete.',
                          ),
                          items: _pricingUnitOptions
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _pricingUnit =
                                  value ?? 'Precio fijo por servicio';
                              if (!_requiresQuantityInput) {
                                _quantityController.text = '1';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _unitPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: _unitPriceLabel,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );
                            if (parsed == null || parsed <= 0) {
                              return 'Ingresa un valor unitario válido.';
                            }
                            return null;
                          },
                        ),
                        if (_requiresQuantityInput) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: _quantityFieldLabel,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              final parsed = double.tryParse(
                                (value ?? '').replaceAll(',', '.'),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Ingresa una cantidad válida.';
                              }
                              return null;
                            },
                          ),
                        ],
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Este servicio lleva IVA'),
                          value: _applyIva,
                          onChanged: (value) =>
                              setState(() => _applyIva = value),
                        ),
                        if (_applyIva)
                          TextFormField(
                            initialValue: _ivaRate.toStringAsFixed(0),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Porcentaje de IVA',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _ivaRate =
                                    double.tryParse(
                                      value.replaceAll(',', '.'),
                                    ) ??
                                    19;
                              });
                            },
                          ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$_pricingDescription. Base de cálculo: $_pricingBreakdown.',
                            style: const TextStyle(
                              color: Color(0xFF456356),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MoneyRow(label: 'Subtotal', value: _subtotal),
                        _MoneyRow(
                          label: _applyIva
                              ? 'IVA (${_ivaRate.toStringAsFixed(0)}%)'
                              : 'IVA no aplica',
                          value: _taxAmount,
                        ),
                        const Divider(height: 24),
                        _MoneyRow(
                          label: 'Total cotizado ($_pricingUnit)',
                          value: _totalAmount,
                          emphasized: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Observaciones finales',
                    child: TextFormField(
                      controller: _observationsController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Notas adicionales para el cliente',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Vista previa comercial',
                    child: _QuotePreviewSheet(
                      providerName: _providerName,
                      logoUrl: _logoUrl,
                      requestTitle:
                          widget.requestData['titulo']?.toString() ??
                          'Solicitud',
                      requestCity: widget.requestData['city']?.toString(),
                      summary: _summaryController.text.trim(),
                      scope: _scopeController.text.trim(),
                      deliverables: _deliverablesController.text.trim(),
                      conditions: _conditionsController.text.trim(),
                      exclusions: _exclusionsController.text.trim(),
                      timeline: _timelineController.text.trim(),
                      warranty: _warrantyController.text.trim(),
                      paymentTerms: _paymentTermsController.text.trim(),
                      observations: _observationsController.text.trim(),
                      pricingUnit: _pricingUnit,
                      pricingDescription: _pricingDescription,
                      pricingBreakdown: _pricingBreakdown,
                      unitPrice: _unitPrice,
                      serviceQuantity: _serviceQuantity,
                      quantityLabel: _quantityLabel,
                      subtotal: _subtotal,
                      taxAmount: _taxAmount,
                      totalAmount: _totalAmount,
                      appliesIva: _applyIva,
                      ivaRate: _ivaRate,
                      validityDays:
                          int.tryParse(_validityDaysController.text.trim()) ??
                          15,
                      operationEmail:
                          (_providerData['operationEmail'] as String?) ??
                          (_providerData['email'] as String?) ??
                          (_userData['email'] as String?),
                      operationPhone:
                          (_providerData['operationPhone'] as String?) ??
                          (_providerData['phoneNumber'] as String?),
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
              : const Icon(Icons.request_quote_outlined),
          label: Text(
            _saving ? 'Enviando cotización...' : 'Enviar cotización formal',
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.providerName,
    required this.logoUrl,
    required this.requestTitle,
    this.requestCity,
    required this.onEditLogo,
  });

  final String providerName;
  final String? logoUrl;
  final String requestTitle;
  final String? requestCity;
  final Future<void> Function() onEditLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            _ProviderQuoteFormPageState._brandGreen,
            _ProviderQuoteFormPageState._brandGreenSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.16),
                backgroundImage: (logoUrl != null && logoUrl!.isNotEmpty)
                    ? NetworkImage(logoUrl!)
                    : null,
                child: logoUrl == null || logoUrl!.isEmpty
                    ? const Icon(Icons.business, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cotización para $requestTitle',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (requestCity != null &&
                        requestCity!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        requestCity!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uso de logo en la cotización',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Esta cotización solo puede usar el logo corporativo de la empresa registrado en tu perfil proveedor. No se permiten imágenes promocionales, banners ni logos distintos dentro de la cotización.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onEditLogo,
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    label: const Text(
                      'Actualizar logo en perfil',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotePreviewSheet extends StatelessWidget {
  const _QuotePreviewSheet({
    required this.providerName,
    required this.logoUrl,
    required this.requestTitle,
    required this.requestCity,
    required this.summary,
    required this.scope,
    required this.deliverables,
    required this.conditions,
    required this.exclusions,
    required this.timeline,
    required this.warranty,
    required this.paymentTerms,
    required this.observations,
    required this.pricingUnit,
    required this.pricingDescription,
    required this.pricingBreakdown,
    required this.unitPrice,
    required this.serviceQuantity,
    required this.quantityLabel,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.appliesIva,
    required this.ivaRate,
    required this.validityDays,
    required this.operationEmail,
    required this.operationPhone,
  });

  final String providerName;
  final String? logoUrl;
  final String requestTitle;
  final String? requestCity;
  final String summary;
  final String scope;
  final String deliverables;
  final String conditions;
  final String exclusions;
  final String timeline;
  final String warranty;
  final String paymentTerms;
  final String observations;
  final String pricingUnit;
  final String pricingDescription;
  final String pricingBreakdown;
  final double unitPrice;
  final double serviceQuantity;
  final String quantityLabel;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final bool appliesIva;
  final double ivaRate;
  final int validityDays;
  final String? operationEmail;
  final String? operationPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8DED9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8DED9)),
                  image: logoUrl != null && logoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: logoUrl == null || logoUrl!.isEmpty
                    ? const Icon(
                        Icons.business,
                        color: _ProviderQuoteFormPageState._brandGreen,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _ProviderQuoteFormPageState._brandGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cotización comercial',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    if (operationEmail != null && operationEmail!.isNotEmpty)
                      Text(operationEmail!),
                    if (operationPhone != null && operationPhone!.isNotEmpty)
                      Text(operationPhone!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          _PreviewLine(label: 'Cliente / solicitud', value: requestTitle),
          _PreviewLine(label: 'Ciudad', value: requestCity ?? '-'),
          _PreviewLine(label: 'Vigencia', value: '$validityDays días'),
          _PreviewLine(
            label: 'Tiempo estimado',
            value: timeline.isEmpty ? '-' : timeline,
          ),
          _PreviewLine(
            label: 'Garantía',
            value: warranty.isEmpty ? '-' : warranty,
          ),
          _PreviewLine(label: 'Precio del servicio', value: pricingDescription),
          _PreviewLine(label: 'Tarifa base', value: pricingBreakdown),
          _PreviewLine(
            label: 'Cantidad facturable',
            value:
                '${_ProviderQuoteFormPageState.formatNumericValue(serviceQuantity)} $quantityLabel',
          ),
          const SizedBox(height: 18),
          _PreviewBlock(title: 'Resumen ejecutivo', value: summary),
          _PreviewBlock(title: 'Alcance', value: scope),
          if (deliverables.isNotEmpty)
            _PreviewBlock(title: 'Entregables', value: deliverables),
          if (conditions.isNotEmpty)
            _PreviewBlock(title: 'Condiciones', value: conditions),
          if (exclusions.isNotEmpty)
            _PreviewBlock(title: 'Exclusiones', value: exclusions),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E5E1)),
            ),
            child: Column(
              children: [
                _MoneyRow(label: 'Subtotal', value: subtotal),
                _MoneyRow(
                  label: appliesIva
                      ? 'IVA (${ivaRate.toStringAsFixed(0)}%)'
                      : 'IVA no aplica',
                  value: taxAmount,
                ),
                const Divider(height: 20),
                _MoneyRow(
                  label: 'Total cotizado ($pricingUnit)',
                  value: totalAmount,
                  emphasized: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PreviewBlock(
            title: 'Términos de pago',
            value: paymentTerms.isEmpty ? 'Por definir' : paymentTerms,
          ),
          if (observations.isNotEmpty)
            _PreviewBlock(title: 'Observaciones', value: observations),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEBD9A4)),
            ),
            child: const Text(
              'Esta vista previa representa una cotización formal de empresa. El logo visible corresponde únicamente al logo corporativo configurado en el perfil del proveedor.',
              style: TextStyle(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PreviewBlock extends StatelessWidget {
  const _PreviewBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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

class _QuotePlaybookItem {
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onApply;

  const _QuotePlaybookItem({
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onApply,
  });
}

class _PlaybookTile extends StatelessWidget {
  final _QuotePlaybookItem item;

  const _PlaybookTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.auto_awesome_outlined, color: Color(0xFF1E7A4B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: const TextStyle(
                    color: Color(0xFF64736C),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: item.onApply,
                    icon: const Icon(Icons.tune),
                    label: Text(item.actionLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingGuidance {
  final String recommendedUnit;
  final String suggestedRange;
  final String positioning;
  final String paymentTerms;
  final String warranty;

  const _PricingGuidance({
    required this.recommendedUnit,
    required this.suggestedRange,
    required this.positioning,
    required this.paymentTerms,
    required this.warranty,
  });
}

class _PricingGuidanceCard extends StatelessWidget {
  final _PricingGuidance guidance;
  final String currentUnit;
  final VoidCallback onApply;

  const _PricingGuidanceCard({
    required this.guidance,
    required this.currentUnit,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guidance premium de pricing',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Unidad sugerida: ${guidance.recommendedUnit}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Rango orientativo: ${guidance.suggestedRange}',
            style: const TextStyle(color: Color(0xFF64736C)),
          ),
          const SizedBox(height: 8),
          Text(
            guidance.positioning,
            style: const TextStyle(color: Color(0xFF64736C), height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: currentUnit == guidance.recommendedUnit
                    ? null
                    : onApply,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Aplicar guidance'),
              ),
              Text(
                'Pago sugerido: ${guidance.paymentTerms}',
                style: const TextStyle(color: Color(0xFF55665E), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
      fontSize: emphasized ? 18 : 15,
      color: emphasized
          ? _ProviderQuoteFormPageState._brandGreen
          : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${value.toStringAsFixed(0)} COP', style: style),
        ],
      ),
    );
  }
}
