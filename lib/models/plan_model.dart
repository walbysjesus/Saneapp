/// Modelo de planes premium y monetizaciÃ³n para SaneApp
class PlanModel {
  final String id;
  final String name;
  final double price;
  final String description;
  final bool isActive;
  final int priority; // mayor prioridad = mÃ¡s visibilidad
  final bool earlyAccess;

  PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.isActive,
    required this.priority,
    required this.earlyAccess,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map, String id) {
    return PlanModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
      priority: map['priority'] ?? 0,
      earlyAccess: map['earlyAccess'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'isActive': isActive,
      'priority': priority,
      'earlyAccess': earlyAccess,
    };
  }
}

