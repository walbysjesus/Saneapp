import 'package:flutter/material.dart';

// Mapeo privado de nombres de categoría a iconos Material
const Map<String, IconData> _categoryIcons = {
  'local_shipping': Icons.local_shipping,
  'oil_barrel': Icons.oil_barrel,
  'delete': Icons.delete,
  'cleaning_services': Icons.cleaning_services,
  'eco': Icons.eco,
  'construction': Icons.construction,
  'precision_manufacturing': Icons.precision_manufacturing,
  'water': Icons.water,
  'warning': Icons.warning,
  'recycling': Icons.recycling,
  'engineering': Icons.engineering,
  'foundation': Icons.foundation,
  'terrain': Icons.terrain,
  'opacity': Icons.opacity,
  'medical_services': Icons.medical_services,
  'bolt': Icons.bolt,
  'plumbing': Icons.plumbing,
  'factory': Icons.factory,
};

/// Retorna el icono correspondiente a la categoría.
/// Si el nombre es null o no existe, retorna Icons.category.
IconData getCategoryIcon(String? iconName) {
  return _categoryIcons[iconName] ?? Icons.category;
}
