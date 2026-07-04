import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/provider_commercial_reputation_service.dart';
import '../chat/transaction_chat_page.dart';
import '../shared/request_image_gallery.dart';
import '../supervision/supervision_artifacts.dart';
import 'provider_access_guard.dart';
import 'provider_quote_form_page.dart';

class ServiciosDisponiblesPage extends StatefulWidget {
  const ServiciosDisponiblesPage({super.key});

  @override
  State<ServiciosDisponiblesPage> createState() =>
      _ServiciosDisponiblesPageState();
}

class _ServiciosDisponiblesPageState extends State<ServiciosDisponiblesPage> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _ink = Color(0xFF10231A);
  static const _surface = Color(0xFFF6FAF7);

  final _searchController = TextEditingController();
  final Set<String> _quickFilters = <String>{};
  final Set<String> _expandedIds = <String>{};

  _AdvancedFilters _advancedFilters = const _AdvancedFilters();
  _SortOption _sortOption = _SortOption.recent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openQuoteForm({
    required BuildContext context,
    required String solicitudId,
    required Map<String, dynamic> requestData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final canOperate = await ensureProviderCanOperate(
      context,
      message: 'Debes completar tu registro de proveedor para poder ofertar.',
    );
    if (!canOperate || !context.mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderQuoteFormPage(
          solicitudId: solicitudId,
          requestData: requestData,
        ),
      ),
    );
  }

  Future<void> _acceptDirectRequest({
    required BuildContext context,
    required String solicitudId,
    required Map<String, dynamic> requestData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final canOperate = await ensureProviderCanOperate(
      context,
      message:
          'Debes completar tu registro de proveedor para aceptar servicios.',
    );
    if (!canOperate) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(solicitudId)
        .update({
          'selectedProveedorId': user.uid,
          'status': 'pago_confirmado',
          'selectedOfferId': null,
          'selectedAt': FieldValue.serverTimestamp(),
          'directAcceptance': true,
          'providerAcceptedAt': FieldValue.serverTimestamp(),
        });
    await ProviderCommercialReputationService.registerCommercialResponse(
      providerId: user.uid,
      requestCreatedAt: (requestData['createdAt'] as Timestamp?)?.toDate(),
      recordWin: true,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servicio aceptado y enviado a operación.')),
    );
  }

  void _openTransactionalChat({
    required BuildContext context,
    required _OpportunityViewModel item,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final profileSnapshot = (item.data['profileSnapshot'] as Map?)
        ?.cast<String, dynamic>();
    final generatorLabel =
        item.data['companyName']?.toString().trim().isNotEmpty == true
        ? item.data['companyName'].toString().trim()
        : profileSnapshot?['companyName']?.toString().trim().isNotEmpty == true
        ? profileSnapshot!['companyName'].toString().trim()
        : 'Generador';
    final providerLabel = item.preferredProviderName?.trim().isNotEmpty == true
        ? item.preferredProviderName!.trim()
        : 'Proveedor';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionChatPage(
          requestId: item.id,
          requestTitle: item.title,
          generatorId: item.data['generadorId']?.toString() ?? '',
          providerId: currentUser.uid,
          generatorLabel: generatorLabel,
          providerLabel: providerLabel,
        ),
      ),
    );
  }

  Future<void> _persistProviderPreferences({
    required String userId,
    required Set<String> favoriteIds,
    required Set<String> dismissedIds,
  }) {
    return FirebaseFirestore.instance.collection('providers').doc(userId).set({
      'savedOpportunityIds': favoriteIds.toList(),
      'dismissedOpportunityIds': dismissedIds.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _toggleFavorite({
    required String userId,
    required Set<String> favoriteIds,
    required Set<String> dismissedIds,
    required String opportunityId,
  }) async {
    final updatedFavorites = Set<String>.from(favoriteIds);
    if (!updatedFavorites.add(opportunityId)) {
      updatedFavorites.remove(opportunityId);
    }
    await _persistProviderPreferences(
      userId: userId,
      favoriteIds: updatedFavorites,
      dismissedIds: dismissedIds,
    );
  }

  Future<void> _dismissOpportunity({
    required BuildContext context,
    required String userId,
    required Set<String> favoriteIds,
    required Set<String> dismissedIds,
    required String opportunityId,
  }) async {
    final updatedDismissed = Set<String>.from(dismissedIds)..add(opportunityId);
    await _persistProviderPreferences(
      userId: userId,
      favoriteIds: favoriteIds,
      dismissedIds: updatedDismissed,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Oportunidad ocultada de tu tablero.'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            final restoredDismissed = Set<String>.from(updatedDismissed)
              ..remove(opportunityId);
            _persistProviderPreferences(
              userId: userId,
              favoriteIds: favoriteIds,
              dismissedIds: restoredDismissed,
            );
          },
        ),
      ),
    );
  }

  void _toggleExpanded(String opportunityId) {
    setState(() {
      if (!_expandedIds.add(opportunityId)) {
        _expandedIds.remove(opportunityId);
      }
    });
  }

  void _toggleQuickFilter(String filterKey) {
    setState(() {
      if (!_quickFilters.add(filterKey)) {
        _quickFilters.remove(filterKey);
      }
    });
  }

  Future<void> _openAdvancedFilters({
    required BuildContext context,
    required List<_OpportunityViewModel> opportunities,
  }) async {
    final cityOptions =
        opportunities
            .map((item) => item.city)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final result = await showModalBottomSheet<_AdvancedFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _AdvancedFilterSheet(
        initialValue: _advancedFilters,
        cityOptions: cityOptions,
      ),
    );
    if (result != null) {
      setState(() => _advancedFilters = result);
    }
  }

  List<_OpportunityViewModel> _applyFilters({
    required List<_OpportunityViewModel> opportunities,
    required Set<String> favoriteIds,
  }) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = opportunities.where((item) {
      if (query.isNotEmpty) {
        final haystack = [
          item.title,
          item.description,
          item.city,
          item.serviceLabel,
          item.preferredProviderName ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }
      if (_quickFilters.contains('favorites') &&
          !favoriteIds.contains(item.id)) {
        return false;
      }
      if (_quickFilters.contains('directed') && !item.isDirectedToProvider) {
        return false;
      }
      if (_quickFilters.contains('supervisor') && !item.hasSupervisorSupport) {
        return false;
      }
      if (_quickFilters.contains('technical') && !item.hasTechnicalSheet) {
        return false;
      }
      if (_quickFilters.contains('attachments') && !item.hasAttachments) {
        return false;
      }
      if (_quickFilters.contains('direct-accept') && !item.canAcceptDirectly) {
        return false;
      }
      if (_quickFilters.contains('urgent') && !item.isUrgent) {
        return false;
      }
      if (_advancedFilters.city != null && _advancedFilters.city != item.city) {
        return false;
      }
      if (_advancedFilters.requestIntent != null &&
          _advancedFilters.requestIntent != item.requestIntent) {
        return false;
      }
      if (_advancedFilters.urgency != null &&
          _advancedFilters.urgency != item.urgency) {
        return false;
      }
      if (_advancedFilters.frequency != null &&
          _advancedFilters.frequency != item.frequency) {
        return false;
      }
      if (_advancedFilters.minEstimatedValue != null &&
          item.estimatedValue < _advancedFilters.minEstimatedValue!) {
        return false;
      }
      if (_advancedFilters.maxEstimatedValue != null &&
          item.estimatedValue > _advancedFilters.maxEstimatedValue!) {
        return false;
      }
      if (_advancedFilters.attachmentsOnly && !item.hasAttachments) {
        return false;
      }
      if (_advancedFilters.technicalSheetOnly && !item.hasTechnicalSheet) {
        return false;
      }
      if (_advancedFilters.directedOnly && !item.isDirectedToProvider) {
        return false;
      }
      if (_advancedFilters.openOnly && item.isDirectedToProvider) {
        return false;
      }
      if (_advancedFilters.directAcceptanceOnly && !item.canAcceptDirectly) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case _SortOption.recent:
          return b.createdAt.compareTo(a.createdAt);
        case _SortOption.highValue:
          return b.estimatedValue.compareTo(a.estimatedValue);
        case _SortOption.urgent:
          final urgency = b.urgencyWeight.compareTo(a.urgencyWeight);
          if (urgency != 0) return urgency;
          return b.createdAt.compareTo(a.createdAt);
        case _SortOption.affinity:
          return b.priorityScore.compareTo(a.priorityScore);
        case _SortOption.richRequirements:
          final richness = b.richnessScore.compareTo(a.richnessScore);
          if (richness != 0) return richness;
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return filtered;
  }

  List<_OpportunityViewModel> _buildOpportunities({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> requestDocs,
    required String userId,
    required Set<String> dismissedIds,
    required _ProviderSignals providerSignals,
  }) {
    return requestDocs
        .where((doc) {
          final data = doc.data();
          final preferredProviderId =
              data['preferredProviderId']?.toString() ?? '';
          return (preferredProviderId.isEmpty ||
                  preferredProviderId == userId) &&
              !dismissedIds.contains(doc.id);
        })
        .map((doc) {
          final data = doc.data();
          final technicalSurveySheet = resolveTechnicalSurveySheet(data);
          final requestImages =
              (data['requestImageUrls'] as List?)?.cast<String>() ??
              const <String>[];
          final requestIntent = data['requestIntent']?.toString() ?? '';
          final createdAt =
              (data['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final urgency = data['serviceUrgency']?.toString() ?? 'Programado';
          final frequency = data['contractFrequency']?.toString() ?? 'Puntual';
          final serviceLabel =
              data['serviceInterest']?.toString() ??
              data['serviceCategory']?.toString() ??
              'General';
          final estimatedValue =
              (data['estimatedValue'] as num?)?.toDouble() ?? 0;
          final canAcceptDirectly =
              requestIntent == 'direct_service_request' &&
              (data['selectedProveedorId']?.toString().isEmpty ?? true);
          final hasSupervisorSupport = data['supervisorRequested'] == true;
          final isDirectedToProvider =
              (data['preferredProviderId']?.toString().isNotEmpty ?? false);
          final affinityScore = _calculateAffinityScore(
            data: data,
            userId: userId,
            providerSignals: providerSignals,
          );
          final priorityScore = _calculatePriorityScore(
            urgency: urgency,
            hasAttachments: requestImages.isNotEmpty,
            hasTechnicalSheet: technicalSurveySheet != null,
            estimatedValue: estimatedValue,
            affinityScore: affinityScore,
            canAcceptDirectly: canAcceptDirectly,
          );
          return _OpportunityViewModel(
            id: doc.id,
            data: data,
            title: data['titulo']?.toString() ?? 'Solicitud sin título',
            description: data['descripcion']?.toString() ?? '',
            city: data['city']?.toString() ?? '',
            createdAt: createdAt,
            requestIntent: requestIntent,
            preferredProviderName: data['preferredProviderName']?.toString(),
            requestImages: requestImages,
            technicalSurveySheet: technicalSurveySheet,
            serviceLabel: serviceLabel,
            urgency: urgency,
            frequency: frequency,
            estimatedValue: estimatedValue,
            canAcceptDirectly: canAcceptDirectly,
            hasSupervisorSupport: hasSupervisorSupport,
            isDirectedToProvider: isDirectedToProvider,
            supportAvailable:
                resolveSupervisorActa(data, finalActa: false) != null ||
                resolveSupervisorActa(data, finalActa: true) != null ||
                resolveSupervisorVisitLocation(data) != null ||
                resolveSupervisionLogEntries(data).isNotEmpty ||
                resolveSupervisorEvidenceUrls(data).isNotEmpty,
            affinityScore: affinityScore,
            priorityScore: priorityScore,
          );
        })
        .toList();
  }

  int _calculateAffinityScore({
    required Map<String, dynamic> data,
    required String userId,
    required _ProviderSignals providerSignals,
  }) {
    var score = 20;
    final preferredProviderId = data['preferredProviderId']?.toString() ?? '';
    final serviceInterest =
        data['serviceInterest']?.toString().toLowerCase() ?? '';
    final title = data['titulo']?.toString().toLowerCase() ?? '';
    final description = data['descripcion']?.toString().toLowerCase() ?? '';
    final coverageText = data['city']?.toString().toLowerCase() ?? '';
    final haystack = '$serviceInterest $title $description $coverageText';
    if (preferredProviderId == userId) {
      score += 30;
    }
    if (providerSignals.keywords.any(haystack.contains)) {
      score += 20;
    }
    if (providerSignals.coverages.any(coverageText.contains)) {
      score += 10;
    }
    final requestPriceType =
        data['preferredProviderServicePriceType']?.toString().toLowerCase() ??
        '';
    if (requestPriceType.isNotEmpty &&
        providerSignals.priceTypes.contains(requestPriceType)) {
      score += 10;
    }
    return score.clamp(0, 100);
  }

  int _calculatePriorityScore({
    required String urgency,
    required bool hasAttachments,
    required bool hasTechnicalSheet,
    required double estimatedValue,
    required int affinityScore,
    required bool canAcceptDirectly,
  }) {
    var score = affinityScore;
    final normalizedUrgency = urgency.toLowerCase();
    if (normalizedUrgency.contains('urgente')) {
      score += 18;
    } else if (normalizedUrgency.contains('72')) {
      score += 10;
    }
    if (hasAttachments) {
      score += 8;
    }
    if (hasTechnicalSheet) {
      score += 12;
    }
    if (canAcceptDirectly) {
      score += 10;
    }
    if (estimatedValue >= 5000000) {
      score += 12;
    } else if (estimatedValue >= 1000000) {
      score += 6;
    }
    return score.clamp(0, 100);
  }

  List<_MetricItem> _buildMetrics(List<_OpportunityViewModel> items) {
    final directed = items.where((item) => item.isDirectedToProvider).length;
    final urgent = items.where((item) => item.isUrgent).length;
    final supervisor = items.where((item) => item.hasSupervisorSupport).length;
    return [
      _MetricItem(
        label: 'Disponibles',
        value: items.length.toString(),
        icon: Icons.layers_outlined,
      ),
      _MetricItem(
        label: 'Dirigidas',
        value: directed.toString(),
        icon: Icons.ads_click_outlined,
      ),
      _MetricItem(
        label: 'Urgentes',
        value: urgent.toString(),
        icon: Icons.flash_on_outlined,
      ),
      _MetricItem(
        label: 'Con supervisor',
        value: supervisor.toString(),
        icon: Icons.verified_user_outlined,
      ),
    ];
  }

  List<String> _activeFilterLabels() {
    final labels = <String>[];
    if (_searchController.text.trim().isNotEmpty) {
      labels.add('Búsqueda: ${_searchController.text.trim()}');
    }
    if (_quickFilters.contains('favorites')) labels.add('Favoritos');
    if (_quickFilters.contains('open')) labels.add('Abiertas');
    if (_quickFilters.contains('directed')) labels.add('Dirigidas a mí');
    if (_quickFilters.contains('supervisor')) labels.add('Con supervisor');
    if (_quickFilters.contains('technical')) labels.add('Con ficha técnica');
    if (_quickFilters.contains('attachments')) labels.add('Con adjuntos');
    if (_quickFilters.contains('direct-accept')) {
      labels.add('Aceptación directa');
    }
    if (_quickFilters.contains('urgent')) labels.add('Urgentes');
    labels.addAll(_advancedFilters.labels());
    labels.add(_sortOption.label);
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Servicios disponibles'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<_SortOption>(
            tooltip: 'Ordenar oportunidades',
            initialValue: _sortOption,
            onSelected: (value) => setState(() => _sortOption = value),
            itemBuilder: (context) => _SortOption.values
                .map(
                  (option) => PopupMenuItem<_SortOption>(
                    value: option,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            icon: const Icon(Icons.swap_vert_outlined),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6FAF7), Color(0xFFEFF6F2), Color(0xFFF9F6EF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('provider_services')
              .where('providerId', isEqualTo: user.uid)
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, serviceSnapshot) {
            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final providerSignals = _ProviderSignals.fromServiceDocs(
              serviceSnapshot.data?.docs ?? const [],
            );
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('providers')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, providerSnapshot) {
                final providerData =
                    providerSnapshot.data?.data() ?? const <String, dynamic>{};
                final favoriteIds = _stringSetFrom(
                  providerData['savedOpportunityIds'],
                );
                final dismissedIds = _stringSetFrom(
                  providerData['dismissedOpportunityIds'],
                );
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('solicitudes')
                      .where('status', isEqualTo: 'activa')
                      .where('type', isEqualTo: 'normal')
                      .snapshots(),
                  builder: (context, requestSnapshot) {
                    if (requestSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (requestSnapshot.hasError) {
                      return ProviderOfflineView(
                        title: 'No fue posible cargar oportunidades',
                        message:
                            'La conexión con Firestore no está disponible en este momento. Verifica tu red para consultar solicitudes activas.',
                        onRetry: () async {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const ServiciosDisponiblesPage(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                      );
                    }
                    final opportunities = _buildOpportunities(
                      requestDocs: requestSnapshot.data?.docs ?? const [],
                      userId: user.uid,
                      dismissedIds: dismissedIds,
                      providerSignals: providerSignals,
                    );
                    final filtered = _applyFilters(
                      opportunities: opportunities,
                      favoriteIds: favoriteIds,
                    );
                    final metrics = _buildMetrics(opportunities);

                    return Stack(
                      children: [
                        Positioned(
                          top: -70,
                          right: -40,
                          child: _AuraOrb(
                            size: 180,
                            colors: const [
                              Color(0x221E7A4B),
                              Color(0x11F2E2C4),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 160,
                          left: -70,
                          child: _AuraOrb(
                            size: 200,
                            colors: const [
                              Color(0x16D6EADA),
                              Color(0x10FFFFFF),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            _TopToolbar(
                              searchController: _searchController,
                              onSearchChanged: (_) => setState(() {}),
                              onOpenAdvancedFilters: () => _openAdvancedFilters(
                                context: context,
                                opportunities: opportunities,
                              ),
                              quickFilters: _quickFilters,
                              onToggleQuickFilter: _toggleQuickFilter,
                              activeFilterLabels: _activeFilterLabels(),
                              resultCount: filtered.length,
                            ),
                            SizedBox(
                              height: 122,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  12,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) =>
                                    _MetricCard(item: metrics[index]),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemCount: metrics.length,
                              ),
                            ),
                            Expanded(
                              child: filtered.isEmpty
                                  ? _EmptyState(
                                      hasFilters:
                                          _activeFilterLabels().isNotEmpty ||
                                          dismissedIds.isNotEmpty,
                                      onResetFilters: () {
                                        setState(() {
                                          _quickFilters.clear();
                                          _advancedFilters =
                                              const _AdvancedFilters();
                                          _searchController.clear();
                                          _sortOption = _SortOption.recent;
                                        });
                                      },
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        4,
                                        16,
                                        28,
                                      ),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final item = filtered[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 18,
                                          ),
                                          child: _OpportunityCard(
                                            item: item,
                                            isFavorite: favoriteIds.contains(
                                              item.id,
                                            ),
                                            isExpanded: _expandedIds.contains(
                                              item.id,
                                            ),
                                            onToggleExpanded: () =>
                                                _toggleExpanded(item.id),
                                            onFavorite: () => _toggleFavorite(
                                              userId: user.uid,
                                              favoriteIds: favoriteIds,
                                              dismissedIds: dismissedIds,
                                              opportunityId: item.id,
                                            ),
                                            onDismiss: () =>
                                                _dismissOpportunity(
                                                  context: context,
                                                  userId: user.uid,
                                                  favoriteIds: favoriteIds,
                                                  dismissedIds: dismissedIds,
                                                  opportunityId: item.id,
                                                ),
                                            onOffer: () => _openQuoteForm(
                                              context: context,
                                              solicitudId: item.id,
                                              requestData: item.data,
                                            ),
                                            onChat: () =>
                                                _openTransactionalChat(
                                                  context: context,
                                                  item: item,
                                                ),
                                            onAccept: item.canAcceptDirectly
                                                ? () => _acceptDirectRequest(
                                                    context: context,
                                                    solicitudId: item.id,
                                                    requestData: item.data,
                                                  )
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  static Set<String> _stringSetFrom(Object? value) {
    return (value as List?)?.map((item) => item.toString()).toSet() ??
        <String>{};
  }
}

class _TopToolbar extends StatelessWidget {
  const _TopToolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenAdvancedFilters,
    required this.quickFilters,
    required this.onToggleQuickFilter,
    required this.activeFilterLabels,
    required this.resultCount,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenAdvancedFilters;
  final Set<String> quickFilters;
  final ValueChanged<String> onToggleQuickFilter;
  final List<String> activeFilterLabels;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C4F31), Color(0xFF1E7A4B), Color(0xFF2E8E5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x220C4F31),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tablero de oportunidades',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Evalúa rápido las necesidades del generador, prioriza con contexto y responde desde una sola vista.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Buscar por título, descripción, ciudad o proveedor',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: IconButton(
                    tooltip: 'Filtro pro',
                    onPressed: onOpenAdvancedFilters,
                    icon: const Icon(Icons.tune, color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickFilterChip(
                    label: 'Abiertas',
                    selected: quickFilters.contains('open'),
                    onTap: () => onToggleQuickFilter('open'),
                  ),
                  _QuickFilterChip(
                    label: 'Favoritos',
                    selected: quickFilters.contains('favorites'),
                    onTap: () => onToggleQuickFilter('favorites'),
                  ),
                  _QuickFilterChip(
                    label: 'Dirigidas a mí',
                    selected: quickFilters.contains('directed'),
                    onTap: () => onToggleQuickFilter('directed'),
                  ),
                  _QuickFilterChip(
                    label: 'Con supervisor',
                    selected: quickFilters.contains('supervisor'),
                    onTap: () => onToggleQuickFilter('supervisor'),
                  ),
                  _QuickFilterChip(
                    label: 'Con ficha técnica',
                    selected: quickFilters.contains('technical'),
                    onTap: () => onToggleQuickFilter('technical'),
                  ),
                  _QuickFilterChip(
                    label: 'Con adjuntos',
                    selected: quickFilters.contains('attachments'),
                    onTap: () => onToggleQuickFilter('attachments'),
                  ),
                  _QuickFilterChip(
                    label: 'Aceptación directa',
                    selected: quickFilters.contains('direct-accept'),
                    onTap: () => onToggleQuickFilter('direct-accept'),
                  ),
                  _QuickFilterChip(
                    label: 'Urgentes',
                    selected: quickFilters.contains('urgent'),
                    onTap: () => onToggleQuickFilter('urgent'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$resultCount oportunidades visibles',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            if (activeFilterLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeFilterLabels
                    .map(
                      (label) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white.withOpacity(0.08),
        selectedColor: const Color(0xFFF2E2C4),
        side: BorderSide(
          color: selected
              ? const Color(0x66F2E2C4)
              : Colors.white.withOpacity(0.10),
        ),
        labelStyle: TextStyle(
          color: selected ? _ServiciosDisponiblesPageState._ink : Colors.white,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: _ServiciosDisponiblesPageState._brandGreen,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3D2A), Color(0xFF1E7A4B), Color(0xFF83B89A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0C4F31),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: const TextStyle(color: Colors.white70, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.item,
    required this.isFavorite,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onFavorite,
    required this.onDismiss,
    required this.onOffer,
    required this.onChat,
    required this.onAccept,
  });

  final _OpportunityViewModel item;
  final bool isFavorite;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onFavorite;
  final VoidCallback onDismiss;
  final VoidCallback onOffer;
  final VoidCallback onChat;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF9FCFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE0E9E3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140C4F31),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            width: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  item.priorityScore >= 70
                      ? const Color(0xFF1E7A4B)
                      : const Color(0xFF7F8C84),
                  item.affinityScore >= 70
                      ? const Color(0xFFF2E2C4)
                      : const Color(0xFFDDE6E0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _ServiciosDisponiblesPageState._ink,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.serviceLabel,
                      style: const TextStyle(
                        color: Color(0xFF567063),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusTag(
                          icon: Icons.location_on_outlined,
                          label: item.city.isEmpty ? 'Sin ciudad' : item.city,
                        ),
                        _StatusTag(
                          icon: Icons.schedule_outlined,
                          label: _relativeTimeLabel(item.createdAt),
                        ),
                        _StatusTag(
                          icon: Icons.flag_outlined,
                          label: item.statusLabel,
                          emphasized: true,
                        ),
                        _StatusTag(
                          icon: Icons.auto_awesome_outlined,
                          label: 'Prioridad ${item.priorityScore}/100',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: isFavorite
                        ? 'Quitar favorito'
                        : 'Guardar oportunidad',
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite
                          ? const Color(0xFFE3A600)
                          : Colors.black54,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ocultar oportunidad',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.visibility_off_outlined),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.description,
            maxLines: isExpanded ? null : 3,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              height: 1.5,
              color: Color(0xFF2E3C34),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(label: 'Servicio', value: item.serviceLabel),
              _MetaPill(label: 'Urgencia', value: item.urgency),
              _MetaPill(label: 'Frecuencia', value: item.frequency),
              _MetaPill(
                label: 'Valor estimado',
                value: item.estimatedValue > 0
                    ? '${item.estimatedValue.toStringAsFixed(0)} COP'
                    : 'Por definir',
              ),
              _MetaPill(
                label: 'Adjuntos',
                value: item.requestImages.length.toString(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!item.isDirectedToProvider)
                const _OpportunityChip(
                  label: 'Solicitud abierta',
                  color: Color(0xFFE9F5ED),
                  foreground: _ServiciosDisponiblesPageState._brandGreen,
                ),
              if (item.isDirectedToProvider)
                const _OpportunityChip(
                  label: 'Dirigida a proveedor',
                  color: Color(0xFFFCEFD8),
                  foreground: Color(0xFF8A5A00),
                ),
              if (item.hasSupervisorSupport)
                const _OpportunityChip(
                  label: 'Con supervisor',
                  color: Color(0xFFE8F1FF),
                  foreground: Color(0xFF1E4F9A),
                ),
              if (item.hasTechnicalSheet)
                const _OpportunityChip(
                  label: 'Con ficha técnica',
                  color: Color(0xFFEAF5EE),
                  foreground: _ServiciosDisponiblesPageState._brandGreen,
                ),
              if (item.hasAttachments)
                const _OpportunityChip(
                  label: 'Con adjuntos',
                  color: Color(0xFFF3ECFF),
                  foreground: Color(0xFF5B3FA3),
                ),
              if (item.canAcceptDirectly)
                const _OpportunityChip(
                  label: 'Aceptación directa',
                  color: Color(0xFFFFF3E0),
                  foreground: Color(0xFFB86A00),
                ),
              _OpportunityChip(
                label: item.affinityScore >= 70
                    ? 'Alta afinidad'
                    : item.affinityScore >= 45
                    ? 'Afinidad media'
                    : 'Afinidad por validar',
                color: item.affinityScore >= 70
                    ? const Color(0xFFDDF2E4)
                    : const Color(0xFFF0F3F5),
                foreground: item.affinityScore >= 70
                    ? const Color(0xFF0C4F31)
                    : const Color(0xFF4F5B66),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE0E8E3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onOffer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _ServiciosDisponiblesPageState._brandGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Ofertar'),
                      ),
                    ),
                    if (onAccept != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onAccept,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                _ServiciosDisponiblesPageState._brandGreen,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            side: const BorderSide(color: Color(0xFFCEE0D3)),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Aceptar'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onChat,
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              _ServiciosDisponiblesPageState._brandGreen,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: const BorderSide(color: Color(0xFFCEE0D3)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat comercial'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggleExpanded,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E7E4)),
                        ),
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        label: Text(isExpanded ? 'Ocultar' : 'Ver detalle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF7FBF8), Color(0xFFFDFBF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDCE7DF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vista ampliada de la oportunidad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _ServiciosDisponiblesPageState._ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (item.preferredProviderName != null &&
                      item.preferredProviderName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Proveedor objetivo: ${item.preferredProviderName}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (item.requestImages.isNotEmpty) ...[
                    RequestImageGallery(
                      imageUrls: item.requestImages,
                      title: 'Imágenes compartidas por el generador',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (item.technicalSurveySheet != null) ...[
                    TechnicalSurveySheetCard(
                      sheet: item.technicalSurveySheet!,
                      providerFacing: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (item.supportAvailable) ...[
                    SupervisorSupportCard(
                      requestData: item.data,
                      providerFacing: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _DetailRow(label: 'Estado', value: item.statusLabel),
                  const _DetailRow(
                    label: 'Política de contacto',
                    value:
                        'Protegido por SaneApp. El contacto directo del generador no se libera; coordinación, facturación y trazabilidad continúan dentro de la plataforma.',
                  ),
                  _DetailRow(label: 'Urgencia', value: item.urgency),
                  _DetailRow(label: 'Frecuencia', value: item.frequency),
                  _DetailRow(
                    label: 'Valor estimado',
                    value: item.estimatedValue > 0
                        ? '${item.estimatedValue.toStringAsFixed(0)} COP'
                        : 'Por definir',
                  ),
                  _DetailRow(
                    label: 'Score de afinidad',
                    value: '${item.affinityScore}/100',
                  ),
                  _DetailRow(
                    label: 'Score de prioridad',
                    value: '${item.priorityScore}/100',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _relativeTimeLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) {
      return 'Hace instantes';
    }
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    }
    if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFEAF5EE) : const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized ? const Color(0xFFCAE0D0) : const Color(0xFFE3E9E5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: emphasized
                ? _ServiciosDisponiblesPageState._brandGreen
                : Colors.black54,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: emphasized
                  ? _ServiciosDisponiblesPageState._brandGreen
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuraOrb extends StatelessWidget {
  const _AuraOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: colors,
            center: Alignment.center,
            radius: 0.8,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E7E3)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _OpportunityChip extends StatelessWidget {
  const _OpportunityChip({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.onResetFilters});

  final bool hasFilters;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF6FBF8), Color(0xFFFFFBF3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFDCE7DF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140C4F31),
                blurRadius: 24,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: const [
                  _AuraOrb(
                    size: 120,
                    colors: [Color(0x33DCEBDE), Color(0x11F2E2C4)],
                  ),
                  Icon(
                    Icons.travel_explore_outlined,
                    size: 54,
                    color: _ServiciosDisponiblesPageState._brandGreen,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'No hay oportunidades para los criterios actuales.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _ServiciosDisponiblesPageState._ink,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasFilters
                    ? 'Ajusta filtros, búsqueda o recupera oportunidades ocultas para volver a poblar el tablero con necesidades relevantes.'
                    : 'Aún no hay solicitudes activas compatibles con tu proveedor. Cuando aparezcan, este tablero te ayudará a priorizarlas con mejor contexto.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hasFilters
                      ? 'Sugerencia: amplía ciudad, urgencia o tipo de solicitud.'
                      : 'Sugerencia: mantén tus servicios y coberturas bien afinados para mejorar el match.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ServiciosDisponiblesPageState._brandGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onResetFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ServiciosDisponiblesPageState._brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Limpiar filtros'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedFilterSheet extends StatefulWidget {
  const _AdvancedFilterSheet({
    required this.initialValue,
    required this.cityOptions,
  });

  final _AdvancedFilters initialValue;
  final List<String> cityOptions;

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late _AdvancedFilters _draft;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialValue;
    _minController = TextEditingController(
      text: _draft.minEstimatedValue?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: _draft.maxEstimatedValue?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C4F31), Color(0xFF1E7A4B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtro pro',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Filtra oportunidades por ciudad, tipo, urgencia, frecuencia, valor y soporte documental.',
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String?>(
                initialValue: _draft.city,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  ...widget.cityOptions.map(
                    (city) => DropdownMenuItem<String?>(
                      value: city,
                      child: Text(city),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _draft = _draft.copyWith(city: value)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _draft.requestIntent,
                decoration: const InputDecoration(
                  labelText: 'Tipo de solicitud',
                ),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                  DropdownMenuItem<String?>(
                    value: 'open_marketplace',
                    child: Text('Abierta'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'direct_quote_request',
                    child: Text('Dirigida de cotización'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'direct_service_request',
                    child: Text('Directa de servicio'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'supervisor_request',
                    child: Text('Dirigida con supervisor'),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _draft = _draft.copyWith(requestIntent: value),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _draft.urgency,
                decoration: const InputDecoration(labelText: 'Urgencia'),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                  DropdownMenuItem<String?>(
                    value: 'Programado',
                    child: Text('Programado'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'En menos de 72 horas',
                    child: Text('En menos de 72 horas'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Urgente 24/7',
                    child: Text('Urgente 24/7'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _draft = _draft.copyWith(urgency: value)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _draft.frequency,
                decoration: const InputDecoration(labelText: 'Frecuencia'),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                  DropdownMenuItem<String?>(
                    value: 'Puntual',
                    child: Text('Puntual'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Mensual',
                    child: Text('Mensual'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Semanal',
                    child: Text('Semanal'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Contrato permanente',
                    child: Text('Contrato permanente'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _draft = _draft.copyWith(frequency: value)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor mínimo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor máximo',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _draft.attachmentsOnly,
                title: const Text('Solo con adjuntos'),
                onChanged: (value) => setState(
                  () => _draft = _draft.copyWith(attachmentsOnly: value),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _draft.technicalSheetOnly,
                title: const Text('Solo con ficha técnica'),
                onChanged: (value) => setState(
                  () => _draft = _draft.copyWith(technicalSheetOnly: value),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _draft.directedOnly,
                title: const Text('Solo dirigidas a proveedor'),
                onChanged: (value) => setState(
                  () => _draft = _draft.copyWith(
                    directedOnly: value,
                    openOnly: value ? false : _draft.openOnly,
                  ),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _draft.openOnly,
                title: const Text('Solo abiertas'),
                onChanged: (value) => setState(
                  () => _draft = _draft.copyWith(
                    openOnly: value,
                    directedOnly: value ? false : _draft.directedOnly,
                  ),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _draft.directAcceptanceOnly,
                title: const Text('Solo con aceptación directa'),
                onChanged: (value) => setState(
                  () => _draft = _draft.copyWith(directAcceptanceOnly: value),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(const _AdvancedFilters()),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          _draft.copyWith(
                            minEstimatedValue: _parseDouble(
                              _minController.text,
                            ),
                            maxEstimatedValue: _parseDouble(
                              _maxController.text,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _ServiciosDisponiblesPageState._brandGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double? _parseDouble(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }
}

class _OpportunityViewModel {
  const _OpportunityViewModel({
    required this.id,
    required this.data,
    required this.title,
    required this.description,
    required this.city,
    required this.createdAt,
    required this.requestIntent,
    required this.preferredProviderName,
    required this.requestImages,
    required this.technicalSurveySheet,
    required this.serviceLabel,
    required this.urgency,
    required this.frequency,
    required this.estimatedValue,
    required this.canAcceptDirectly,
    required this.hasSupervisorSupport,
    required this.isDirectedToProvider,
    required this.supportAvailable,
    required this.affinityScore,
    required this.priorityScore,
  });

  final String id;
  final Map<String, dynamic> data;
  final String title;
  final String description;
  final String city;
  final DateTime createdAt;
  final String requestIntent;
  final String? preferredProviderName;
  final List<String> requestImages;
  final Map<String, dynamic>? technicalSurveySheet;
  final String serviceLabel;
  final String urgency;
  final String frequency;
  final double estimatedValue;
  final bool canAcceptDirectly;
  final bool hasSupervisorSupport;
  final bool isDirectedToProvider;
  final bool supportAvailable;
  final int affinityScore;
  final int priorityScore;

  bool get hasAttachments => requestImages.isNotEmpty;
  bool get hasTechnicalSheet => technicalSurveySheet != null;
  bool get isUrgent => urgency.toLowerCase().contains('urgente');

  int get urgencyWeight {
    final normalized = urgency.toLowerCase();
    if (normalized.contains('urgente')) return 3;
    if (normalized.contains('72')) return 2;
    return 1;
  }

  int get richnessScore {
    var score = 0;
    if (hasAttachments) score += 1;
    if (hasTechnicalSheet) score += 2;
    if (hasSupervisorSupport) score += 1;
    return score;
  }

  String get statusLabel {
    switch (requestIntent) {
      case 'direct_quote_request':
        return 'Dirigida de cotización';
      case 'supervisor_request':
        return 'Dirigida con supervisor';
      case 'direct_service_request':
        return 'Directa de servicio';
      default:
        return 'Abierta';
    }
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _ProviderSignals {
  const _ProviderSignals({
    required this.keywords,
    required this.coverages,
    required this.priceTypes,
  });

  final Set<String> keywords;
  final Set<String> coverages;
  final Set<String> priceTypes;

  factory _ProviderSignals.fromServiceDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final keywords = <String>{};
    final coverages = <String>{};
    final priceTypes = <String>{};
    for (final doc in docs) {
      final data = doc.data();
      for (final value in [
        data['title'],
        data['categoryName'],
        data['subcategoryName'],
        data['technicalDescription'],
      ]) {
        final normalized = value?.toString().trim().toLowerCase() ?? '';
        if (normalized.isNotEmpty) {
          keywords.add(normalized);
        }
      }
      final coverage = data['coverage']?.toString().trim().toLowerCase() ?? '';
      if (coverage.isNotEmpty) {
        coverages.add(coverage);
      }
      final priceType =
          data['priceType']?.toString().trim().toLowerCase() ?? '';
      if (priceType.isNotEmpty) {
        priceTypes.add(priceType);
      }
    }
    return _ProviderSignals(
      keywords: keywords,
      coverages: coverages,
      priceTypes: priceTypes,
    );
  }
}

enum _SortOption {
  recent('Más recientes'),
  highValue('Mayor valor estimado'),
  urgent('Urgencia alta primero'),
  affinity('Con mejor match primero'),
  richRequirements('Con adjuntos y ficha primero');

  const _SortOption(this.label);

  final String label;
}

class _AdvancedFilters {
  const _AdvancedFilters({
    this.city,
    this.requestIntent,
    this.urgency,
    this.frequency,
    this.minEstimatedValue,
    this.maxEstimatedValue,
    this.attachmentsOnly = false,
    this.technicalSheetOnly = false,
    this.directedOnly = false,
    this.openOnly = false,
    this.directAcceptanceOnly = false,
  });

  final String? city;
  final String? requestIntent;
  final String? urgency;
  final String? frequency;
  final double? minEstimatedValue;
  final double? maxEstimatedValue;
  final bool attachmentsOnly;
  final bool technicalSheetOnly;
  final bool directedOnly;
  final bool openOnly;
  final bool directAcceptanceOnly;

  _AdvancedFilters copyWith({
    String? city,
    String? requestIntent,
    String? urgency,
    String? frequency,
    double? minEstimatedValue,
    double? maxEstimatedValue,
    bool? attachmentsOnly,
    bool? technicalSheetOnly,
    bool? directedOnly,
    bool? openOnly,
    bool? directAcceptanceOnly,
  }) {
    return _AdvancedFilters(
      city: city,
      requestIntent: requestIntent,
      urgency: urgency,
      frequency: frequency,
      minEstimatedValue: minEstimatedValue,
      maxEstimatedValue: maxEstimatedValue,
      attachmentsOnly: attachmentsOnly ?? this.attachmentsOnly,
      technicalSheetOnly: technicalSheetOnly ?? this.technicalSheetOnly,
      directedOnly: directedOnly ?? this.directedOnly,
      openOnly: openOnly ?? this.openOnly,
      directAcceptanceOnly: directAcceptanceOnly ?? this.directAcceptanceOnly,
    );
  }

  List<String> labels() {
    final labels = <String>[];
    if (city != null) labels.add('Ciudad: $city');
    if (requestIntent != null) {
      labels.add('Tipo: ${_requestIntentLabel(requestIntent!)}');
    }
    if (urgency != null) labels.add('Urgencia: $urgency');
    if (frequency != null) labels.add('Frecuencia: $frequency');
    if (minEstimatedValue != null) {
      labels.add('Mínimo: ${minEstimatedValue!.toStringAsFixed(0)} COP');
    }
    if (maxEstimatedValue != null) {
      labels.add('Máximo: ${maxEstimatedValue!.toStringAsFixed(0)} COP');
    }
    if (attachmentsOnly) labels.add('Solo con adjuntos');
    if (technicalSheetOnly) labels.add('Solo con ficha técnica');
    if (directedOnly) labels.add('Solo dirigidas');
    if (openOnly) labels.add('Solo abiertas');
    if (directAcceptanceOnly) labels.add('Solo aceptación directa');
    return labels;
  }

  static String _requestIntentLabel(String value) {
    switch (value) {
      case 'direct_quote_request':
        return 'Dirigida de cotización';
      case 'direct_service_request':
        return 'Directa de servicio';
      case 'supervisor_request':
        return 'Con supervisor';
      default:
        return 'Abierta';
    }
  }
}
