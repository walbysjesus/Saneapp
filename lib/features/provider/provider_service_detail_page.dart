import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/sane_cached_image.dart';
import 'models/provider_service_listing.dart';
import 'provider_publication_matrix.dart';

class ProviderServiceDetailPage extends StatelessWidget {
  const ProviderServiceDetailPage({super.key, required this.service});

  final ProviderServiceListing service;

  void _openCommercialAction(
    BuildContext context,
    String route,
    Map<String, dynamic> arguments,
  ) {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(
        context,
        '/register',
        arguments: const {'marketplaceIntent': 'buy'},
      );
      return;
    }
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  Map<String, dynamic> _buildRequestArguments({
    required String requestIntent,
    required String requestTitle,
    required String requestDescription,
    required String requestNotes,
    bool supervisorRequested = false,
    String? supervisorType,
  }) {
    return {
      'serviceInterest': service.categoryName,
      'serviceSubcategoryId': service.subcategoryId,
      'serviceSubcategoryName': service.subcategoryName,
      'requestIntent': requestIntent,
      'requestSource': 'provider_marketplace',
      'preferredProviderId': service.providerId,
      'preferredProviderName': service.providerName,
      'preferredProviderServiceId': service.id,
      'preferredProviderServiceTitle': service.title,
      'preferredProviderServicePriceType': service.priceType,
      'requestTitle': requestTitle,
      'requestDescription': requestDescription,
      'requestNotes': requestNotes,
      'supervisorRequested': supervisorRequested,
      'supervisorType': supervisorType,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: Text(service.title),
        backgroundColor: const Color(0xFF0C4F31),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: service.commercialImageUrl.isNotEmpty
                ? SaneCachedImage(
                    imageUrl: service.commercialImageUrl,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      height: 220,
                      color: const Color(0xFFE7EFEA),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 72,
                        color: Color(0xFF2B8A57),
                      ),
                    ),
                    error: Container(
                      height: 220,
                      color: const Color(0xFFE7EFEA),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 72,
                        color: Color(0xFF2B8A57),
                      ),
                    ),
                  )
                : Container(
                    height: 220,
                    color: const Color(0xFFE7EFEA),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 72,
                      color: Color(0xFF2B8A57),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE7DF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  service.shortDescription,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.business_center_outlined,
                      text: service.providerName,
                    ),
                    if (service.serviceLineLabel.trim().isNotEmpty)
                      _MetaChip(
                        icon: Icons.widgets_outlined,
                        text: service.serviceLineLabel,
                      ),
                    _MetaChip(
                      icon: Icons.category_outlined,
                      text: service.categoryName,
                    ),
                    _MetaChip(
                      icon: Icons.tune_outlined,
                      text: service.subcategoryName,
                    ),
                    _MetaChip(
                      icon: Icons.public_outlined,
                      text: service.coverage,
                    ),
                    _MetaChip(
                      icon: Icons.flash_on_outlined,
                      text: service.responseTime,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Alcance técnico',
                  body: service.technicalDescription,
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Industrias atendidas',
                  body: service.industries,
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Requisitos del cliente',
                  body: service.requirements.isNotEmpty
                      ? service.requirements
                      : 'Sin requisitos adicionales registrados.',
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'Entregables',
                  body: service.deliverables.isNotEmpty
                      ? service.deliverables
                      : 'Sin entregables específicos registrados.',
                ),
                if (service.dynamicAttributes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DynamicAttributesSection(service: service),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      'Desde ${service.priceFrom.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0C4F31),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        service.priceType,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Acciones',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _openCommercialAction(
                            context,
                            '/crear_solicitud',
                            _buildRequestArguments(
                              requestIntent: 'direct_service_request',
                              requestTitle:
                                  'Solicitud directa de ${service.title}',
                              requestDescription:
                                  'Requiero el servicio "${service.title}" publicado por ${service.providerName}. Necesito validación de alcance, disponibilidad y condiciones de ejecución para avanzar con la contratación.',
                              requestNotes:
                                  'Proveedor objetivo desde marketplace: ${service.providerName}. Servicio publicado: ${service.title}.',
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('Solicitar servicio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C4F31),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openCommercialAction(
                            context,
                            '/crear_solicitud',
                            _buildRequestArguments(
                              requestIntent: 'direct_quote_request',
                              requestTitle:
                                  'Solicitud de cotización para ${service.title}',
                              requestDescription:
                                  'Solicito una cotización para el servicio "${service.title}" ofrecido por ${service.providerName}. Compartir alcance, tiempos, entregables y condiciones comerciales.',
                              requestNotes:
                                  'Cotización dirigida desde marketplace al proveedor ${service.providerName}.',
                            ),
                          );
                        },
                        icon: const Icon(Icons.request_quote_outlined),
                        label: const Text('Solicitar cotización'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openCommercialAction(
                            context,
                            '/crear_solicitud',
                            _buildRequestArguments(
                              requestIntent: 'supervisor_request',
                              requestTitle:
                                  'Cotización con visita previa para ${service.title}',
                              requestDescription:
                                  'Necesito validar en sitio la necesidad asociada al servicio "${service.title}" antes de cotizar con el proveedor ${service.providerName}.',
                              requestNotes:
                                  'Preinspección técnica de SaneApp solicitada para soportar mejor la cotización del proveedor seleccionado.',
                              supervisorRequested: true,
                              supervisorType: 'prequote_diagnostic',
                            ),
                          );
                        },
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text(
                          'Cotización con visita técnica previa',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openCommercialAction(context, '/crear_subasta', {
                            'serviceInterest': service.categoryName,
                            'requestSource': 'provider_marketplace',
                            'preferredProviderId': service.providerId,
                            'preferredProviderName': service.providerName,
                            'preferredProviderServiceId': service.id,
                            'preferredProviderServiceTitle': service.title,
                            'requestTitle': 'Subasta para ${service.title}',
                            'requestDescription':
                                'Quiero comparar propuestas para un alcance amplio relacionado con ${service.title}, manteniendo a ${service.providerName} dentro del radar comercial.',
                            'city': service.providerLocation,
                          });
                        },
                        icon: const Icon(Icons.gavel_outlined),
                        label: const Text('Abrir subasta para gran alcance'),
                      ),
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
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E7A4B)),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(color: Colors.black87, height: 1.4)),
      ],
    );
  }
}

class _DynamicAttributesSection extends StatelessWidget {
  final ProviderServiceListing service;

  const _DynamicAttributesSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final entries = service.dynamicAttributes.entries.where((entry) {
      final value = entry.value;
      if (value == null) {
        return false;
      }
      if (value is String) {
        return value.trim().isNotEmpty;
      }
      return true;
    }).toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ficha operativa del servicio',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 170,
                  child: Text(
                    marketplaceFieldLabel(
                      entry.key,
                      priceType: service.priceType,
                      serviceLineId: service.serviceLineId,
                      categoryName: service.categoryName,
                      subcategoryName: service.subcategoryName,
                    ),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value is bool
                        ? ((entry.value as bool) ? 'Si' : 'No')
                        : entry.value.toString(),
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
