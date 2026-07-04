// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
  String get welcome => 'Bem-vindo ao SaneApp';

  @override
  String get login => 'Entrar';

  @override
  String get register => 'Registrar';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get forgotPassword => 'Esqueceu sua senha?';

  @override
  String get plans => 'Planos Premium';

  @override
  String get choosePlan => 'Escolha o plano que melhor se adapta à sua empresa';

  @override
  String get pro => 'Pro';

  @override
  String get basic => 'Básico';

  @override
  String get corporate => 'Corporativo';

  @override
  String get free => 'Grátis';

  @override
  String get pay => 'Pagar';

  @override
  String get success => 'Sucesso';

  @override
  String get error => 'Erro';

  @override
  String get logout => 'Sair';

  @override
  String get register_invalid_email => 'E-mail invÃ¡lido';

  @override
  String get register_invalid_phone => 'Telefone invÃ¡lido';

  @override
  String get register_invalid_password => 'Senha invÃ¡lida (mÃ­n. 8 caracteres, maiÃºscula, minÃºscula e nÃºmero)';

  @override
  String get register_complete_required_fields => 'Preencha todos os campos obrigatÃ³rios';

  @override
  String get register_accept_terms_required => 'VocÃª deve aceitar os termos e condiÃ§Ãµes';

  @override
  String get register_select_at_least_one_service => 'Selecione pelo menos um serviÃ§o';

  @override
  String get register_select_at_least_one_city => 'Selecione pelo menos uma cidade';

  @override
  String get register_email_exists => 'E-mail jÃ¡ cadastrado';

  @override
  String get register_success => 'Cadastro realizado com sucesso! Verifique seu e-mail.';

  @override
  String get register_error_register => 'Erro ao cadastrar. Tente novamente.';

  @override
  String get register_title => 'Cadastro';

  @override
  String get register_logo_semantics => 'Logo do SaneApp';

  @override
  String get register_client_semantics => 'Selecionar cliente';

  @override
  String get register_client => 'Cliente';

  @override
  String get register_provider_semantics => 'Selecionar fornecedora';

  @override
  String get register_provider_company => 'Empresa fornecedora';

  @override
  String get register_name_semantics => 'Nome completo';

  @override
  String get register_name => 'Nome completo';

  @override
  String get register_name_help => 'Ex: JoÃ£o Silva';

  @override
  String get register_required => 'Campo obrigatÃ³rio';

  @override
  String get register_email_semantics => 'E-mail';

  @override
  String get register_email => 'E-mail';

  @override
  String get register_email_help => 'Ex: usuario@email.com';

  @override
  String get register_email_tooltip => 'Seu e-mail serÃ¡ seu login';

  @override
  String get register_password_semantics => 'Senha';

  @override
  String get register_password => 'Senha';

  @override
  String get register_password_help => 'MÃ­n. 8 caracteres, maiÃºscula, minÃºscula e nÃºmero';

  @override
  String get register_password_tooltip => 'NÃ£o compartilhe sua senha';

  @override
  String get register_captcha_semantics => 'VerificaÃ§Ã£o de seguranÃ§a';

  @override
  String get register_captcha_placeholder => 'Complete o captcha para continuar';

  @override
  String get register_terms_title => 'Termos e condiÃ§Ãµes';

  @override
  String get register_terms_content => 'Aqui estÃ£o os termos e condiÃ§Ãµes do SaneApp.';

  @override
  String get close => 'Fechar';

  @override
  String get register_terms_link => 'Termos';

  @override
  String get register_privacy_title => 'PolÃ­tica de privacidade';

  @override
  String get register_privacy_content => 'Aqui estÃ¡ a polÃ­tica de privacidade do SaneApp.';

  @override
  String get register_privacy_link => 'Privacidade';

  @override
  String get register_loading => 'Cadastrando...';

  @override
  String get register_button => 'Cadastrar';

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

