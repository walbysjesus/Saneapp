
/// Constantes globales de SaneApp
/// ──────────────────────────────
/// ✔ Valores inmutables
/// ✔ Usados en toda la app
/// ✔ Evita strings mágicos
/// ✔ Preparado para producción real


class AppConstants {
  AppConstants._();

  // ─────────────────────────────
  // App
  // ─────────────────────────────

  static const String appName = 'SaneApp';

  static const String appTagline =
      'Conectando contigo soluciones ambientales';

  // ─────────────────────────────
  // Rutas (navegación)
  // ─────────────────────────────

  static const String welcomeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String servicesRoute = '/services';
  static const String requestsRoute = '/requests';
  static const String profileRoute = '/profile';

  // ─────────────────────────────
  // Mensajes UI
  // ─────────────────────────────

  static const String genericError =
      'Ocurrió un error inesperado. Inténtalo nuevamente.';

  static const String noInternetMessage =
      'Sin conexión a internet. Verifica tu red.';

  static const String loadingMessage = 'Cargando...';

  // ─────────────────────────────
  // Validaciones
  // ─────────────────────────────

  static const int minPasswordLength = 8;

  static const String invalidEmailMessage =
      'Por favor ingresa un correo electrónico válido.';

  static const String passwordTooShortMessage =
      'La contraseña debe tener al menos 8 caracteres.';

  static const String passwordsDoNotMatchMessage =
      'Las contraseñas no coinciden.';

  // ─────────────────────────────
  // Servicios ambientales (categorías base)
  // ─────────────────────────────

  static const List<String> environmentalServiceCategories = [
    'Reciclaje',
    'Recolección de residuos',
    'Aceite usado',
    'Limpieza industrial',
    'Saneamiento',
    'Servicios ambientales especializados',
    'Soluciones sostenibles',
  ];

  // ─────────────────────────────
  // Formatos
  // ─────────────────────────────

  static const String dateFormat = 'dd/MM/yyyy';
}
