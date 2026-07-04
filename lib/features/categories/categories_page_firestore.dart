import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/category_icon_mapper.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _appSurface = Color(0xFFF6FAF7);

class CategoryItem {
  final String id;
  final String name;
  final String icon;
  final String description;

  CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    this.description = '',
  });

  factory CategoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return CategoryItem(
      id: doc.id,
      name: data?['name'] as String? ?? 'Sin nombre',
      icon: data?['icon'] as String? ?? 'category',
      description: data?['description'] as String? ?? '',
    );
  }
}

class SubcategoryItem {
  final String id;
  final String name;
  final String description;
  final bool requiresLicense;
  final bool isEmergencyAvailable;
  final String icon;

  SubcategoryItem({
    required this.id,
    required this.name,
    required this.description,
    this.requiresLicense = false,
    this.isEmergencyAvailable = false,
    this.icon = 'category',
  });

  factory SubcategoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return SubcategoryItem(
      id: doc.id,
      name: data?['name'] as String? ?? 'Sin nombre',
      description: data?['description'] as String? ?? '',
      requiresLicense: data?['requiresLicense'] as bool? ?? false,
      isEmergencyAvailable: data?['isEmergencyAvailable'] as bool? ?? false,
      icon: data?['icon'] as String? ?? 'category',
    );
  }
}

class CategoriesPageGallery extends StatefulWidget {
  final String? categoryId;

  const CategoriesPageGallery({super.key, this.categoryId});

  @override
  State<CategoriesPageGallery> createState() => _CategoriesPageGalleryState();
}

class _CategoriesPageGalleryState extends State<CategoriesPageGallery> {
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de Servicios'),
        backgroundColor: _brandGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('categories')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text('Error al cargar categorías'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No hay categorías disponibles'));
            }

            final categories = snapshot.data!.docs
                .map((doc) => CategoryItem.fromFirestore(doc))
                .toList();

            // Seleccionar primera categoría si no hay seleccionada
            if (selectedCategoryId == null && categories.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    selectedCategoryId = categories.first.id;
                  });
                }
              });
            }

            return Row(
              children: [
                // Panel lateral de categorías
                Container(
                  width: 120,
                  color: _appSurface,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category.id == selectedCategoryId;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryId = category.id;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : _appSurface,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? _brandGreen
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                getCategoryIcon(category.icon),
                                size: 28,
                                color: isSelected
                                    ? _brandGreen
                                    : Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? _brandGreen
                                      : Colors.grey[700],
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Panel de subcategorías
                Expanded(
                  child: selectedCategoryId != null
                      ? _buildSubcategoriesPanel(selectedCategoryId!)
                      : const Center(child: Text('Selecciona una categoría')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubcategoriesPanel(String categoryId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .collection('subcategories')
          .snapshots(),
      builder: (context, snapshot) {
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
                const Text('Error al cargar subcategorías'),
              ],
            ),
          );
        }

        final subcategories = snapshot.data!.docs
            .map((doc) => SubcategoryItem.fromFirestore(doc))
            .toList();

        if (subcategories.isEmpty) {
          return const Center(child: Text('No hay subcategorías disponibles'));
        }

        // Obtener nombre de la categoría
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('categories')
              .doc(categoryId)
              .get(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final categoryData =
                categorySnapshot.data?.data() as Map<String, dynamic>?;
            final categoryName =
                categoryData?['name'] as String? ?? 'Categoría';

            return Column(
              children: [
                // Encabezado con color corporativo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_brandGreen, _brandGreenSoft],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${subcategories.length} subcategorías disponibles',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Listado de subcategorías
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: subcategories.length,
                    itemBuilder: (context, index) {
                      final subcategory = subcategories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            subcategory.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subcategory.description,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (subcategory.requiresLicense)
                                      Chip(
                                        label: const Text(
                                          'Requiere Licencia',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: Colors.orange.shade100,
                                        labelStyle: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (subcategory.isEmergencyAvailable)
                                      Chip(
                                        label: const Text(
                                          '🚨 Emergencia 24/7',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: Colors.red.shade100,
                                        labelStyle: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: _brandGreen,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/providers-list',
                              arguments: {
                                'categoryId': categoryId,
                                'categoryName': categoryName,
                                'subcategoryId': subcategory.id,
                                'subcategoryName': subcategory.name,
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
