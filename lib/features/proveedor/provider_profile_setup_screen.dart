import 'package:flutter/material.dart';
import 'dart:async';
import '../../ui/widgets/corporate_button.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'provider_profile_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/analytics_service.dart';
// TODO: Import provider_documents_service.dart when implemented

import 'provider_profile_controller.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);

class ProviderProfileSetupScreen extends StatefulWidget {
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  const ProviderProfileSetupScreen({super.key, this.auth, this.firestore});

  @override
  State<ProviderProfileSetupScreen> createState() =>
      _ProviderProfileSetupScreenState();
}

class _ProviderProfileSetupScreenState
    extends State<ProviderProfileSetupScreen> {
  late ProviderProfileController controller;
  late TextEditingController companyNameController;
  late TextEditingController legalRepresentativeController;
  late TextEditingController nitController;
  late TextEditingController emailController;
  final List<_CategoryOption> _categoryOptions = [];
  List<MultiSelectItem<String>> categoryItems = [];
  List<MultiSelectItem<String>> subcategoryItems = [];
  bool _isLoadingCategories = false;
  bool _isLoadingSubcategories = false;
  String? _catalogError;

  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

  Future<void> _logCatalogEvent(
    String name, {
    Map<String, Object>? params,
  }) async {
    try {
      await AnalyticsService.logEvent(name, params: params);
    } catch (_) {
      // Ignorar errores de analitica para no afectar UX.
    }
  }

  @override
  void initState() {
    super.initState();
    controller = ProviderProfileController(
      auth: widget.auth,
      firestore: widget.firestore,
    );
    companyNameController = TextEditingController();
    legalRepresentativeController = TextEditingController();
    nitController = TextEditingController();
    emailController = TextEditingController();
    // Cargar datos iniciales
    controller.loadPartialProfile().then((_) {
      if (!mounted) return;
      setState(() {
        companyNameController.text = controller.companyName ?? '';
        legalRepresentativeController.text =
            controller.legalRepresentative ?? '';
        nitController.text = controller.nit ?? '';
        emailController.text = controller.email ?? '';
      });
      _loadServiceCatalog();
    });
    _loadServiceCatalog();
  }

  Future<void> _loadServiceCatalog() async {
    if (_isLoadingCategories) return;
    setState(() {
      _isLoadingCategories = true;
      _catalogError = null;
    });
    try {
      final snapshot = await _firestore.collection('categories').get();
      final options =
          snapshot.docs
              .map(
                (doc) => _CategoryOption(
                  id: doc.id,
                  name:
                      (doc.data()['name'] as String?)?.trim().isNotEmpty == true
                      ? (doc.data()['name'] as String).trim()
                      : doc.id,
                ),
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      unawaited(
        _logCatalogEvent(
          'provider_catalog_loaded',
          params: {'categories_count': options.length},
        ),
      );

      if (!mounted) return;
      _categoryOptions
        ..clear()
        ..addAll(options);

      categoryItems = _buildCategoryItems();
      final normalizedCategoryIds = _normalizeSelectedCategoryIds(
        controller.selectedCategories,
      );
      if (normalizedCategoryIds.isNotEmpty) {
        if (normalizedCategoryIds.length !=
                controller.selectedCategories.length ||
            normalizedCategoryIds.join('|') !=
                controller.selectedCategories.join('|')) {
          unawaited(
            _logCatalogEvent(
              'provider_catalog_legacy_categories_normalized',
              params: {
                'before_count': controller.selectedCategories.length,
                'after_count': normalizedCategoryIds.length,
              },
            ),
          );
        }
        controller.selectedCategories = normalizedCategoryIds;
      }
      await _loadSubcategoriesForSelection(controller.selectedCategories);
    } catch (e) {
      unawaited(
        _logCatalogEvent(
          'provider_catalog_fallback_used',
          params: {'error_type': e.runtimeType.toString()},
        ),
      );
      if (!mounted) return;
      _catalogError =
          'No se pudieron cargar las categorías. Se mostrarán las categorías base.';
      _categoryOptions
        ..clear()
        ..addAll(
          AppConstants.environmentalServiceCategories
              .map((name) => _CategoryOption(id: name, name: name))
              .toList(),
        );
      categoryItems = _buildCategoryItems();
      subcategoryItems = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  List<MultiSelectItem<String>> _buildCategoryItems() {
    return _categoryOptions
        .map((option) => MultiSelectItem<String>(option.id, option.name))
        .toList();
  }

  List<String> _normalizeSelectedCategoryIds(List<String> selectedValues) {
    if (_categoryOptions.isEmpty || selectedValues.isEmpty) {
      return selectedValues;
    }

    final byId = <String, String>{};
    final byName = <String, String>{};
    for (final option in _categoryOptions) {
      byId[option.id] = option.id;
      byName[option.name.trim().toLowerCase()] = option.id;
    }

    final normalized = <String>[];
    for (final value in selectedValues) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final resolved = byId[trimmed] ?? byName[trimmed.toLowerCase()];
      if (resolved != null && !normalized.contains(resolved)) {
        normalized.add(resolved);
      }
    }
    return normalized;
  }

  List<String> _resolveCategoryIdsForQuery(List<String> selectedValues) {
    if (_categoryOptions.isEmpty || selectedValues.isEmpty) {
      return const <String>[];
    }
    return _normalizeSelectedCategoryIds(selectedValues).toSet().toList();
  }

  Future<void> _loadSubcategoriesForSelection(List<String> categoryIds) async {
    final selectedIds = _resolveCategoryIdsForQuery(categoryIds);
    if (selectedIds.isEmpty) {
      if (!mounted) return;
      setState(() {
        subcategoryItems = [];
        controller.selectedSubcategories = [];
      });
      return;
    }

    setState(() {
      _isLoadingSubcategories = true;
    });

    try {
      final snapshots = await Future.wait(
        selectedIds.map(
          (categoryId) => _firestore
              .collection('categories')
              .doc(categoryId)
              .collection('subcategories')
              .get(),
        ),
      );

      final subcategoryMap = <String, String>{};
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final name = (data['name'] as String?)?.trim();
          subcategoryMap[doc.id] = (name != null && name.isNotEmpty)
              ? name
              : doc.id;
        }
      }

      final items =
          subcategoryMap.entries
              .map((entry) => MultiSelectItem<String>(entry.key, entry.value))
              .toList()
            ..sort(
              (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
            );

      unawaited(
        _logCatalogEvent(
          'provider_subcategories_loaded',
          params: {
            'categories_selected': selectedIds.length,
            'subcategories_count': items.length,
          },
        ),
      );

      final validSubcategoryIds = items.map((item) => item.value).toSet();

      if (!mounted) return;
      setState(() {
        subcategoryItems = items;
        controller.selectedSubcategories = controller.selectedSubcategories
            .where(validSubcategoryIds.contains)
            .toList();
      });
    } catch (_) {
      unawaited(
        _logCatalogEvent(
          'provider_subcategories_load_failed',
          params: {'categories_selected': selectedIds.length},
        ),
      );
      if (!mounted) return;
      setState(() {
        subcategoryItems = [];
        controller.selectedSubcategories = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubcategories = false;
        });
      }
    }
  }

  Future<void> _sanitizeCatalogSelectionBeforeSave() async {
    final normalizedCategoryIds = _normalizeSelectedCategoryIds(
      controller.selectedCategories,
    );

    if (normalizedCategoryIds.join('|') !=
        controller.selectedCategories.join('|')) {
      unawaited(
        _logCatalogEvent(
          'provider_catalog_categories_pruned_on_save',
          params: {
            'before_count': controller.selectedCategories.length,
            'after_count': normalizedCategoryIds.length,
          },
        ),
      );
      controller.selectedCategories = normalizedCategoryIds;
    }

    if (controller.selectedCategories.isNotEmpty &&
        controller.selectedSubcategories.isNotEmpty &&
        subcategoryItems.isEmpty) {
      await _loadSubcategoriesForSelection(controller.selectedCategories);
    }

    final validSubcategoryIds = subcategoryItems
        .map((item) => item.value)
        .toSet();
    final filteredSubcategories = controller.selectedSubcategories
        .where(validSubcategoryIds.contains)
        .toList();

    if (filteredSubcategories.length !=
        controller.selectedSubcategories.length) {
      unawaited(
        _logCatalogEvent(
          'provider_catalog_subcategories_pruned_on_save',
          params: {
            'before_count': controller.selectedSubcategories.length,
            'after_count': filteredSubcategories.length,
          },
        ),
      );
      controller.selectedSubcategories = filteredSubcategories;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Registro de proveedor'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [_brandGreen, _brandGreenSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activa tu perfil proveedor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Completa tus datos legales, categorías y alcance operativo para avanzar al módulo documental y publicar tu oferta.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: controller.isCompleted ? 1 : 0.3,
              minHeight: 8,
              backgroundColor: const Color(0xFFDCE7DF),
              valueColor: const AlwaysStoppedAnimation<Color>(_brandGreen),
            ),
            const SizedBox(height: 24),
            Text(
              'Datos básicos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            TextField(
              key: const Key('companyName'),
              decoration: InputDecoration(
                labelText: 'Nombre de empresa',
                errorText: controller.errors['companyName'],
              ),
              controller: companyNameController,
              onChanged: (v) {
                controller.companyName = v;
              },
            ),
            TextField(
              key: const Key('legalRepresentative'),
              decoration: InputDecoration(
                labelText: 'Representante legal',
                errorText: controller.errors['legalRepresentative'],
              ),
              controller: legalRepresentativeController,
              onChanged: (v) {
                controller.legalRepresentative = v;
              },
            ),
            TextField(
              key: const Key('nit'),
              decoration: InputDecoration(
                labelText: 'NIT',
                errorText: controller.errors['nit'],
              ),
              controller: nitController,
              onChanged: (v) {
                controller.nit = v;
              },
            ),
            TextField(
              key: const Key('email'),
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                errorText: controller.errors['email'],
              ),
              controller: emailController,
              onChanged: (v) {
                controller.email = v;
              },
            ),
            const SizedBox(height: 16),
            Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_catalogError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  _catalogError!,
                  style: const TextStyle(color: Color(0xFFC27A00)),
                ),
              ),
            if (_isLoadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
            Container(
              key: const Key('categoryDropdown'),
              child: MultiSelectDialogField<String>(
                items: categoryItems,
                title: const Text('Selecciona categorías'),
                selectedColor: _brandGreen,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _brandGreen, width: 1.5),
                ),
                buttonIcon: const Icon(Icons.category, color: _brandGreen),
                buttonText: const Text(
                  'Selecciona categorías',
                  style: TextStyle(
                    color: _brandGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                initialValue: controller.selectedCategories,
                onConfirm: (values) async {
                  setState(() {
                    controller.selectedCategories = values;
                    controller.selectedSubcategories = [];
                  });
                  await _loadSubcategoriesForSelection(values);
                },
                chipDisplay: MultiSelectChipDisplay(
                  onTap: (value) {
                    setState(() {
                      controller.selectedCategories.remove(value);
                      controller.selectedSubcategories = [];
                    });
                    _loadSubcategoriesForSelection(
                      controller.selectedCategories,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Subcategorías',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_isLoadingSubcategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
            if (!_isLoadingSubcategories &&
                controller.selectedCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  'Selecciona primero una o más categorías para ver sus subcategorías.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            Container(
              key: const Key('subcategoryDropdown'),
              child: MultiSelectDialogField<String>(
                items: subcategoryItems,
                title: const Text('Selecciona subcategorías'),
                selectedColor: _brandGreen,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _brandGreen, width: 1.5),
                ),
                buttonIcon: const Icon(Icons.list, color: _brandGreen),
                buttonText: const Text(
                  'Selecciona subcategorías',
                  style: TextStyle(
                    color: _brandGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                initialValue: controller.selectedSubcategories,
                onConfirm: (values) {
                  setState(() {
                    controller.selectedSubcategories = values;
                  });
                },
                chipDisplay: MultiSelectChipDisplay(
                  onTap: (value) {
                    setState(() {
                      controller.selectedSubcategories.remove(value);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            CorporateButton(
              text: 'Siguiente',
              onPressed: () async {
                await _sanitizeCatalogSelectionBeforeSave();
                final valid = controller.validateStep(0);
                setState(() {});
                if (valid) {
                  try {
                    await controller.savePartialProfile();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Datos guardados correctamente'),
                      ),
                    );
                    Navigator.pushReplacementNamed(
                      context,
                      '/termina-tu-registro',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, completa todos los campos obligatorios',
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            CorporateButton(
              text: 'Llenar después',
              onPressed: () async {
                await _sanitizeCatalogSelectionBeforeSave();
                final valid = controller.validateStep(0);
                setState(() {});
                if (valid) {
                  try {
                    await controller.savePartialProfile();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Datos guardados. Puedes completar después.',
                        ),
                      ),
                    );
                    Navigator.pushReplacementNamed(context, '/marketplace');
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, completa todos los campos obligatorios',
                      ),
                    ),
                  );
                }
              },
            ),
            if (!controller.isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Completa tu registro para acceder a todas las funciones.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String id;
  final String name;

  const _CategoryOption({required this.id, required this.name});
}
