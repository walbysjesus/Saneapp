/// Estados avanzados y documentados para solicitudes SaneApp
/// Usar estas constantes para lÃ³gica de negocio, UI y backend
class SolicitudStatus {
  /// Solicitud creada, pendiente de acciÃ³n
  static const pendiente = "pendiente";
  /// Pendiente verificaciÃ³n inicial por supervisor
  static const pendienteVerificacion = "pendiente_verificacion";
  /// Verificado por supervisor
  static const verificado = "verificado";
  /// Servicio en ejecuciÃ³n
  static const enEjecucion = "en_ejecucion";
  /// Finalizado por proveedor
  static const finalizadoProveedor = "finalizado_proveedor";
  /// Servicio completado y cerrado
  static const completado = "completado";
  // Puedes agregar mÃ¡s segÃºn la evoluciÃ³n del flujo
}

