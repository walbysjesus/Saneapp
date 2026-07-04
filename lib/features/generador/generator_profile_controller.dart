import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeneratorProfileController {
  // CategorÃ­as principales
  static const List<String> categoriesList = [
    "GestionResiduos",
    "ServiciosVactor",
    "LimpiezaIndustrial",
    "TransporteResiduos",
    "ResiduosPeligrosos",
    "Emergencias24_7",
    "ConsultoriaAmbiental",
    "TratamientoAguas",
    "ControlPlagas"
  ];

  // SubcategorÃ­as por categorÃ­a
  static const Map<String, List<String>> subcategoriesMap = {
    "GestionResiduos": [
      "Ordinarios",
      "Especiales",
      "Hospitalarios",
      "RAEE",
      "AceiteUsado",
      "Industriales"
    ],
    "ServiciosVactor": [
      "SuccionLodos",
      "TrampasGrasa",
      "Alcantarillado",
      "PozosSepticos",
      "Desobstruccion"
    ],
    // Agrega mÃ¡s segÃºn sea necesario
  };

  static const List<String> contractFrequencies = [
    "Ocasional",
    "Mensual",
    "Semanal",
    "ContratoPermanente",
    "SoloEmergencias"
  ];

  static const List<String> budgetRanges = [
    "Menos1M",
    "1M_5M",
    "5M_20M",
    "Mas20M"
  ];

  static const List<String> coverages = [
    "Local",
    "Regional",
    "Nacional"
  ];

  // Estado temporal del wizard
  List<String> selectedCategories = [];
  List<String> selectedSubcategories = [];
  String? contractFrequency;
  String? budgetRange;
  String? coverage;

  // Validaciones
  bool get isStep1Valid => selectedCategories.isNotEmpty;
  bool get isStep2Valid => selectedSubcategories.isNotEmpty;
  bool get isStep3Valid => contractFrequency != null && contractFrequency!.isNotEmpty;
  bool get isStep4Valid => budgetRange != null && budgetRange!.isNotEmpty;
  bool get isStep5Valid => coverage != null && coverage!.isNotEmpty;
  bool get isAllValid => isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid && isStep5Valid;

  // Guardar en Firestore
  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'categories': selectedCategories,
      'subcategories': selectedSubcategories,
      'contractFrequency': contractFrequency,
      'budgetRange': budgetRange,
      'coverage': coverage,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

