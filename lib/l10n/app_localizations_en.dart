// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ayudaSoporte => 'Help & Support';

  @override
  String errorAbrirAyuda(Object error) {
    return 'Error opening help: $error';
  }

  @override
  String get irAInicio => 'Go to home';

  @override
  String get inicio => 'Home';

  @override
  String get verCategorias => 'View categories';

  @override
  String get categorias => 'Categories';

  @override
  String get verProveedores => 'View providers';

  @override
  String get proveedores => 'Providers';

  @override
  String get verCertificados => 'View certificates';

  @override
  String get certificados => 'Certificates';

  @override
  String get cerrarSesion => 'Log out';

  @override
  String get confirmarCerrarSesion => 'Confirm log out';

  @override
  String get estasSeguroCerrarSesion => 'Are you sure you want to log out?';

  @override
  String get cancelar => 'Cancel';

  @override
  String errorCerrarSesion(Object error) {
    return 'Error logging out: $error';
  }

  @override
  String errorAbrirPerfil(Object error) {
    return 'Error opening profile: $error';
  }

  @override
  String get miPerfil => 'My profile';

  @override
  String get verEditarPerfil => 'View or edit profile';

  @override
  String get menuPrincipal => 'Main menu';

  @override
  String get usuario => 'User';

  @override
  String get requestsTitle => 'User requests';

  @override
  String get client => 'Client';

  @override
  String get city => 'City';

  @override
  String get serviceType => 'Service type';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get notAvailable => 'N/A';

  @override
  String get quote => 'Quote';

  @override
  String get details => 'View details';

  @override
  String get sendQuote => 'Send Quote';

  @override
  String get price => 'Price (USD)';

  @override
  String get proposalDescription => 'Proposal description';

  @override
  String get requiredField => 'Required field';

  @override
  String get attachFile => 'Attach file';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get quoteSent => 'Quote sent';

  @override
  String get loadingRequests => 'Loading requests...';

  @override
  String get errorLoadingRequests => 'Error loading requests';

  @override
  String get noRequests => 'No requests match the selected filters';

  @override
  String get tryChangingFilters => 'Try changing filters or wait for new requests.';

  @override
  String get pending => 'Pending';

  @override
  String get accepted => 'Accepted';

  @override
  String get rejected => 'Rejected';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get fileUploaded => 'File uploaded successfully';

  @override
  String get fileUploadError => 'Error uploading file';

  @override
  String get appTitle => 'SaneApp';

  @override
  String get welcome => 'Welcome to SaneApp';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get plans => 'Premium Plans';

  @override
  String get choosePlan => 'Choose the plan that best fits your company';

  @override
  String get pro => 'Pro';

  @override
  String get basic => 'Basic';

  @override
  String get corporate => 'Corporate';

  @override
  String get free => 'Free';

  @override
  String get pay => 'Pay';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get logout => 'Logout';

  @override
  String get register_invalid_email => 'Invalid email address';

  @override
  String get register_invalid_phone => 'Invalid phone number';

  @override
  String get register_invalid_password => 'Invalid password (min 8 chars, uppercase, lowercase, number)';

  @override
  String get register_complete_required_fields => 'Please complete all required fields';

  @override
  String get register_accept_terms_required => 'You must accept the terms and conditions';

  @override
  String get register_select_at_least_one_service => 'Select at least one service';

  @override
  String get register_select_at_least_one_city => 'Select at least one city';

  @override
  String get register_email_exists => 'Email is already registered';

  @override
  String get register_success => 'Registration successful! Check your email.';

  @override
  String get register_error_register => 'Registration error. Please try again.';

  @override
  String get register_title => 'Register';

  @override
  String get register_logo_semantics => 'SaneApp logo';

  @override
  String get register_client_semantics => 'Select client';

  @override
  String get register_client => 'Client';

  @override
  String get register_provider_semantics => 'Select provider';

  @override
  String get register_provider_company => 'Provider company';

  @override
  String get register_name_semantics => 'Full name';

  @override
  String get register_name => 'Full name';

  @override
  String get register_name_help => 'E.g. John Doe';

  @override
  String get register_required => 'Required field';

  @override
  String get register_email_semantics => 'Email';

  @override
  String get register_email => 'Email';

  @override
  String get register_email_help => 'E.g. user@email.com';

  @override
  String get register_email_tooltip => 'Your email will be your login';

  @override
  String get register_password_semantics => 'Password';

  @override
  String get register_password => 'Password';

  @override
  String get register_password_help => 'Min 8 chars, uppercase, lowercase, number';

  @override
  String get register_password_tooltip => 'Do not share your password';

  @override
  String get register_captcha_semantics => 'Security verification';

  @override
  String get register_captcha_placeholder => 'Complete the captcha to continue';

  @override
  String get register_terms_title => 'Terms and conditions';

  @override
  String get register_terms_content => 'Here are SaneApp terms and conditions.';

  @override
  String get close => 'Close';

  @override
  String get register_terms_link => 'Terms';

  @override
  String get register_privacy_title => 'Privacy policy';

  @override
  String get register_privacy_content => 'Here is SaneApp privacy policy.';

  @override
  String get register_privacy_link => 'Privacy';

  @override
  String get register_loading => 'Registering...';

  @override
  String get register_button => 'Register';

  @override
  String get underConstruction => 'Under construction';

  @override
  String get seleccionaCategoria => 'Select a category';

  @override
  String get errorAlCargarCategorias => 'Error loading categories.';

  @override
  String get noHayCategoriasDisponibles => 'No categories available.';

  @override
  String get settings => 'Settings';

  @override
  String get settings_language => 'Language';

  @override
  String get onboarding_title1 => 'Welcome to SaneApp';

  @override
  String get onboarding_desc1 => 'The B2B platform for reliable services, quotes, and business management.';

  @override
  String get onboarding_title2 => 'Request & Quote';

  @override
  String get onboarding_desc2 => 'Manage requests, receive quotes, and choose the best option for your company.';

  @override
  String get onboarding_title3 => 'Trust & Traceability';

  @override
  String get onboarding_desc3 => 'Verify companies, check history, and ensure legal traceability for every service.';

  @override
  String get onboarding_title4 => 'Start now!';

  @override
  String get onboarding_desc4 => 'Create your account and take your business to the next level with SaneApp.';
}

