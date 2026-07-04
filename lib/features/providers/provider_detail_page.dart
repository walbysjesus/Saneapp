import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/provider_commercial_reputation_service.dart';
import '../provider/models/provider_service_listing.dart';
import '../provider/provider_service_detail_page.dart';

class ProviderDetailPage extends StatelessWidget {
  final Map<String, dynamic> provider;

  const ProviderDetailPage({super.key, required this.provider});

  static const _brandGreen = Color(0xFF0C4F31);
  static const _surface = Color(0xFFF4F8F5);

  @override
  Widget build(BuildContext context) {
    final providerId = provider['id']?.toString() ?? '';
    final providerName = provider['name']?.toString() ?? 'Proveedor';
    final providerDescription =
        provider['description']?.toString().trim().isNotEmpty == true
        ? provider['description'].toString().trim()
        : 'Proveedor operativo en servicios ambientales con portafolio visible para contratación y cotización.';
    final contactPhone = provider['operationPhone']?.toString() ?? '';
    final contactEmail = provider['operationEmail']?.toString() ?? '';
    final categories =
        (provider['services'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final completedDocuments = _countCompletedDocuments(provider);
    final accountStatus =
        provider['accountStatus']?.toString() ?? 'pending_documents';
    final profileCompleted = provider['profileCompleted'] == true;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(providerName),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('provider_services')
            .where('providerId', isEqualTo: providerId)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          final services =
              (snapshot.data?.docs ?? const [])
                  .map(ProviderServiceListing.fromDocument)
                  .toList()
                ..sort(
                  (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000))
                      .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(2000)),
                );

          final coverages = services
              .map((service) => service.coverage.trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList();
          final minPrice = services.isEmpty
              ? 0.0
              : services
                    .map((service) => service.priceFrom)
                    .reduce((a, b) => a < b ? a : b);
          final licenseServices = services
              .where((service) => service.requiresLicense)
              .length;
          final emergencyServices = services
              .where((service) => service.emergencyAvailability)
              .length;
          final fastestResponse = services
              .map((service) => service.responseTime.trim())
              .where((item) => item.isNotEmpty)
              .cast<String?>()
              .firstWhere((item) => item != null, orElse: () => null);
          final reputation =
              ProviderCommercialReputationService.fromProviderData(
                provider,
                activeServiceCount: services.length,
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _ProviderHero(
                provider: provider,
                serviceCount: services.length,
                minPrice: minPrice,
                completedDocuments: completedDocuments,
                accountStatus: accountStatus,
                profileCompleted: profileCompleted,
                categories: categories,
                reputation: reputation,
              ),
              const SizedBox(height: 16),
              _CommercialActionPanel(
                providerId: providerId,
                providerName: providerName,
                defaultCategory: categories.isNotEmpty
                    ? categories.first
                    : provider['service']?.toString(),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Perfil comercial',
                subtitle:
                    'Cobertura, señales de confianza y datos base del proveedor para tomar una decisión rápida.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerDescription,
                      style: const TextStyle(
                        color: Color(0xFF56665D),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _SignalPill(
                          icon: Icons.verified_user_outlined,
                          label: _accountStatusLabel(
                            accountStatus,
                            profileCompleted,
                          ),
                        ),
                        _SignalPill(
                          icon: Icons.folder_outlined,
                          label: '$completedDocuments/4 soportes base cargados',
                        ),
                        _SignalPill(
                          icon: Icons.local_shipping_outlined,
                          label:
                              '${coverages.isEmpty ? 1 : coverages.length} coberturas visibles',
                        ),
                        _SignalPill(
                          icon: Icons.workspace_premium_outlined,
                          label:
                              '$licenseServices servicios con soporte regulatorio',
                        ),
                        _SignalPill(
                          icon: Icons.flash_on_outlined,
                          label: '$emergencyServices con atención prioritaria',
                        ),
                        _SignalPill(
                          icon: Icons.workspace_premium_outlined,
                          label:
                              'Tier ${reputation.tier} · ${reputation.tierLabel}',
                        ),
                        _SignalPill(
                          icon: Icons.timer_outlined,
                          label: 'SLA ${reputation.responseLabel}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;
                        final cardWidth = compact
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;
                        final metrics = [
                          _MetricData(
                            title: 'Portafolio visible',
                            value: '${services.length}',
                            hint: services.length == 1
                                ? 'servicio activo publicado'
                                : 'servicios activos publicados',
                          ),
                          _MetricData(
                            title: 'Precio desde',
                            value: services.isEmpty
                                ? 'Por definir'
                                : _formatCurrency(minPrice),
                            hint: services.isEmpty
                                ? 'sin tarifa visible todavía'
                                : 'entrada comercial del proveedor',
                          ),
                          _MetricData(
                            title: 'Tiempo de respuesta',
                            value: fastestResponse ?? 'Por confirmar',
                            hint: 'dato tomado del portafolio publicado',
                          ),
                          _MetricData(
                            title: 'Cobertura comercial',
                            value: coverages.isEmpty
                                ? (provider['city']?.toString() ?? 'Sin ciudad')
                                : coverages.first,
                            hint: coverages.length > 1
                                ? '+${coverages.length - 1} zonas adicionales'
                                : 'zona principal visible',
                          ),
                          _MetricData(
                            title: 'Score comercial',
                            value: '${reputation.formattedScore}/100',
                            hint: reputation.tierLabel,
                          ),
                          _MetricData(
                            title: 'Servicios cerrados',
                            value: '${reputation.completedServices}',
                            hint:
                                '${reputation.commercialWins} negocios ganados · ${reputation.acceptanceRate.toStringAsFixed(0)}% aceptación',
                          ),
                        ];

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: metrics
                              .map(
                                (metric) => SizedBox(
                                  width: cardWidth,
                                  child: _MetricCard(metric: metric),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    if (contactPhone.isNotEmpty || contactEmail.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ContactCard(phone: contactPhone, email: contactEmail),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Portafolio publicado',
                subtitle:
                    'Desde aquí el generador puede explorar los servicios activos del proveedor y disparar una solicitud, una cotización o una visita técnica previa.',
                child: services.isEmpty
                    ? const _EmptyPortfolioState()
                    : Column(
                        children: services
                            .map(
                              (service) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _ProviderServiceShowcaseCard(
                                  service: service,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _countCompletedDocuments(Map<String, dynamic> data) {
    const fields = [
      'rutUrl',
      'camaraComercioUrl',
      'cedulaUrl',
      'certificadoBancarioUrl',
    ];
    return fields
        .where((field) => data[field]?.toString().trim().isNotEmpty == true)
        .length;
  }

  String _accountStatusLabel(String status, bool profileCompleted) {
    final normalized = status.toLowerCase();
    if (profileCompleted ||
        normalized.contains('active') ||
        normalized.contains('approved')) {
      return 'Cuenta habilitada para operar';
    }
    if (normalized.contains('reject')) {
      return 'Cuenta con revisión pendiente';
    }
    return 'Validación comercial en curso';
  }

  static String _formatCurrency(double value) =>
      '\$${value.toStringAsFixed(0)}';
}

class _ProviderHero extends StatelessWidget {
  final Map<String, dynamic> provider;
  final int serviceCount;
  final double minPrice;
  final int completedDocuments;
  final String accountStatus;
  final bool profileCompleted;
  final List<String> categories;
  final ProviderCommercialSnapshot reputation;

  const _ProviderHero({
    required this.provider,
    required this.serviceCount,
    required this.minPrice,
    required this.completedDocuments,
    required this.accountStatus,
    required this.profileCompleted,
    required this.categories,
    required this.reputation,
  });

  @override
  Widget build(BuildContext context) {
    final name = provider['name']?.toString() ?? 'Proveedor';
    final city = provider['city']?.toString() ?? 'Cobertura por confirmar';
    final logoUrl = provider['logoUrl']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3423), Color(0xFF155939), Color(0xFF2D8A59)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                backgroundImage: logoUrl.isNotEmpty
                    ? NetworkImage(logoUrl)
                    : null,
                child: logoUrl.isEmpty
                    ? const Icon(Icons.business, color: Colors.white, size: 32)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      city,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            profileCompleted
                ? 'Perfil comercial listo para recibir solicitudes dirigidas, cotizaciones y supervisión previa desde el explorador.'
                : 'Proveedor visible en el explorador con información comercial base y portafolio publicado.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroTag(label: '$serviceCount servicios activos'),
              _HeroTag(
                label: minPrice > 0
                    ? 'Desde ${ProviderDetailPage._formatCurrency(minPrice)}'
                    : 'Tarifa por definir',
              ),
              _HeroTag(label: '$completedDocuments documentos base cargados'),
              _HeroTag(
                label:
                    'Tier ${reputation.tier} · ${reputation.formattedScore}/100',
              ),
              _HeroTag(label: 'SLA ${reputation.responseLabel}'),
              _HeroTag(
                label: categories.isEmpty
                    ? 'Sin categorías visibles'
                    : categories.first,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String label;

  const _HeroTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
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

class _CommercialActionPanel extends StatelessWidget {
  final String providerId;
  final String providerName;
  final String? defaultCategory;

  const _CommercialActionPanel({
    required this.providerId,
    required this.providerName,
    required this.defaultCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE7E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activar relación comercial',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Si aún no elegiste un servicio específico, puedes abrir una solicitud general, pedir cotización o solicitar visita técnica previa con este proveedor como objetivo.',
            style: TextStyle(color: Color(0xFF61716A), height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _openRequest(
                  context,
                  requestIntent: 'direct_service_request',
                  requestTitle: 'Solicitud comercial para $providerName',
                  requestDescription:
                      'Quiero activar un servicio con el proveedor $providerName. Necesito propuesta de alcance, disponibilidad y ruta de ejecución.',
                  notes:
                      'Solicitud general disparada desde el perfil comercial del proveedor.',
                ),
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('Solicitar servicio'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openRequest(
                  context,
                  requestIntent: 'direct_quote_request',
                  requestTitle: 'Cotización dirigida a $providerName',
                  requestDescription:
                      'Necesito una cotización comercial dirigida al proveedor $providerName para avanzar con la evaluación económica.',
                  notes:
                      'Solicitud de cotización abierta desde el perfil del proveedor.',
                ),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('Solicitar cotización'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openRequest(
                  context,
                  requestIntent: 'supervisor_request',
                  requestTitle: 'Cotización con visita técnica previa',
                  requestDescription:
                      'Antes de cotizar con $providerName, requiero una visita técnica previa de SaneApp para consolidar evidencia y alcance real.',
                  notes:
                      'Flujo premium de preinspección solicitado desde el perfil del proveedor.',
                  supervisorRequested: true,
                  supervisorType: 'prequote_diagnostic',
                ),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Cotización con visita previa'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRequest(
    BuildContext context, {
    required String requestIntent,
    required String requestTitle,
    required String requestDescription,
    required String notes,
    bool supervisorRequested = false,
    String? supervisorType,
  }) {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(
        context,
        '/register',
        arguments: const {'marketplaceIntent': 'buy'},
      );
      return;
    }
    Navigator.pushNamed(
      context,
      '/crear_solicitud',
      arguments: {
        'serviceInterest': defaultCategory,
        'requestIntent': requestIntent,
        'requestSource': 'provider_profile',
        'preferredProviderId': providerId,
        'preferredProviderName': providerName,
        'requestTitle': requestTitle,
        'requestDescription': requestDescription,
        'requestNotes': notes,
        'supervisorRequested': supervisorRequested,
        'supervisorType': supervisorType,
      },
    );
  }
}

class _ProviderServiceShowcaseCard extends StatelessWidget {
  final ProviderServiceListing service;

  const _ProviderServiceShowcaseCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE7E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service.commercialImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              child: Image.network(
                service.commercialImageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            service.shortDescription,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF5C6B64),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ProviderDetailPage._formatCurrency(service.priceFrom),
                      style: const TextStyle(
                        color: ProviderDetailPage._brandGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SignalPill(
                      icon: Icons.category_outlined,
                      label: service.categoryName,
                    ),
                    _SignalPill(
                      icon: Icons.tune_outlined,
                      label: service.subcategoryName,
                    ),
                    _SignalPill(
                      icon: Icons.location_on_outlined,
                      label: service.coverage,
                    ),
                    _SignalPill(
                      icon: Icons.schedule_outlined,
                      label: service.responseTime,
                    ),
                    if (service.requiresLicense)
                      const _SignalPill(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Soporte regulatorio',
                      ),
                    if (service.emergencyAvailability)
                      const _SignalPill(
                        icon: Icons.flash_on_outlined,
                        label: 'Atención prioritaria',
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openServiceDetail(context),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver servicio'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openRequest(
                        context,
                        requestIntent: 'direct_quote_request',
                        requestTitle: 'Cotización para ${service.title}',
                        requestDescription:
                            'Necesito una cotización para el servicio ${service.title} ofrecido por ${service.providerName}.',
                        notes:
                            'Cotización dirigida desde el perfil comercial del proveedor.',
                      ),
                      icon: const Icon(Icons.request_quote_outlined),
                      label: const Text('Cotizar este servicio'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openRequest(
                        context,
                        requestIntent: 'supervisor_request',
                        requestTitle:
                            'Cotización con visita previa para ${service.title}',
                        requestDescription:
                            'Requiero una visita técnica previa de SaneApp antes de cotizar el servicio ${service.title} con ${service.providerName}.',
                        notes:
                            'Flujo premium previo a cotización activado desde la vitrina del proveedor.',
                        supervisorRequested: true,
                        supervisorType: 'prequote_diagnostic',
                      ),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Visita previa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openServiceDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderServiceDetailPage(service: service),
      ),
    );
  }

  void _openRequest(
    BuildContext context, {
    required String requestIntent,
    required String requestTitle,
    required String requestDescription,
    required String notes,
    bool supervisorRequested = false,
    String? supervisorType,
  }) {
    Navigator.pushNamed(
      context,
      '/crear_solicitud',
      arguments: {
        'serviceInterest': service.categoryName,
        'serviceSubcategoryId': service.subcategoryId,
        'serviceSubcategoryName': service.subcategoryName,
        'requestIntent': requestIntent,
        'requestSource': 'provider_profile_service',
        'preferredProviderId': service.providerId,
        'preferredProviderName': service.providerName,
        'preferredProviderServiceId': service.id,
        'preferredProviderServiceTitle': service.title,
        'preferredProviderServicePriceType': service.priceType,
        'requestTitle': requestTitle,
        'requestDescription': requestDescription,
        'requestNotes': notes,
        'supervisorRequested': supervisorRequested,
        'supervisorType': supervisorType,
      },
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE7E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF63736C), height: 1.4),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SignalPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ProviderDetailPage._brandGreen),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String hint;

  const _MetricData({
    required this.title,
    required this.value,
    required this.hint,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.title,
            style: const TextStyle(
              color: Color(0xFF617169),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            metric.hint,
            style: const TextStyle(color: Color(0xFF72827A), height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String phone;
  final String email;

  const _ContactCard({required this.phone, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contacto visible',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Teléfono: $phone'),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Correo: $email'),
          ],
        ],
      ),
    );
  }
}

class _EmptyPortfolioState extends StatelessWidget {
  const _EmptyPortfolioState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E9E2)),
      ),
      child: const Text(
        'Este proveedor todavía no tiene servicios activos publicados. Conviene mantener la relación comercial general, pero aún no hay fichas comerciales listas para contratación directa.',
        style: TextStyle(color: Color(0xFF617169), height: 1.45),
      ),
    );
  }
}
