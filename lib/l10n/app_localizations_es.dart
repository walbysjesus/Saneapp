// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';
// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
    @override
    String get ayudaSoporte => 'Ayuda y soporte';

    @override
    String get cerrarSesion => 'Cerrar sesión';

    @override
    String get quoteSent => 'Cotización enviada';
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get confirmarCerrarSesion => 'Confirmar cierre de sesión';

  @override
  String errorAbrirAyuda(Object error) {
    return 'Error al abrir ayuda: $error';
  }

  @override
  String get irAInicio => 'Ir a inicio';

  String get sendQuote => 'Enviar Cotización';
  String get inicio => 'Inicio';


  @override
  String get verCategorias => 'Ver categorías';

  @override
  String get categorias => 'Categorías';

  @override
  String get verProveedores => 'Ver proveedores';

  @override
  String get proveedores => 'Proveedores';

  @override
  String get verCertificados => 'Ver certificados';

  @override
  String get certificados => 'Certificados';

  @override
  String get login => 'Iniciar sesión';


  @override
  String get estasSeguroCerrarSesion => 'Â¿EstÃ¡s seguro de que deseas cerrar sesiÃ³n?';

  @override
  String get cancelar => 'Cancelar';

  @override
  String errorCerrarSesion(Object error) {
    return 'Error al cerrar sesiÃ³n: $error';
  }

  @override
  String errorAbrirPerfil(Object error) {
    return 'Error al abrir perfil: $error';
  }

  @override
  String get miPerfil => 'Mi perfil';

  @override
  String get success => 'Éxito';
  @override
  String get verEditarPerfil => 'Ver o editar perfil';

  @override
  String get menuPrincipal => 'Menú principal';

  @override
  String get usuario => 'Usuario';

  @override
  String get requestsTitle => 'Solicitudes de usuarios';

  @override
  String get client => 'Cliente';

  @override
  String get city => 'Ciudad';

  @override
  String get serviceType => 'Tipo de servicio';

  @override
  String get date => 'Fecha';

  @override
  String get status => 'Estado';

  @override
  String get notAvailable => 'N/A';

  @override
  String get quote => 'Cotizar';

  @override
  String get details => 'Ver detalles';


  @override
  String get price => 'Precio (USD)';

  @override
  String get register_name_help => 'Ej: Juan Pérez';
  @override
  String get proposalDescription => 'Descripción de la propuesta';

  @override
  String get requiredField => 'Campo requerido';

  @override
  String get attachFile => 'Adjuntar archivo';

  @override
  String get cancel => 'Cancelar';

  @override
  String get send => 'Enviar';

  @override
  String get register_password_help => 'Mínimo 8 caracteres, mayúscula, minúscula y número';

  @override
  String get loadingRequests => 'Cargando solicitudes...';

  @override
  String get errorLoadingRequests => 'Error al cargar solicitudes';

  @override
  String get noRequests => 'No hay solicitudes que cumplan los filtros seleccionados';

  @override
  String get tryChangingFilters => 'Prueba cambiando los filtros o espera nuevas solicitudes.';

  @override
  String get pending => 'Pendiente';

  @override
  String get accepted => 'Aceptada';

  @override
  String get rejected => 'Rechazada';

  @override
  String get completed => 'Completada';

  @override
  String get cancelled => 'Cancelada';

  @override
  String get fileUploaded => 'Archivo subido correctamente';

  @override
  String get fileUploadError => 'Error al subir archivo';

  @override
  String get appTitle => 'SaneApp';

  @override
  String get welcome => 'Bienvenido a SaneApp';


  @override
  String get register => 'Registrarse';

  @override
  String get email => 'Correo electrÃ³nico';

  @override
  String get password => 'ContraseÃ±a';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get plans => 'Planes Premium';

  @override
  String get choosePlan => 'Elige el plan que mejor se adapte a tu empresa';

  @override
  String get pro => 'Pro';

  @override
  String get basic => 'Básico';

  @override
  String get corporate => 'Corporativo';

  @override
  String get free => 'Gratis';

  @override
  String get pay => 'Pagar';


  @override
  String get error => 'Error';

  @override
  String get logout => 'Cerrar sesiÃ³n';

  @override
  String get register_invalid_email => 'Correo electrónico inválido';

  @override
  String get register_invalid_phone => 'Teléfono inválido';

  @override
  String get register_invalid_password => 'Contraseña inválida (mínimo 8 caracteres, mayúscula, minúscula y número)';

  @override
  String get register_complete_required_fields => 'Completa todos los campos obligatorios';

  @override
  String get register_accept_terms_required => 'Debes aceptar los términos y condiciones';

  @override
  String get register_select_at_least_one_service => 'Selecciona al menos un servicio';

  @override
  String get register_select_at_least_one_city => 'Selecciona al menos una ciudad';

  @override
  String get register_email_exists => 'El correo ya está registrado';

  @override
  String get register_success => '¡Registro exitoso! Revisa tu correo.';

  @override
  String get register_error_register => 'Error al registrar. Intenta de nuevo.';

  @override
  String get register_title => 'Registro';

  @override
  String get register_logo_semantics => 'Logo de SaneApp';

  @override
  String get register_client_semantics => 'Seleccionar cliente';

  @override
  String get register_client => 'Cliente';

  @override
  String get register_provider_semantics => 'Seleccionar proveedora';

  @override
  String get register_provider_company => 'Empresa proveedora';

  @override
  String get register_name_semantics => 'Nombre completo';

  @override
  String get register_name => 'Nombre completo';


  @override
  String get register_required => 'Campo obligatorio';

  @override
  String get register_email_semantics => 'Correo electrÃ³nico';

  @override
  String get register_email => 'Correo electrÃ³nico';

  @override
  String get register_email_help => 'Ej: usuario@correo.com';

  @override
  String get register_email_tooltip => 'Tu correo serÃ¡ tu usuario de acceso';

  @override
  String get register_password_semantics => 'Contraseña';

  @override
  String get register_password => 'Contraseña';


  @override
  String get register_password_tooltip => 'No compartas tu contraseÃ±a';

  @override
  String get register_captcha_semantics => 'Verificación de seguridad';

  @override
  String get register_captcha_placeholder => 'Completa el captcha para continuar';

  @override
  String get register_terms_title => 'Términos y condiciones';

  @override
  String get register_terms_content => 'Aquí van los términos y condiciones de SaneApp.';

  @override
  String get close => 'Cerrar';

  @override
  String get register_terms_link => 'Términos';

  @override
  String get register_privacy_title => 'Política de privacidad';

  @override
  String get register_privacy_content => 'Aquí va la política de privacidad de SaneApp.';

  @override
  String get register_privacy_link => 'Privacidad';

  @override
  String get register_loading => 'Registrando...';

  @override
  String get register_button => 'Registrarse';

  @override
  String get underConstruction => 'Pantalla en construcción';

  @override
  String get seleccionaCategoria => 'Selecciona una categoría';

  @override
  String get errorAlCargarCategorias => 'Error al cargar categorías.';

  @override
  String get noHayCategoriasDisponibles => 'No hay categorías disponibles.';

  @override
  String get settings => 'Ajustes';

  @override
  String get settings_language => 'Idioma';

  @override
  String get onboarding_title1 => 'Bienvenido a SaneApp';

  @override
  String get onboarding_desc1 => 'La plataforma B2B para servicios confiables, cotizaciones y gestión empresarial.';

  @override
  String get onboarding_title2 => 'Solicita y Cotiza';

  @override
  String get onboarding_desc2 => 'Gestiona solicitudes, recibe cotizaciones y elige la mejor opción para tu empresa.';

  @override
  String get onboarding_title3 => 'Confianza y Trazabilidad';

  @override
  String get onboarding_desc3 => 'Verifica empresas, consulta historial y asegura la trazabilidad legal de cada servicio.';

  @override
  String get onboarding_title4 => '¡Comienza ahora!';

  @override
  String get onboarding_desc4 => 'Crea tu cuenta y lleva tu empresa al siguiente nivel con SaneApp.';
}

