import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, youâ€™ll need to edit this
/// file.
///
/// First, open your projectâ€™s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// projectâ€™s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @ayudaSoporte.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get ayudaSoporte;

  /// No description provided for @errorAbrirAyuda.
  ///
  /// In en, this message translates to:
  /// **'Error opening help: {error}'**
  String errorAbrirAyuda(Object error);

  /// No description provided for @irAInicio.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get irAInicio;

  /// No description provided for @inicio.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get inicio;

  /// No description provided for @verCategorias.
  ///
  /// In en, this message translates to:
  /// **'View categories'**
  String get verCategorias;

  /// No description provided for @categorias.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categorias;

  /// No description provided for @verProveedores.
  ///
  /// In en, this message translates to:
  /// **'View providers'**
  String get verProveedores;

  /// No description provided for @proveedores.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get proveedores;

  /// No description provided for @verCertificados.
  ///
  /// In en, this message translates to:
  /// **'View certificates'**
  String get verCertificados;

  /// No description provided for @certificados.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificados;

  /// No description provided for @cerrarSesion.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get cerrarSesion;

  /// No description provided for @confirmarCerrarSesion.
  ///
  /// In en, this message translates to:
  /// **'Confirm log out'**
  String get confirmarCerrarSesion;

  /// No description provided for @estasSeguroCerrarSesion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get estasSeguroCerrarSesion;

  /// No description provided for @cancelar.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelar;

  /// No description provided for @errorCerrarSesion.
  ///
  /// In en, this message translates to:
  /// **'Error logging out: {error}'**
  String errorCerrarSesion(Object error);

  /// No description provided for @errorAbrirPerfil.
  ///
  /// In en, this message translates to:
  /// **'Error opening profile: {error}'**
  String errorAbrirPerfil(Object error);

  /// No description provided for @miPerfil.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get miPerfil;

  /// No description provided for @verEditarPerfil.
  ///
  /// In en, this message translates to:
  /// **'View or edit profile'**
  String get verEditarPerfil;

  /// No description provided for @menuPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get menuPrincipal;

  /// No description provided for @usuario.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get usuario;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'User requests'**
  String get requestsTitle;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service type'**
  String get serviceType;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @quote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get details;

  /// No description provided for @sendQuote.
  ///
  /// In en, this message translates to:
  /// **'Send Quote'**
  String get sendQuote;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price (USD)'**
  String get price;

  /// No description provided for @proposalDescription.
  ///
  /// In en, this message translates to:
  /// **'Proposal description'**
  String get proposalDescription;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get attachFile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @quoteSent.
  ///
  /// In en, this message translates to:
  /// **'Quote sent'**
  String get quoteSent;

  /// No description provided for @loadingRequests.
  ///
  /// In en, this message translates to:
  /// **'Loading requests...'**
  String get loadingRequests;

  /// No description provided for @errorLoadingRequests.
  ///
  /// In en, this message translates to:
  /// **'Error loading requests'**
  String get errorLoadingRequests;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests match the selected filters'**
  String get noRequests;

  /// No description provided for @tryChangingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try changing filters or wait for new requests.'**
  String get tryChangingFilters;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @fileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully'**
  String get fileUploaded;

  /// No description provided for @fileUploadError.
  ///
  /// In en, this message translates to:
  /// **'Error uploading file'**
  String get fileUploadError;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SaneApp'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SaneApp'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Premium Plans'**
  String get plans;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose the plan that best fits your company'**
  String get choosePlan;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @corporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get corporate;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get register_invalid_email;

  /// No description provided for @register_invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get register_invalid_phone;

  /// No description provided for @register_invalid_password.
  ///
  /// In en, this message translates to:
  /// **'Invalid password (min 8 chars, uppercase, lowercase, number)'**
  String get register_invalid_password;

  /// No description provided for @register_complete_required_fields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields'**
  String get register_complete_required_fields;

  /// No description provided for @register_accept_terms_required.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and conditions'**
  String get register_accept_terms_required;

  /// No description provided for @register_select_at_least_one_service.
  ///
  /// In en, this message translates to:
  /// **'Select at least one service'**
  String get register_select_at_least_one_service;

  /// No description provided for @register_select_at_least_one_city.
  ///
  /// In en, this message translates to:
  /// **'Select at least one city'**
  String get register_select_at_least_one_city;

  /// No description provided for @register_email_exists.
  ///
  /// In en, this message translates to:
  /// **'Email is already registered'**
  String get register_email_exists;

  /// No description provided for @register_success.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Check your email.'**
  String get register_success;

  /// No description provided for @register_error_register.
  ///
  /// In en, this message translates to:
  /// **'Registration error. Please try again.'**
  String get register_error_register;

  /// No description provided for @register_title.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register_title;

  /// No description provided for @register_logo_semantics.
  ///
  /// In en, this message translates to:
  /// **'SaneApp logo'**
  String get register_logo_semantics;

  /// No description provided for @register_client_semantics.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get register_client_semantics;

  /// No description provided for @register_client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get register_client;

  /// No description provided for @register_provider_semantics.
  ///
  /// In en, this message translates to:
  /// **'Select provider'**
  String get register_provider_semantics;

  /// No description provided for @register_provider_company.
  ///
  /// In en, this message translates to:
  /// **'Provider company'**
  String get register_provider_company;

  /// No description provided for @register_name_semantics.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get register_name_semantics;

  /// No description provided for @register_name.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get register_name;

  /// No description provided for @register_name_help.
  ///
  /// In en, this message translates to:
  /// **'E.g. John Doe'**
  String get register_name_help;

  /// No description provided for @register_required.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get register_required;

  /// No description provided for @register_email_semantics.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get register_email_semantics;

  /// No description provided for @register_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get register_email;

  /// No description provided for @register_email_help.
  ///
  /// In en, this message translates to:
  /// **'E.g. user@email.com'**
  String get register_email_help;

  /// No description provided for @register_email_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Your email will be your login'**
  String get register_email_tooltip;

  /// No description provided for @register_password_semantics.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get register_password_semantics;

  /// No description provided for @register_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get register_password;

  /// No description provided for @register_password_help.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars, uppercase, lowercase, number'**
  String get register_password_help;

  /// No description provided for @register_password_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Do not share your password'**
  String get register_password_tooltip;

  /// No description provided for @register_captcha_semantics.
  ///
  /// In en, this message translates to:
  /// **'Security verification'**
  String get register_captcha_semantics;

  /// No description provided for @register_captcha_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Complete the captcha to continue'**
  String get register_captcha_placeholder;

  /// No description provided for @register_terms_title.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get register_terms_title;

  /// No description provided for @register_terms_content.
  ///
  /// In en, this message translates to:
  /// **'Here are SaneApp terms and conditions.'**
  String get register_terms_content;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @register_terms_link.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get register_terms_link;

  /// No description provided for @register_privacy_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get register_privacy_title;

  /// No description provided for @register_privacy_content.
  ///
  /// In en, this message translates to:
  /// **'Here is SaneApp privacy policy.'**
  String get register_privacy_content;

  /// No description provided for @register_privacy_link.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get register_privacy_link;

  /// No description provided for @register_loading.
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get register_loading;

  /// No description provided for @register_button.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register_button;

  /// No description provided for @underConstruction.
  ///
  /// In en, this message translates to:
  /// **'Under construction'**
  String get underConstruction;

  /// No description provided for @seleccionaCategoria.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get seleccionaCategoria;

  /// No description provided for @errorAlCargarCategorias.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories.'**
  String get errorAlCargarCategorias;

  /// No description provided for @noHayCategoriasDisponibles.
  ///
  /// In en, this message translates to:
  /// **'No categories available.'**
  String get noHayCategoriasDisponibles;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @onboarding_title1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SaneApp'**
  String get onboarding_title1;

  /// No description provided for @onboarding_desc1.
  ///
  /// In en, this message translates to:
  /// **'The B2B platform for reliable services, quotes, and business management.'**
  String get onboarding_desc1;

  /// No description provided for @onboarding_title2.
  ///
  /// In en, this message translates to:
  /// **'Request & Quote'**
  String get onboarding_title2;

  /// No description provided for @onboarding_desc2.
  ///
  /// In en, this message translates to:
  /// **'Manage requests, receive quotes, and choose the best option for your company.'**
  String get onboarding_desc2;

  /// No description provided for @onboarding_title3.
  ///
  /// In en, this message translates to:
  /// **'Trust & Traceability'**
  String get onboarding_title3;

  /// No description provided for @onboarding_desc3.
  ///
  /// In en, this message translates to:
  /// **'Verify companies, check history, and ensure legal traceability for every service.'**
  String get onboarding_desc3;

  /// No description provided for @onboarding_title4.
  ///
  /// In en, this message translates to:
  /// **'Start now!'**
  String get onboarding_title4;

  /// No description provided for @onboarding_desc4.
  ///
  /// In en, this message translates to:
  /// **'Create your account and take your business to the next level with SaneApp.'**
  String get onboarding_desc4;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

