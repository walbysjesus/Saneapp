import 'dart:async';

// ...existing code...
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controller for managing provider registration wizard state, validation, and Firestore integration.
class ProviderProfileController extends ChangeNotifier {
  // Setter para subcategorías seleccionadas
  void setSelectedSubcategories(List<String> value) {
    selectedSubcategories = value;
    notifyListeners();
  }

  // Categorías seleccionadas (IDs técnicos)
  List<String> selectedCategories = [];
  // Subcategorías seleccionadas (IDs técnicos)
  List<String> selectedSubcategories = [];

  /// ValidaciÃ³n cruzada y consistencia antes de guardar
  bool validateConsistency() {
    // Ejemplo: email y billingEmail deben ser distintos
    if (email != null && billingEmail != null && email == billingEmail) {
      errors['billingEmail'] =
          'El correo de facturación debe ser diferente al correo principal.';
      return false;
    }
    // Ejemplo: CLABE y cuenta bancaria no deben ser iguales
    if (clabe != null && bankAccount != null && clabe == bankAccount) {
      errors['clabe'] = 'La CLABE debe ser diferente a la cuenta bancaria.';
      return false;
    }
    return true;
  }

  // Recupera el perfil parcial del proveedor
  /// Recupera el perfil parcial del proveedor solo si el usuario estÃ¡ autenticado
  Future<void> loadProfile() async {
    setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
        final doc = await _firestore
          .collection('providers')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      // Solo el usuario autenticado puede editar su perfil
      companyName = data['companyName'];
      legalRepresentative = data['legalRepresentative'];
      nit = data['nit'];
      businessType = data['businessType'];
      legalAddress = data['legalAddress'];
      phoneNumber = data['phoneNumber'];
      email = data['email'];
      operationAddress = data['operationAddress'];
      operationPhone = data['operationPhone'];
      operationEmail = data['operationEmail'];
      // Cargar categorías seleccionadas
      if (data['selectedCategories'] is List) {
        selectedCategories = List<String>.from(data['selectedCategories']);
      } else {
        selectedCategories = [];
      }
      // Cargar subcategorías seleccionadas
      if (data['selectedSubcategories'] is List) {
        selectedSubcategories = List<String>.from(
          data['selectedSubcategories'],
        );
      } else {
        selectedSubcategories = [];
      }
      serviceArea = data['serviceArea'];
      serviceHours = data['serviceHours'];
      tier = data['tier'];
      bankName = data['bankName'];
      bankAccount = data['bankAccount'];
      clabe = data['clabe'];
      billingEmail = data['billingEmail'];
      paymentTerms = data['paymentTerms'];
      actaConstitutivaUrl = data['actaConstitutivaUrl'];
      comprobanteDomicilioUrl = data['comprobanteDomicilioUrl'];
      identificacionOficialUrl = data['identificacionOficialUrl'];
      cedulaFiscalUrl = data['cedulaFiscalUrl'];
      contratoFirmadoUrl = data['contratoFirmadoUrl'];
      termsAccepted = data['termsAccepted'] ?? false;
      isCompleted = data['profileCompleted'] ?? false;
      notifyListeners();
    } catch (e) {
      // Log de acceso denegado o error
      debugPrint('Error de seguridad: $e');
    } finally {
      setLoading(false);
    }
  }

  // Guardado parcial automático
  /// Guardado parcial automático solo si el usuario está autenticado
  Future<void> savePartialProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final data = {
      'companyName': companyName,
      'legalRepresentative': legalRepresentative,
      'nit': nit,
      'businessType': businessType,
      'legalAddress': legalAddress,
      'phoneNumber': phoneNumber,
      'email': email,
      'operationAddress': operationAddress,
      'operationPhone': operationPhone,
      'operationEmail': operationEmail,
      'selectedCategories': selectedCategories,
      'selectedSubcategories': selectedSubcategories,
      'serviceArea': serviceArea,
      'serviceHours': serviceHours,
      'tier': tier,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'clabe': clabe,
      'billingEmail': billingEmail,
      'paymentTerms': paymentTerms,
      'actaConstitutivaUrl': actaConstitutivaUrl,
      'comprobanteDomicilioUrl': comprobanteDomicilioUrl,
      'identificacionOficialUrl': identificacionOficialUrl,
      'cedulaFiscalUrl': cedulaFiscalUrl,
      'contratoFirmadoUrl': contratoFirmadoUrl,
      'termsAccepted': termsAccepted,
      'profileCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Mejor práctica: nunca guardar datos sensibles en texto plano
    await _firestore
      .collection('providers')
      .doc(user.uid)
      .set(data, SetOptions(merge: true))
      .timeout(const Duration(seconds: 10));
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
          'profileCompleted': false,
          'status': 'pending_documents',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 10));
  }

  // Cargar progreso parcial del perfil
  Future<void> loadPartialProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
        final doc = await _firestore
          .collection('providers')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (!doc.exists) return;
      final data = doc.data() ?? {};
      companyName = data['companyName'];
      legalRepresentative = data['legalRepresentative'];
      nit = data['nit'];
      businessType = data['businessType'];
      legalAddress = data['legalAddress'];
      phoneNumber = data['phoneNumber'];
      email = data['email'];
      operationAddress = data['operationAddress'];
      operationPhone = data['operationPhone'];
      operationEmail = data['operationEmail'];
      if (data['selectedCategories'] is List) {
        selectedCategories = List<String>.from(data['selectedCategories']);
      } else {
        selectedCategories = [];
      }
      if (data['selectedSubcategories'] is List) {
        selectedSubcategories = List<String>.from(data['selectedSubcategories']);
      } else {
        selectedSubcategories = [];
      }
      serviceArea = data['serviceArea'];
      serviceHours = data['serviceHours'];
      tier = data['tier'];
      bankName = data['bankName'];
      bankAccount = data['bankAccount'];
      clabe = data['clabe'];
      billingEmail = data['billingEmail'];
      paymentTerms = data['paymentTerms'];
      actaConstitutivaUrl = data['actaConstitutivaUrl'];
      comprobanteDomicilioUrl = data['comprobanteDomicilioUrl'];
      identificacionOficialUrl = data['identificacionOficialUrl'];
      cedulaFiscalUrl = data['cedulaFiscalUrl'];
      contratoFirmadoUrl = data['contratoFirmadoUrl'];
      termsAccepted = data['termsAccepted'] ?? false;
      isCompleted = data['profileCompleted'] ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('No se pudo cargar el perfil parcial del proveedor: $e');
    }
  }

  // ...existing code...
  void setTermsAccepted(bool value) {
    termsAccepted = value;
    notifyListeners();
  }

  // Step 1: Legal Data
  String? companyName;
  String? legalRepresentative;
  String? nit;
  String? businessType;
  String? legalAddress;
  String? phoneNumber;
  String? email;

  // Step 2: Operational Data
  String? operationAddress;
  String? operationPhone;
  String? operationEmail;
  String? serviceArea;
  String? serviceHours;
  String? tier; // e.g., 'basic', 'premium', 'enterprise'

  // Step 3: Commercial Data
  String? bankName;
  String? bankAccount;
  String? clabe;
  String? billingEmail;
  String? paymentTerms;

  // Step 4: Documents (URLs after upload)
  String? actaConstitutivaUrl;
  String? comprobanteDomicilioUrl;
  String? identificacionOficialUrl;
  String? cedulaFiscalUrl;
  String? contratoFirmadoUrl;

  // Step 5: Acceptance
  bool termsAccepted = false;

  // Validation errors
  final Map<String, String?> errors = {};

  // Firestore reference
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProviderProfileController({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Stepper state
  int currentStep = 0;
  bool isLoading = false;
  bool isCompleted = false;

  void updateStep(int step) {
    currentStep = step;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setCompleted(bool value) {
    isCompleted = value;
    notifyListeners();
  }

  // Validation logic for each step
  bool validateStep(int step) {
    errors.clear();
    switch (step) {
      case 0:
        if (companyName == null || companyName!.isEmpty) {
          errors['companyName'] = 'Nombre de la empresa requerido';
        }
        if (legalRepresentative == null || legalRepresentative!.isEmpty) {
          errors['legalRepresentative'] = 'Representante legal requerido';
        }
        if (nit == null || nit!.isEmpty) {
          errors['nit'] = 'NIT requerido';
        } else {
          final nitRegExp = RegExp(r'^\d{5,15}$');
          if (!nitRegExp.hasMatch(nit!)) {
            errors['nit'] = 'NIT inválido. Ejemplo: 900123456-7';
          }
        }
        if (email == null || email!.isEmpty) {
          errors['email'] = 'Correo electrónico requerido';
        } else {
          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegExp.hasMatch(email!)) {
            errors['email'] = 'Correo electrónico inválido.';
          }
        }
        if (selectedCategories.isEmpty) {
          errors['selectedCategories'] =
              'Debes seleccionar al menos una categoría de servicio';
        }
        break;
      case 1:
        if (operationAddress == null || operationAddress!.isEmpty) {
          errors['operationAddress'] = 'Domicilio de operación requerido';
        }
        if (operationPhone == null || operationPhone!.isEmpty) {
          errors['operationPhone'] = 'Teléfono de operación requerido';
        }
        if (operationEmail == null || operationEmail!.isEmpty) {
          errors['operationEmail'] = 'Correo de operación requerido';
        }
        if (selectedCategories.isEmpty) {
          errors['selectedCategories'] =
              'Debes seleccionar al menos una categorÃ­a de servicio';
        }
        if (serviceHours == null || serviceHours!.isEmpty) {
          errors['serviceHours'] = 'Horario de servicio requerido';
        }
        if (tier == null || tier!.isEmpty) {
          errors['tier'] = 'Nivel de proveedor requerido';
        }
        break;
      case 2:
        if (bankName == null || bankName!.isEmpty) {
          errors['bankName'] = 'Banco requerido';
        }
        if (bankAccount == null || bankAccount!.isEmpty) {
          errors['bankAccount'] = 'Cuenta bancaria requerida';
        }
        if (clabe == null || clabe!.isEmpty) {
          errors['clabe'] = 'CLABE requerida';
        } else {
          final clabeRegExp = RegExp(r'^\d{18}$');
          if (!clabeRegExp.hasMatch(clabe!)) {
            errors['clabe'] = 'CLABE inválida. Debe tener 18 dígitos.';
          }
        }
        if (billingEmail == null || billingEmail!.isEmpty) {
          errors['billingEmail'] = 'Correo de facturación requerido';
        }
        if (paymentTerms == null || paymentTerms!.isEmpty) {
          errors['paymentTerms'] = 'Condiciones de pago requeridas';
        }
        break;
      case 3:
        if (actaConstitutivaUrl == null || actaConstitutivaUrl!.isEmpty) {
          errors['actaConstitutivaUrl'] = 'Acta constitutiva requerida';
        }
        if (comprobanteDomicilioUrl == null ||
            comprobanteDomicilioUrl!.isEmpty) {
          errors['comprobanteDomicilioUrl'] =
              'Comprobante de domicilio requerido';
        }
        if (identificacionOficialUrl == null ||
            identificacionOficialUrl!.isEmpty) {
          errors['identificacionOficialUrl'] =
              'Identificación oficial requerida';
        }
        if (cedulaFiscalUrl == null || cedulaFiscalUrl!.isEmpty) {
          errors['cedulaFiscalUrl'] = 'Cédula fiscal requerida';
        }
        if (contratoFirmadoUrl == null || contratoFirmadoUrl!.isEmpty) {
          errors['contratoFirmadoUrl'] = 'Contrato firmado requerido';
        }
        break;
      case 4:
        if (!termsAccepted) {
          errors['termsAccepted'] = 'Debes aceptar los términos y condiciones';
        }
        break;
    }
    notifyListeners();
    return errors.isEmpty;
  }

  // Save provider profile to Firestore
  /// Guardado final solo si el usuario está autenticado
  Future<void> saveProfile() async {
    setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
      // Validación cruzada y consistencia
      if (!validateConsistency()) {
        setCompleted(false);
        throw Exception('Inconsistencia de datos detectada');
      }
      // Manejo de conflictos: leer datos actuales antes de guardar
        final doc = await _firestore
          .collection('providers')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      final currentData = doc.data() ?? {};
      final data = {
        'companyName': companyName,
        'legalRepresentative': legalRepresentative,
        'nit': nit,
        'businessType': businessType,
        'legalAddress': legalAddress,
        'phoneNumber': phoneNumber,
        'email': email,
        'operationAddress': operationAddress,
        'operationPhone': operationPhone,
        'operationEmail': operationEmail,
        'selectedCategories': selectedCategories,
        'selectedSubcategories': selectedSubcategories,
        'serviceArea': serviceArea,
        'serviceHours': serviceHours,
        'tier': tier,
        'bankName': bankName,
        'bankAccount': bankAccount,
        'clabe': clabe,
        'billingEmail': billingEmail,
        'paymentTerms': paymentTerms,
        'actaConstitutivaUrl':
            actaConstitutivaUrl ?? currentData['actaConstitutivaUrl'],
        'comprobanteDomicilioUrl':
            comprobanteDomicilioUrl ?? currentData['comprobanteDomicilioUrl'],
        'identificacionOficialUrl':
            identificacionOficialUrl ?? currentData['identificacionOficialUrl'],
        'cedulaFiscalUrl': cedulaFiscalUrl ?? currentData['cedulaFiscalUrl'],
        'contratoFirmadoUrl':
            contratoFirmadoUrl ?? currentData['contratoFirmadoUrl'],
        'termsAccepted': termsAccepted,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // Mejor práctica: nunca guardar datos sensibles en texto plano
        await _firestore
          .collection('providers')
          .doc(user.uid)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({
              'profileCompleted': true,
              'status': 'active',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
      setCompleted(true);
    } catch (e) {
      setCompleted(false);
      debugPrint('Error de seguridad: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Reset all fields
  void reset() {
    companyName = null;
    legalRepresentative = null;
    nit = null;
    businessType = null;
    legalAddress = null;
    phoneNumber = null;
    email = null;
    operationAddress = null;
    operationPhone = null;
    operationEmail = null;
    selectedCategories = [];
    selectedSubcategories = [];
    serviceArea = null;
    serviceHours = null;
    tier = null;
    bankName = null;
    bankAccount = null;
    clabe = null;
    billingEmail = null;
    paymentTerms = null;
    actaConstitutivaUrl = null;
    comprobanteDomicilioUrl = null;
    identificacionOficialUrl = null;
    cedulaFiscalUrl = null;
    contratoFirmadoUrl = null;
    termsAccepted = false;
    errors.clear();
    currentStep = 0;
    isLoading = false;
    isCompleted = false;
    notifyListeners();
  }
}
