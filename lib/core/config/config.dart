
/// Configuración central de la aplicación SaneApp
/// Archivo listo para producción
/// Aquí NO va lógica de UI ni Firebase directamente


class AppConfig {
  // ─────────────────────────────────────────────
  // Información general de la app
  // ─────────────────────────────────────────────

  static const String appName = 'SaneApp';
  static const String appVersion = '1.0.0';
  static const String environment = 'production'; 
  // production | staging | development

  // ─────────────────────────────────────────────
  // Configuración de comportamiento
  // ─────────────────────────────────────────────

  /// Tiempo máximo de espera para requests (en segundos)
  static const int networkTimeoutSeconds = 30;

  /// Activar logs internos (solo para debug)
  static const bool enableLogs = false;

  // ─────────────────────────────────────────────
  // Rutas principales (nombres lógicos)
  // ─────────────────────────────────────────────

  static const String welcomeRoute = '/welcome';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';

  // ─────────────────────────────────────────────
  // Textos globales reutilizables
  // ─────────────────────────────────────────────

  static const String welcomeMessage =
      'Conectando contigo soluciones ambientales';

  static const String appDescription =
      'Plataforma digital que conecta usuarios con proveedores de servicios ambientales certificados.';

  // ─────────────────────────────────────────────
  // Seguridad / validaciones
  // ─────────────────────────────────────────────

  /// Longitud mínima de contraseña
  static const int minPasswordLength = 6;

  /// Dominios permitidos (opcional, escalable)
  static const List<String> allowedEmailDomains = [];

  // ─────────────────────────────────────────────
  // Constructor privado
  // ─────────────────────────────────────────────

  const AppConfig._();
}
