/// Modelo de supervisor para la colecciÃ³n 'supervisors'
class SupervisorModel {
  final String userId;
  final String nombre;
  final String telefono;
  final String zonaCobertura;
  final double calificacionPromedio;
  final int serviciosAsignadosCount;
  final bool activo;

  SupervisorModel({
    required this.userId,
    required this.nombre,
    required this.telefono,
    required this.zonaCobertura,
    this.calificacionPromedio = 0.0,
    this.serviciosAsignadosCount = 0,
    this.activo = true,
  });

  factory SupervisorModel.fromMap(Map<String, dynamic> map) {
    return SupervisorModel(
      userId: map['userId'] ?? '',
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      zonaCobertura: map['zonaCobertura'] ?? '',
      calificacionPromedio: (map['calificacionPromedio'] ?? 0).toDouble(),
      serviciosAsignadosCount: map['serviciosAsignadosCount'] ?? 0,
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombre': nombre,
      'telefono': telefono,
      'zonaCobertura': zonaCobertura,
      'calificacionPromedio': calificacionPromedio,
      'serviciosAsignadosCount': serviciosAsignadosCount,
      'activo': activo,
    };
  }
}

