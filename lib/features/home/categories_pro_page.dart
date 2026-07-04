import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/utils/category_icon_mapper.dart';
import '../../screens/subcategory_screen.dart';

class CategoriesProPage extends StatelessWidget {
  const CategoriesProPage({super.key});

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Categorías del marketplace'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('No fue posible cargar las categorías.'),
            );
          }
          final categories = snapshot.data?.docs ?? const [];
          if (categories.isEmpty) {
            return const Center(
              child: Text('Aún no hay categorías disponibles.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              const _HeroPanel(),
              const SizedBox(height: 18),
              ...categories.map((doc) {
                final data = doc.data();
                final categoryName =
                    (data['name'] as String?)?.trim().isNotEmpty == true
                    ? (data['name'] as String).trim()
                    : doc.id;
                final description =
                    (data['description'] as String?)?.trim() ??
                    'Línea ambiental para solicitudes y contratación especializada.';
                final iconName = data['icon'] as String?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CategoryMarketplaceCard(
                    title: categoryName,
                    description: description,
                    icon: getCategoryIcon(iconName),
                    onBrowse: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubcategoryScreen(categoryId: doc.id),
                        ),
                      );
                    },
                    onRequest: () {
                      Navigator.pushNamed(
                        context,
                        '/crear_solicitud',
                        arguments: {
                          'serviceInterest': categoryName,
                          'requestMode': 'normal',
                        },
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            label: 'Supervisión',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/home_generador');
            return;
          }
          if (index == 1) {
            return;
          }
          if (index == 2) {
            Navigator.of(
              context,
            ).pushReplacementNamed('/supervision_generador');
          }
        },
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            CategoriesProPage._brandGreen,
            CategoriesProPage._brandGreenSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explora categorías y convierte demanda en solicitudes más rápidas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Usa este catálogo para descubrir líneas de servicio, entrar a subcategorías o lanzar una solicitud ya precargada con la categoría adecuada.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _CategoryMarketplaceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onBrowse;
  final VoidCallback onRequest;

  const _CategoryMarketplaceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onBrowse,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F3ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: CategoriesProPage._brandGreenSoft),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.travel_explore_outlined),
                  label: const Text('Ver subcategorías'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CategoriesProPage._brandGreen,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Solicitar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
