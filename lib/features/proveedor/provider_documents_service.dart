import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProviderDocumentValidationResult {
  const ProviderDocumentValidationResult({
    required this.isValid,
    this.error,
    this.extension,
    this.sizeBytes,
  });

  final bool isValid;
  final String? error;
  final String? extension;
  final int? sizeBytes;
}

class ProviderDocumentsService {
  ProviderDocumentsService({
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const int maxFileSizeBytes = 10 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {'pdf', 'jpg', 'jpeg', 'png'};

  static const Map<String, String> providerFieldByDocumentType = {
    'rut': 'rutUrl',
    'camara_comercio': 'camaraComercioUrl',
    'cedula_representante': 'cedulaUrl',
    'certificado_bancario': 'certificadoBancarioUrl',
    'licencia_ambiental': 'licenciaAmbientalUrl',
  };

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  ProviderDocumentValidationResult validateDocumentDetailed(
    String filePath,
    String documentType,
  ) {
    if (!providerFieldByDocumentType.containsKey(documentType)) {
      return const ProviderDocumentValidationResult(
        isValid: false,
        error: 'Tipo de documento no soportado.',
      );
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return const ProviderDocumentValidationResult(
        isValid: false,
        error: 'El archivo no existe.',
      );
    }

    final extension = _extractExtension(filePath);
    if (!_allowedExtensions.contains(extension)) {
      return const ProviderDocumentValidationResult(
        isValid: false,
        error: 'Formato no permitido. Usa PDF, JPG, JPEG o PNG.',
      );
    }

    final fileSize = file.lengthSync();
    if (fileSize <= 0) {
      return const ProviderDocumentValidationResult(
        isValid: false,
        error: 'El archivo esta vacio.',
      );
    }
    if (fileSize > maxFileSizeBytes) {
      return const ProviderDocumentValidationResult(
        isValid: false,
        error: 'El archivo excede el tamano maximo de 10MB.',
      );
    }

    return ProviderDocumentValidationResult(
      isValid: true,
      extension: extension,
      sizeBytes: fileSize,
    );
  }

  bool validateDocument(String filePath, String documentType) {
    return validateDocumentDetailed(filePath, documentType).isValid;
  }

  Future<String> uploadDocument(String filePath, String documentType) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }

    final validation = validateDocumentDetailed(filePath, documentType);
    if (!validation.isValid) {
      throw Exception(validation.error ?? 'Documento invalido.');
    }

    final fieldKey = providerFieldByDocumentType[documentType];
    if (fieldKey == null) {
      throw Exception('No se pudo resolver el campo del documento.');
    }

    final extension = validation.extension ?? _extractExtension(filePath);
    final fileName =
        '${documentType}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final storagePath = 'provider_docs/${currentUser.uid}/$fileName';

    final ref = _storage.ref().child(storagePath);
    await ref.putFile(
      File(filePath),
      SettableMetadata(
        contentType: _contentTypeForExtension(extension),
        customMetadata: {
          'ownerUid': currentUser.uid,
          'documentType': documentType,
          'fieldKey': fieldKey,
        },
      ),
    );
    final url = await ref.getDownloadURL();

    await _firestore.collection('providers').doc(currentUser.uid).set({
      fieldKey: url,
      'documentsStatus': 'pending_review',
      'kycLastSubmissionAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('documents')
        .doc(fieldKey)
        .set({
          'fieldKey': fieldKey,
          'documentType': documentType,
          'fileName': fileName,
          'url': url,
          'status': 'pending_review',
          'uploadedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    return url;
  }

  static String _extractExtension(String filePath) {
    final segments = filePath.split('.');
    if (segments.length < 2) {
      return '';
    }
    return segments.last.toLowerCase().trim();
  }

  static String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
