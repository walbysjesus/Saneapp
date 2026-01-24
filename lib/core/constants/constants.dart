
/// Constantes globales de SaneApp
/// ──────────────────────────────
/// ✔ Uso transversal en toda la app
/// ✔ Evita strings mágicos
/// ✔ Preparado para producción
/// ✔ Alineado con el negocio ambiental de SaneApp


class Constants {
  Constants._();

  // ─────────────────────────────
  // App
  // ─────────────────────────────

  static const String appName = 'SaneApp';
  static const String appSlogan =
      'Conectando contigo soluciones ambientales';

  // ─────────────────────────────
  // Rutas de navegación
  // ─────────────────────────────

  static const String welcomeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String servicesRoute = '/services';
  static const String requestsRoute = '/requests';
  static const String profileRoute = '/profile';

  // ─────────────────────────────
  // Mensajes generales
  // ─────────────────────────────

  static const String loading = 'Cargando...';
  static const String unexpectedError =
      'Ocurrió un error inesperado. Intenta nuevamente.';
  static const String noInternet =
      'No hay conexión a internet. Verifica tu red.';

  // ─────────────────────────────
  // Validaciones
  // ─────────────────────────────

  static const int minPasswordLength = 8;

  static const String invalidEmail =
      'Ingresa un correo electrónico válido.';
  static const String shortPassword =
      'La contraseña debe tener al menos 8 caracteres.';
  static const String passwordMismatch =
      'Las contraseñas no coinciden.';

  // ─────────────────────────────
  // Tipos de documentos (LatAm ready)
  // ─────────────────────────────

  static const List<String> documentTypes = [
    'Cédula de ciudadanía',
    'Cédula de extranjería',
    'Pasaporte',
    'NIT',
  ];

  // ─────────────────────────────
  // Categorías de servicios ambientales
  // ─────────────────────────────

  static const List<String> environmentalServices = [
    'Reciclaje',
    'Recolección de residuos',
    'Gestión de aceite usado',
    'Limpieza industrial',
    'Saneamiento ambiental',
    'Servicios ambientales especializados',
    'Soluciones sostenibles',
  ];

  // ─────────────────────────────
  // UI
  // ─────────────────────────────

  static const double defaultPadding = 16.0;
  static const double borderRadius = 12.0;
}