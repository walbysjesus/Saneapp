import 'package:flutter/material.dart';
import 'package:saneapp_pro_nuevo/screens/subcategory_screen.dart';


class ServiceCategoryPage extends StatelessWidget {
  final String categoryId;
  const ServiceCategoryPage({required this.categoryId, super.key});

  @override
  Widget build(BuildContext context) {
    // Mock de servicios destacados con todas las categorías solicitadas
    final services = [
      ServiceCardData(
        id: 'vactor',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Servicios de limpieza con equipos vactor para alcantarillado y drenaje.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'aceites',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Gestión y recolección de aceites usados y lubricantes.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'transporte_ambiental',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Transporte especializado para residuos y materiales ambientales.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'gestion_residuos',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Gestión integral de residuos peligrosos y no peligrosos.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'limpieza_industrial',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Limpieza industrial para plantas, maquinaria y espacios productivos.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'servicios_ambientales',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Consultoría y soluciones en servicios ambientales.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'alquiler_maquinaria',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Alquiler de maquinaria pesada para obras y proyectos ambientales.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'alquiler_equipos',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Alquiler de equipos especiales para manejo de residuos y limpieza.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'manejo_aguas',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Manejo y tratamiento de aguas y efluentes industriales.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'residuos_especiales',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Gestión de residuos especiales y peligrosos.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'reciclaje_valorizacion',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Reciclaje y valorización de materiales recuperables.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'demolicion_obras',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Demolición y obras ambientales controladas.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'rcd',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Gestión de residuos de construcción y demolición (RCD).',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'remediacion_ambiental',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Remediación ambiental de suelos y cuerpos de agua.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'control_derrame',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Control y atención de derrames de sustancias peligrosas.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'residuos_hospitalarios',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Gestión de residuos hospitalarios y biológicos.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'energia_sostenible',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Soluciones en energía sostenible y renovable.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'seguridad_industrial',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Servicios de seguridad industrial y ambiental.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'saneamiento_ambiental',
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        description: 'Saneamiento ambiental para comunidades y empresas.',
        isCertified: true,
        isVerified: true,
      ),
      ServiceCardData(
        id: 'otros',
        imageUrl: 'https://images.unsplash.com/photo-1464983953574-0892a716854b',
        description: 'Otros servicios ambientales y de gestión.',
        isCertified: true,
        isVerified: true,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios destacados'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final s = services[index];
          return _ServiceMarketplaceCard(data: s, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubcategoryScreen(categoryId: categoryId),
              ),
            );
          });
        },
      ),
    );
  }
}

class ServiceCardData {
  final String id;
  final String imageUrl;
  final String description;
  final bool isCertified;
  final bool isVerified;
  const ServiceCardData({
    required this.id,
    required this.imageUrl,
    required this.description,
    required this.isCertified,
    required this.isVerified,
  });
}

class _ServiceMarketplaceCard extends StatelessWidget {
  final ServiceCardData data;
  final VoidCallback onTap;
  const _ServiceMarketplaceCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: Image.network(
                data.imageUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.description, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (data.isCertified)
                          _Badge(label: 'Certificado', color: Colors.blue),
                        if (data.isVerified)
                          _Badge(label: 'Verificado', color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

