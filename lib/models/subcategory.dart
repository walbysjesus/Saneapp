/// Modelo de subcategorÃ­a para SaneApp
/// Compatible con Firestore y null-safety
class Subcategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool requiresLicense;
  final bool isEmergencyAvailable;
  final List<String> sectorAllowed;
  final bool isHighlighted;

  const Subcategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.requiresLicense = false,
    this.isEmergencyAvailable = false,
    this.sectorAllowed = const [],
    this.isHighlighted = false,
  });

  Subcategory copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? requiresLicense,
    bool? isEmergencyAvailable,
    List<String>? sectorAllowed,
    bool? isHighlighted,
  }) {
    return Subcategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requiresLicense: requiresLicense ?? this.requiresLicense,
      isEmergencyAvailable: isEmergencyAvailable ?? this.isEmergencyAvailable,
      sectorAllowed: sectorAllowed ?? this.sectorAllowed,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  factory Subcategory.fromMap(Map<String, dynamic> map, String documentId) {
    return Subcategory(
      id: documentId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
      requiresLicense: map['requiresLicense'] as bool? ?? false,
      isEmergencyAvailable: map['isEmergencyAvailable'] as bool? ?? false,
      sectorAllowed: (map['sectorAllowed'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isHighlighted: map['isHighlighted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'requiresLicense': requiresLicense,
      'isEmergencyAvailable': isEmergencyAvailable,
      'sectorAllowed': sectorAllowed,
      'isHighlighted': isHighlighted,
    };
  }
}

