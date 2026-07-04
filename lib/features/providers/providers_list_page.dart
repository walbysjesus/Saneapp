import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/analytics_service.dart';
import '../../core/widgets/sane_cached_image.dart';
import '../provider/models/provider_service_listing.dart';
import '../provider/provider_service_detail_page.dart';
import 'provider_ranking.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _cardBorder = Color(0xFFDCE7DF);

class ProvidersListPage extends StatefulWidget {
  final String subcategoryId;
  final String? subcategoryName;
  final String? categoryId;
  final String? categoryName;

  const ProvidersListPage({
    super.key,
    required this.subcategoryId,
    this.subcategoryName,
    this.categoryId,
    this.categoryName,
  });

  @override
  State<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends State<ProvidersListPage> {
  String _searchQuery = '';
  ProviderSortOption _sortOption = ProviderSortOption.relevance;
  bool _onlyEmergency = false;
  bool _onlyRequiresLicense = false;

  String get _sortLabel {
    switch (_sortOption) {
      case ProviderSortOption.relevance:
        return 'Relevancia';
      case ProviderSortOption.newest:
        return 'Más nuevos';
      case ProviderSortOption.topRated:
        return 'Mejor calificados';
      case ProviderSortOption.fastestResponse:
        return 'Respuesta rápida';
      case ProviderSortOption.priceLow:
        return 'Menor precio';
    }
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreen('providers_list_page');
  }

  CollectionReference<Map<String, dynamic>> get _servicesCollection =>
      FirebaseFirestore.instance.collection('provider_services');

  Query<Map<String, dynamic>> get _primaryQuery {
    if (widget.subcategoryId.trim().isEmpty) {
      return _servicesCollection.limit(1);
    }
    return _servicesCollection.where(
      'subcategoryId',
      isEqualTo: widget.subcategoryId,
    );
  }

  Query<Map<String, dynamic>> get _legacySubcategoryIdQuery {
    if (widget.subcategoryId.trim().isEmpty) {
      return _servicesCollection.limit(1);
    }
    return _servicesCollection.where(
      'serviceSubcategoryId',
      isEqualTo: widget.subcategoryId,
    );
  }

  Query<Map<String, dynamic>> get _subcategoryNameQuery {
    final subcategoryName = widget.subcategoryName?.trim() ?? '';
    if (subcategoryName.isEmpty) {
      return _servicesCollection.limit(1);
    }
    return _servicesCollection.where(
      'subcategoryName',
      isEqualTo: subcategoryName,
    );
  }

  String _normalize(dynamic value) =>
      (value?.toString().trim().toLowerCase() ?? '');

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  bool _matchesAnyField(
    Map<String, dynamic> service,
    List<String> keys,
    String expected,
  ) {
    if (expected.isEmpty) {
      return false;
    }
    for (final key in keys) {
      if (_normalize(service[key]) == expected) {
        return true;
      }
    }
    return false;
  }

  bool _isActiveService(Map<String, dynamic> service) {
    final isActive = service['isActive'];
    if (isActive is bool) {
      return isActive;
    }

    final status = _normalize(service['status']);
    if (status.isEmpty) {
      return true;
    }
    return status == 'active' ||
        status == 'activo' ||
        status == 'published' ||
        status == 'publicado';
  }

  bool _matchesServiceFilters(Map<String, dynamic> service) {
    final selectedSubcategoryId = _normalize(widget.subcategoryId);
    final selectedSubcategoryName = _normalize(widget.subcategoryName);
    final selectedCategoryId = _normalize(widget.categoryId);
    final selectedCategoryName = _normalize(widget.categoryName);

    final subcategoryMatchesById = _matchesAnyField(service, [
      'subcategoryId',
      'serviceSubcategoryId',
      'subcategory_id',
      'subCategoryId',
    ], selectedSubcategoryId);

    final subcategoryMatchesByName = _matchesAnyField(service, [
      'subcategoryName',
      'serviceSubcategory',
      'subCategoryName',
      'subcategoria',
    ], selectedSubcategoryName);

    final hasSubcategoryFilter =
        selectedSubcategoryId.isNotEmpty || selectedSubcategoryName.isNotEmpty;
    final subcategoryMatches =
        !hasSubcategoryFilter ||
        subcategoryMatchesById ||
        subcategoryMatchesByName;

    final categoryMatchesById = _matchesAnyField(service, [
      'categoryId',
      'serviceCategoryId',
      'category_id',
    ], selectedCategoryId);

    final categoryMatchesByName = _matchesAnyField(service, [
      'categoryName',
      'serviceCategoryName',
      'serviceCategory',
      'categoria',
    ], selectedCategoryName);

    final hasCategoryFilter =
        selectedCategoryId.isNotEmpty || selectedCategoryName.isNotEmpty;
    final categoryMatches =
        !hasCategoryFilter || categoryMatchesById || categoryMatchesByName;

    return subcategoryMatches && categoryMatches;
  }

  ProviderServiceListing _toListing(Map<String, dynamic> service) {
    final priceFrom =
        (service['priceFrom'] as num?)?.toDouble() ??
        (service['price'] as num?)?.toDouble() ??
        0;
    final imageUrl =
        (service['commercialImageUrl'] as String?)?.trim() ??
        (service['image'] as String?)?.trim() ??
        (service['providerLogoUrl'] as String?)?.trim() ??
        '';
    final responseTimeMinutes = service['responseTimeMinutes'] as num?;
    final responseTime =
        (service['responseTime'] as String?)?.trim().isNotEmpty == true
        ? (service['responseTime'] as String).trim()
        : (responseTimeMinutes != null
              ? '${responseTimeMinutes.toInt()} min'
              : 'Por confirmar');

    return ProviderServiceListing(
      id: service['id'] as String? ?? '',
      providerId: service['providerId'] as String? ?? '',
      providerName: service['providerName'] as String? ?? 'Proveedor',
      providerLocation:
          service['providerLocation'] as String? ??
          service['coverage'] as String? ??
          '',
      providerLogoUrl: (service['providerLogoUrl'] as String?)?.trim() ?? '',
      commercialImageUrl: imageUrl,
      commercialVideoUrl:
          (service['commercialVideoUrl'] as String?)?.trim() ?? '',
      serviceLineId:
          service['serviceLineId'] as String? ?? 'environmental_services',
      serviceLineLabel:
          service['serviceLineLabel'] as String? ?? 'Servicios ambientales',
      categoryId:
          service['categoryId'] as String? ??
          service['serviceCategoryId'] as String? ??
          widget.categoryId ??
          '',
      categoryName:
          service['categoryName'] as String? ??
          service['serviceCategoryName'] as String? ??
          service['serviceCategory'] as String? ??
          widget.categoryName ??
          'Categoría',
      subcategoryId:
          service['subcategoryId'] as String? ??
          service['serviceSubcategoryId'] as String? ??
          widget.subcategoryId,
      subcategoryName:
          service['subcategoryName'] as String? ??
          service['serviceSubcategoryName'] as String? ??
          service['serviceSubcategory'] as String? ??
          widget.subcategoryName ??
          'Subcategoría',
      title: service['title'] as String? ?? 'Servicio',
      shortDescription:
          service['shortDescription'] as String? ??
          service['description'] as String? ??
          'Sin descripción',
      technicalDescription:
          service['technicalDescription'] as String? ??
          service['description'] as String? ??
          service['shortDescription'] as String? ??
          'Sin descripción técnica',
      coverage: service['coverage'] as String? ?? 'Cobertura amplia',
      serviceMode: service['serviceMode'] as String? ?? 'Puntual',
      priceType: service['priceType'] as String? ?? 'Presupuesto',
      priceFrom: priceFrom,
      responseTime: responseTime,
      industries: service['industries'] as String? ?? '',
      requirements: service['requirements'] as String? ?? '',
      deliverables: service['deliverables'] as String? ?? '',
      dynamicAttributes:
          (service['dynamicAttributes'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
      emergencyAvailability:
          service['emergencyAvailability'] == true ||
          service['isEmergencyAvailable'] == true,
      requiresLicense: service['requiresLicense'] == true,
      isActive: _isActiveService(service),
      createdAt: _toDateTime(service['createdAt']),
      updatedAt: _toDateTime(service['updatedAt']),
    );
  }

  void _openServiceDetail(Map<String, dynamic> service) {
    final listing = _toListing(service);
    AnalyticsService.logEvent(
      'provider_service_detail_opened',
      params: {
        'service_id': listing.id,
        'provider_id': listing.providerId,
        'category_id': listing.categoryId,
        'subcategory_id': listing.subcategoryId,
      },
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderServiceDetailPage(service: listing),
      ),
    );
  }

  List<Map<String, dynamic>> _extractServices(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final filtered = docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where(_isActiveService)
        .where(_matchesServiceFilters)
        .where((service) {
          if (_onlyEmergency &&
              service['emergencyAvailability'] != true &&
              service['isEmergencyAvailable'] != true) {
            return false;
          }
          if (_onlyRequiresLicense && service['requiresLicense'] != true) {
            return false;
          }
          return true;
        })
        .where((service) {
          if (_searchQuery.isEmpty) return true;
          final title = (service['title'] as String?)?.toLowerCase() ?? '';
          final providerName =
              (service['providerName'] as String?)?.toLowerCase() ?? '';
          final providerBusiness =
              (service['providerBusinessName'] as String?)?.toLowerCase() ?? '';
          return title.contains(_searchQuery) ||
              providerName.contains(_searchQuery) ||
              providerBusiness.contains(_searchQuery);
        })
        .toList();

    return sortProviderServices(filtered, _sortOption);
  }

  Widget _buildListFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final services = _extractServices(docs);
    if (services.isEmpty) {
      final label = widget.subcategoryName ?? 'esta subcategoría';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay proveedores disponibles\npara $label',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _ServiceCard(
          service: service,
          onTap: () => _openServiceDetail(service),
        );
      },
    );
  }

  Widget _buildQueryState(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text('Error al cargar proveedores'),
          ],
        ),
      );
    }

    return _buildListFromDocs(snapshot.data?.docs ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores Disponibles'),
        backgroundColor: _brandGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Buscador
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedor...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final selected =
                                await showModalBottomSheet<ProviderSortOption>(
                                  context: context,
                                  builder: (context) {
                                    return SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: const Text('Relevancia'),
                                            onTap: () => Navigator.pop(
                                              context,
                                              ProviderSortOption.relevance,
                                            ),
                                          ),
                                          ListTile(
                                            title: const Text('Más nuevos'),
                                            onTap: () => Navigator.pop(
                                              context,
                                              ProviderSortOption.newest,
                                            ),
                                          ),
                                          ListTile(
                                            title: const Text(
                                              'Mejor calificados',
                                            ),
                                            onTap: () => Navigator.pop(
                                              context,
                                              ProviderSortOption.topRated,
                                            ),
                                          ),
                                          ListTile(
                                            title: const Text(
                                              'Respuesta rápida',
                                            ),
                                            onTap: () => Navigator.pop(
                                              context,
                                              ProviderSortOption
                                                  .fastestResponse,
                                            ),
                                          ),
                                          ListTile(
                                            title: const Text('Menor precio'),
                                            onTap: () => Navigator.pop(
                                              context,
                                              ProviderSortOption.priceLow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                            if (selected != null && mounted) {
                              setState(() {
                                _sortOption = selected;
                              });
                              AnalyticsService.logEvent(
                                'providers_sort_changed',
                                params: {'sort': _sortLabel},
                              );
                            }
                          },
                          icon: const Icon(Icons.sort),
                          label: Text(_sortLabel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Solo emergencia'),
                        selected: _onlyEmergency,
                        onSelected: (value) {
                          setState(() {
                            _onlyEmergency = value;
                          });
                          AnalyticsService.logEvent(
                            'providers_filter_changed',
                            params: {'filter': 'emergency', 'enabled': value},
                          );
                        },
                      ),
                      FilterChip(
                        label: const Text('Requiere licencia'),
                        selected: _onlyRequiresLicense,
                        onSelected: (value) {
                          setState(() {
                            _onlyRequiresLicense = value;
                          });
                          AnalyticsService.logEvent(
                            'providers_filter_changed',
                            params: {'filter': 'license', 'enabled': value},
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Lista de servicios
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _primaryQuery.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _legacySubcategoryIdQuery.snapshots(),
                      builder: (context, legacySnapshot) {
                        if (!legacySnapshot.hasData ||
                            legacySnapshot.data!.docs.isEmpty) {
                          return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            stream: _subcategoryNameQuery.snapshots(),
                            builder: (context, nameSnapshot) {
                              return _buildQueryState(nameSnapshot);
                            },
                          );
                        }
                        return _buildQueryState(legacySnapshot);
                      },
                    );
                  }
                  return _buildQueryState(snapshot);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final Map<String, dynamic> service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = service['title'] as String? ?? 'Sin título';
    final providerName = service['providerName'] as String? ?? 'Proveedor';
    final description =
        service['shortDescription'] as String? ??
        service['description'] as String? ??
        'Sin descripción';
    final price =
        (service['priceFrom'] as num?) ?? (service['price'] as num?) ?? 0;
    final priceType = service['priceType'] as String? ?? 'Presupuesto';
    final responseTimeMinutes = service['responseTimeMinutes'] as num?;
    final responseTimeText = (service['responseTime'] as String?)?.trim() ?? '';
    final responseTimeLabel = responseTimeText.isNotEmpty
        ? responseTimeText
        : (responseTimeMinutes != null
              ? '${responseTimeMinutes.toInt()} min'
              : 'Por confirmar');
    final coverage = service['coverage'] as String? ?? 'Cobertura amplia';
    final rating = (service['rating'] as num? ?? 0).toDouble();
    final ratingCount = service['ratingCount'] as num? ?? 0;
    final imageUrl =
        (service['commercialImageUrl'] as String?)?.trim() ??
        (service['image'] as String?)?.trim() ??
        (service['providerLogoUrl'] as String?)?.trim() ??
        '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del servicio
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: imageUrl.isNotEmpty
                  ? SaneCachedImage(
                      imageUrl: imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: const _PlaceholderImage(),
                      error: const _PlaceholderImage(),
                    )
                  : _PlaceholderImage(height: 180),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del proveedor y calificación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              providerName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Calificación
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Descripción
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Metadatos
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(
                        icon: Icons.schedule_outlined,
                        label: responseTimeLabel,
                        compact: true,
                      ),
                      _MetaPill(
                        icon: Icons.location_on_outlined,
                        label: coverage.length > 20
                            ? '${coverage.substring(0, 17)}...'
                            : coverage,
                        compact: true,
                      ),
                      if (ratingCount > 0)
                        _MetaPill(
                          icon: Icons.rate_review_outlined,
                          label: '${ratingCount.toInt()} reseñas',
                          compact: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Precio y botón
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Desde',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '\$${price.toStringAsFixed(0)} $priceType',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _brandGreen,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          'Ver detalle',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
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

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: _brandGreenSoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final double? height;

  const _PlaceholderImage({this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 180,
      color: const Color(0xFFEAF3ED),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 56, color: _brandGreenSoft),
    );
  }
}
