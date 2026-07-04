import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/app_state.dart';
import 'provider_profile_status.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);
const _cardBorder = Color(0xFFDDE6E0);
const _warningColor = Color(0xFFC27A00);

class PerfilProveedorPage extends StatefulWidget {
  const PerfilProveedorPage({super.key});

  @override
  State<PerfilProveedorPage> createState() => _PerfilProveedorPageState();
}

class _PerfilProveedorPageState extends State<PerfilProveedorPage> {
  static const _allowedDocumentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const _allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _legalRepresentativeController = TextEditingController();
  final _nitController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _operationAddressController = TextEditingController();
  final _operationPhoneController = TextEditingController();
  final _operationEmailController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _serviceHoursController = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _paymentTermsController = TextEditingController();

  final List<_CategoryOption> _categoryOptions = [];
  List<MultiSelectItem<String>> _categoryItems = const [];
  List<MultiSelectItem<String>> _subcategoryItems = const [];
  List<String> _selectedCategories = [];
  List<String> _selectedSubcategories = [];
  final Map<String, String?> _documentUrls = {
    'rutUrl': null,
    'camaraComercioUrl': null,
    'cedulaUrl': null,
    'certificadoBancarioUrl': null,
    'licenciaAmbientalUrl': null,
  };
  final Map<String, bool> _uploadingDocuments = {
    'rutUrl': false,
    'camaraComercioUrl': false,
    'cedulaUrl': false,
    'certificadoBancarioUrl': false,
    'licenciaAmbientalUrl': false,
  };
  final Map<String, double?> _documentUploadProgress = {
    'rutUrl': null,
    'camaraComercioUrl': null,
    'cedulaUrl': null,
    'certificadoBancarioUrl': null,
    'licenciaAmbientalUrl': null,
  };

  bool _loading = true;
  bool _saving = false;
  bool _loadingSubcategories = false;
  bool _hasUnsavedChanges = false;
  bool _licenseApplies = false;
  bool _termsAccepted = false;
  String? _email;
  String? _logoUrl;
  String? _status;
  String? _catalogError;
  ProviderProfileStatus? _profileStatus;

  final _statusService = const ProviderProfileStatusService();

  @override
  void initState() {
    super.initState();
    _attachDirtyListeners();
    _loadProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _legalRepresentativeController.dispose();
    _nitController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _operationAddressController.dispose();
    _operationPhoneController.dispose();
    _operationEmailController.dispose();
    _serviceAreaController.dispose();
    _serviceHoursController.dispose();
    _billingEmailController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  void _attachDirtyListeners() {
    for (final controller in [
      _companyNameController,
      _legalRepresentativeController,
      _nitController,
      _cityController,
      _phoneController,
      _operationAddressController,
      _operationPhoneController,
      _operationEmailController,
      _serviceAreaController,
      _serviceHoursController,
      _billingEmailController,
      _paymentTermsController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_hasUnsavedChanges && mounted) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hay cambios sin guardar'),
        content: const Text(
          'Si sales ahora perderás los cambios recientes del perfil del proveedor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir editando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Descartar cambios'),
          ),
        ],
      ),
    );

    return discard ?? false;
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _catalogError = null;
    });

    try {
      final futures = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        FirebaseFirestore.instance.collection('providers').doc(user.uid).get(),
        FirebaseFirestore.instance.collection('categories').get(),
        _statusService.loadCurrentUserStatus(),
      ]);

      final userDoc = futures[0] as DocumentSnapshot<Map<String, dynamic>>;
      final providerDoc = futures[1] as DocumentSnapshot<Map<String, dynamic>>;
      final categoriesSnapshot =
          futures[2] as QuerySnapshot<Map<String, dynamic>>;
      final profileStatus = futures[3] as ProviderProfileStatus;

      final userData = userDoc.data() ?? <String, dynamic>{};
      final providerData = providerDoc.data() ?? <String, dynamic>{};

      _companyNameController.text =
          (providerData['companyName'] as String?) ??
          (userData['companyName'] as String?) ??
          '';
      _legalRepresentativeController.text =
          (providerData['legalRepresentative'] as String?) ?? '';
      _nitController.text = (providerData['nit'] as String?) ?? '';
      _cityController.text = (userData['city'] as String?) ?? '';
      _phoneController.text = (providerData['phoneNumber'] as String?) ?? '';
      _operationAddressController.text =
          (providerData['operationAddress'] as String?) ?? '';
      _operationPhoneController.text =
          (providerData['operationPhone'] as String?) ?? '';
      _operationEmailController.text =
          (providerData['operationEmail'] as String?) ??
          ((providerData['email'] as String?) ?? user.email ?? '');
      _serviceAreaController.text =
          (providerData['serviceArea'] as String?) ?? '';
      _serviceHoursController.text =
          (providerData['serviceHours'] as String?) ?? '';
      _billingEmailController.text =
          (providerData['billingEmail'] as String?) ?? '';
      _paymentTermsController.text =
          (providerData['paymentTerms'] as String?) ?? '';

      _email =
          user.email ??
          (userData['email'] as String?) ??
          (providerData['email'] as String?);
      _logoUrl =
          (providerData['logoUrl'] as String?) ??
          (userData['photoUrl'] as String?);
      _status = (userData['status'] as String?) ?? profileStatus.accountStatus;
      _profileStatus = profileStatus;
      _licenseApplies =
          ((providerData['licenciaAmbientalUrl'] as String?)?.isNotEmpty ??
          false);
      _termsAccepted = providerData['termsAccepted'] == true;

      for (final key in _documentUrls.keys) {
        _documentUrls[key] = providerData[key] as String?;
      }

      _categoryOptions
        ..clear()
        ..addAll(
          categoriesSnapshot.docs
              .map(
                (doc) => _CategoryOption(
                  id: doc.id,
                  name:
                      ((doc.data()['name'] as String?)?.trim().isNotEmpty ??
                          false)
                      ? (doc.data()['name'] as String).trim()
                      : doc.id,
                ),
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ),
        );
      _categoryItems = _categoryOptions
          .map((option) => MultiSelectItem<String>(option.id, option.name))
          .toList();

      _selectedCategories =
          (providerData['selectedCategories'] as List?)
              ?.cast<String>()
              .toList() ??
          <String>[];
      _selectedSubcategories =
          (providerData['selectedSubcategories'] as List?)
              ?.cast<String>()
              .toList() ??
          <String>[];

      await _loadSubcategories(_selectedCategories);
      _hasUnsavedChanges = false;
    } catch (_) {
      _catalogError = 'No se pudo cargar toda la información del perfil.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadSubcategories(List<String> categoryIds) async {
    if (categoryIds.isEmpty) {
      if (mounted) {
        setState(() {
          _subcategoryItems = const [];
          _selectedSubcategories = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loadingSubcategories = true;
      });
    }

    try {
      final snapshots = await Future.wait(
        categoryIds.map(
          (categoryId) => FirebaseFirestore.instance
              .collection('categories')
              .doc(categoryId)
              .collection('subcategories')
              .get(),
        ),
      );

      final subcategoryMap = <String, String>{};
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          final name = (doc.data()['name'] as String?)?.trim();
          subcategoryMap[doc.id] = (name != null && name.isNotEmpty)
              ? name
              : doc.id;
        }
      }

      final items =
          subcategoryMap.entries
              .map((entry) => MultiSelectItem<String>(entry.key, entry.value))
              .toList()
            ..sort(
              (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
            );

      final validIds = items.map((item) => item.value).toSet();

      if (mounted) {
        setState(() {
          _subcategoryItems = items;
          _selectedSubcategories = _selectedSubcategories
              .where(validIds.contains)
              .toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSubcategories = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una categoría de servicio.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final providerPayload = <String, dynamic>{
        'companyName': _companyNameController.text.trim(),
        'legalRepresentative': _legalRepresentativeController.text.trim(),
        'nit': _nitController.text.trim(),
        'logoUrl': _logoUrl,
        'phoneNumber': _phoneController.text.trim(),
        'email': _email,
        'operationAddress': _operationAddressController.text.trim(),
        'operationPhone': _operationPhoneController.text.trim(),
        'operationEmail': _operationEmailController.text.trim(),
        'serviceArea': _serviceAreaController.text.trim(),
        'serviceHours': _serviceHoursController.text.trim(),
        'billingEmail': _billingEmailController.text.trim(),
        'paymentTerms': _paymentTermsController.text.trim(),
        'selectedCategories': _selectedCategories,
        'selectedSubcategories': _selectedSubcategories,
        'licenciaAmbientalUrl': _licenseApplies
            ? _documentUrls['licenciaAmbientalUrl']
            : FieldValue.delete(),
        'termsAccepted': _termsAccepted,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final userPayload = <String, dynamic>{
        'companyName': _companyNameController.text.trim(),
        'city': _cityController.text.trim(),
        'photoUrl': _logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await Future.wait([
        FirebaseFirestore.instance
            .collection('providers')
            .doc(user.uid)
            .set(providerPayload, SetOptions(merge: true)),
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userPayload, SetOptions(merge: true)),
      ]);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil del proveedor actualizado.')),
      );
      setState(() {
        _hasUnsavedChanges = false;
      });
      await _loadProfile();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    final selectedFile = result?.files.single;
    final imageExtension = (selectedFile?.extension ?? '').toLowerCase();
    if (selectedFile != null &&
        imageExtension.isNotEmpty &&
        !_allowedImageExtensions.contains(imageExtension)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usa una imagen JPG, JPEG, PNG o WEBP.')),
      );
      return;
    }

    final bytes = selectedFile?.bytes;
    final path = selectedFile?.path;
    if (path == null && bytes == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final extension = selectedFile?.extension ?? 'jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'proveedores/${user.uid}/logo_perfil.$extension',
      );
      final uploadTask = await _startUpload(ref: ref, path: path, bytes: bytes);
      await uploadTask;
      final url = await ref.getDownloadURL();

      await Future.wait([
        FirebaseFirestore.instance.collection('providers').doc(user.uid).set({
          'logoUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'photoUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      ]);

      if (!mounted) {
        return;
      }
      setState(() {
        _logoUrl = url;
        _hasUnsavedChanges = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo actualizado correctamente.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible cargar el logo. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadDocument({
    required String fieldKey,
    required String fileName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );

    final selectedFile = result?.files.single;
    final extension = (selectedFile?.extension ?? '').toLowerCase();
    if (selectedFile != null &&
        extension.isNotEmpty &&
        !_allowedDocumentExtensions.contains(extension)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato no permitido. Usa PDF, JPG, JPEG o PNG.'),
        ),
      );
      return;
    }
    final path = selectedFile?.path;
    final bytes = selectedFile?.bytes;
    if (path == null && bytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo leer el archivo seleccionado.'),
        ),
      );
      return;
    }

    setState(() {
      _uploadingDocuments[fieldKey] = true;
      _documentUploadProgress[fieldKey] = 0;
    });

    try {
      final extension = selectedFile?.extension ?? 'pdf';
      final ref = FirebaseStorage.instance.ref().child(
        'proveedores/${user.uid}/$fileName.$extension',
      );
      final uploadTask = await _startUpload(ref: ref, path: path, bytes: bytes);

      uploadTask.snapshotEvents.listen((snapshot) {
        if (!mounted) {
          return;
        }
        final totalBytes = snapshot.totalBytes;
        final progress = totalBytes > 0
            ? snapshot.bytesTransferred / totalBytes
            : null;
        setState(() {
          _documentUploadProgress[fieldKey] = progress;
        });
      });

      await uploadTask;
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .set({
            fieldKey: url,
            'termsAccepted': _termsAccepted,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await _saveDocumentRepositoryEntry(
        userId: user.uid,
        fieldKey: fieldKey,
        label: _documentLabelForField(fieldKey),
        url: url,
        fileName: '${fileName.split('.').first}.$extension',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documentUrls[fieldKey] = url;
        _hasUnsavedChanges = true;
        if (fieldKey == 'licenciaAmbientalUrl') {
          _licenseApplies = true;
        }
      });
      await _refreshStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento cargado correctamente.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible cargar el documento. Verifica el archivo e inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingDocuments[fieldKey] = false;
          _documentUploadProgress[fieldKey] = null;
        });
      }
    }
  }

  Future<UploadTask> _startUpload({
    required Reference ref,
    String? path,
    Uint8List? bytes,
  }) async {
    if (bytes != null) {
      return ref.putData(bytes);
    }
    if (path != null && path.isNotEmpty) {
      return ref.putFile(File(path));
    }
    throw Exception('No file data available for upload');
  }

  Future<void> _saveDocumentRepositoryEntry({
    required String userId,
    required String fieldKey,
    required String label,
    required String url,
    required String fileName,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc(fieldKey)
        .set({
          'fieldKey': fieldKey,
          'nombre': label,
          'fileName': fileName,
          'url': url,
          'uploadedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  String _documentLabelForField(String fieldKey) {
    switch (fieldKey) {
      case 'rutUrl':
        return 'RUT';
      case 'camaraComercioUrl':
        return 'Cámara de comercio';
      case 'cedulaUrl':
        return 'Cédula representante';
      case 'certificadoBancarioUrl':
        return 'Certificado bancario';
      case 'licenciaAmbientalUrl':
        return 'Licencia ambiental';
      default:
        return 'Documento proveedor';
    }
  }

  Future<void> _refreshStatus() async {
    final status = await _statusService.loadCurrentUserStatus();
    if (!mounted) {
      return;
    }
    setState(() {
      _profileStatus = status;
    });
  }

  Future<void> _openDocument(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Text(
          _hasUnsavedChanges
              ? 'Tienes cambios sin guardar. Si continúas, se cerrará la sesión y perderás esos cambios.'
              : '¿Deseas cerrar la sesión de tu perfil proveedor?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !mounted) {
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) {
        return;
      }
      context.read<AppState>().clearUser();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible cerrar la sesión. Intenta de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final companyName = _companyNameController.text.trim();
    final initials = companyName.isEmpty
        ? 'PR'
        : companyName
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return WillPopScope(
      onWillPop: _confirmDiscardChanges,
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          title: const Text('Perfil del proveedor'),
          actions: [
            TextButton.icon(
              onPressed: _saving ? null : _signOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar sesión'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _ProfileHeader(
                initials: initials,
                companyName: companyName.isEmpty
                    ? 'Proveedor SaneApp'
                    : companyName,
                email: _email ?? user.email ?? '',
                logoUrl: _logoUrl,
                statusLabel: _mapStatus(_status),
                completionPercent: _profileStatus?.completionPercent ?? 0,
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Imagen y cumplimiento',
                subtitle:
                    'Mantén visible tu identidad de marca y el estado documental operativo.',
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickAndUploadLogo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brandGreen,
                        side: const BorderSide(color: _brandGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Actualizar logo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () =>
                                Navigator.pushNamed(context, '/mis_documentos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brandGreen,
                        side: const BorderSide(color: _brandGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.folder_shared_outlined),
                      label: const Text('Ver repositorio'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DocumentsSummaryCard(profileStatus: _profileStatus),
              const SizedBox(height: 12),
              _InlineDocumentsManager(
                saving: _saving,
                licenseApplies: _licenseApplies,
                termsAccepted: _termsAccepted,
                documentUrls: _documentUrls,
                uploadingDocuments: _uploadingDocuments,
                uploadProgress: _documentUploadProgress,
                onTermsChanged: (value) async {
                  setState(() {
                    _termsAccepted = value;
                    _hasUnsavedChanges = true;
                  });
                },
                onLicenseChanged: (value) {
                  setState(() {
                    _licenseApplies = value;
                    _hasUnsavedChanges = true;
                    if (!value) {
                      _documentUrls['licenciaAmbientalUrl'] = null;
                    }
                  });
                },
                onUpload: _pickAndUploadDocument,
                onOpen: _openDocument,
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Identidad comercial',
                subtitle:
                    'Mantén actualizada la información principal con la que te ven clientes y operaciones.',
              ),
              _buildTextField(
                controller: _companyNameController,
                label: 'Nombre comercial o razón social',
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Ingresa un nombre válido.'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _legalRepresentativeController,
                label: 'Representante legal',
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Ingresa el representante legal.'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nitController,
                label: 'NIT',
                validator: (value) => value == null || value.trim().length < 5
                    ? 'Ingresa un NIT válido.'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                label: 'Correo principal de la cuenta',
                value: _email ?? '',
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Operación y cobertura',
                subtitle:
                    'Ajusta los datos que usa SaneApp para asignación, contacto y promesa operativa.',
              ),
              _buildTextField(
                controller: _cityController,
                label: 'Ciudad base',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa tu ciudad base.'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono principal',
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa un teléfono de contacto.'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _operationAddressController,
                label: 'Dirección de operación',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa la dirección operativa.'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _operationPhoneController,
                label: 'Teléfono operativo',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _operationEmailController,
                label: 'Correo operativo',
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _serviceAreaController,
                label: 'Cobertura geográfica',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _serviceHoursController,
                label: 'Horario y disponibilidad',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Catálogo y facturación',
                subtitle:
                    'Mantén alineadas tus categorías, subcategorías y condiciones administrativas.',
              ),
              if (_catalogError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _catalogError!,
                    style: const TextStyle(color: _warningColor),
                  ),
                ),
              MultiSelectDialogField<String>(
                items: _categoryItems,
                initialValue: _selectedCategories,
                title: const Text('Categorías'),
                buttonText: const Text('Selecciona categorías'),
                buttonIcon: const Icon(Icons.category),
                selectedColor: const Color(0xFF1E7A4B),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD3E3D9)),
                ),
                onConfirm: (values) async {
                  setState(() {
                    _selectedCategories = values;
                    _selectedSubcategories = [];
                    _hasUnsavedChanges = true;
                  });
                  await _loadSubcategories(values);
                },
              ),
              const SizedBox(height: 12),
              if (_loadingSubcategories) const LinearProgressIndicator(),
              if (!_loadingSubcategories)
                MultiSelectDialogField<String>(
                  items: _subcategoryItems,
                  initialValue: _selectedSubcategories,
                  title: const Text('Subcategorías'),
                  buttonText: const Text('Selecciona subcategorías'),
                  buttonIcon: const Icon(Icons.tune),
                  selectedColor: const Color(0xFF1E7A4B),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD3E3D9)),
                  ),
                  onConfirm: (values) {
                    setState(() {
                      _selectedSubcategories = values;
                      _hasUnsavedChanges = true;
                    });
                  },
                ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _billingEmailController,
                label: 'Correo de facturación',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  return _validateEmail(value);
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _paymentTermsController,
                label: 'Términos de pago',
                maxLines: 3,
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _saving
                  ? 'Guardando...'
                  : _hasUnsavedChanges
                  ? 'Guardar cambios'
                  : 'Sin cambios pendientes',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _brandGreen, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: const Color(0xFFF4F7F5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _cardBorder),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un correo válido.';
    }
    final emailRegExp = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Correo inválido.';
    }
    return null;
  }

  String _mapStatus(String? status) {
    switch (status) {
      case 'active':
        return 'Operativo';
      case 'pending_review':
        return 'En revisión';
      case 'pending_documents':
        return 'Pendiente de documentos';
      case 'suspended':
        return 'Suspendido';
      default:
        return 'En configuración';
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String companyName;
  final String email;
  final String? logoUrl;
  final String statusLabel;
  final int completionPercent;

  const _ProfileHeader({
    required this.initials,
    required this.companyName,
    required this.email,
    required this.logoUrl,
    required this.statusLabel,
    required this.completionPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C4F31), Color(0xFF1E7A4B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.16),
                backgroundImage: logoUrl != null && logoUrl!.isNotEmpty
                    ? NetworkImage(logoUrl!)
                    : null,
                child: logoUrl == null || logoUrl!.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusChip(label: statusLabel),
              _StatusChip(label: '$completionPercent% completo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _DocumentsSummaryCard extends StatelessWidget {
  final ProviderProfileStatus? profileStatus;

  const _DocumentsSummaryCard({required this.profileStatus});

  @override
  Widget build(BuildContext context) {
    final hasDocuments = profileStatus?.hasDocuments == true;
    final completion = profileStatus?.completionPercent ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasDocuments ? Icons.verified_user : Icons.pending_actions,
                  color: hasDocuments ? _brandGreenSoft : _warningColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasDocuments
                        ? 'Documentación operativa cargada'
                        : 'Documentación pendiente o incompleta',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasDocuments
                  ? 'Tu expediente base ya está cargado. Puedes actualizar archivos si hay cambios regulatorios o comerciales.'
                  : 'Completa RUT, cámara de comercio, cédula, certificado bancario y anexos aplicables para mantener la cuenta operativa.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completion / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFFDCE7DF),
                valueColor: const AlwaysStoppedAnimation<Color>(_brandGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineDocumentsManager extends StatelessWidget {
  final bool saving;
  final bool licenseApplies;
  final bool termsAccepted;
  final Map<String, String?> documentUrls;
  final Map<String, bool> uploadingDocuments;
  final Map<String, double?> uploadProgress;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onLicenseChanged;
  final Future<void> Function({
    required String fieldKey,
    required String fileName,
  })
  onUpload;
  final Future<void> Function(String? url) onOpen;

  const _InlineDocumentsManager({
    required this.saving,
    required this.licenseApplies,
    required this.termsAccepted,
    required this.documentUrls,
    required this.uploadingDocuments,
    required this.uploadProgress,
    required this.onTermsChanged,
    required this.onLicenseChanged,
    required this.onUpload,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_DocumentItem>[
      if (licenseApplies)
        const _DocumentItem(
          'licenciaAmbientalUrl',
          'Licencia ambiental',
          'licencia_ambiental',
          false,
        ),
    ];
    final requiredCount = items.where((item) => item.required).length;
    final uploadedRequiredCount = items
        .where(
          (item) =>
              item.required &&
              (documentUrls[item.fieldKey]?.isNotEmpty ?? false),
        )
        .length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documentos del proveedor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Carga y consulta tu expediente sin salir del perfil.',
              style: TextStyle(color: Colors.black54),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Base documental: $uploadedRequiredCount/$requiredCount obligatorios cargados',
                style: const TextStyle(
                  color: _brandGreenSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InlineDocumentTile(
                    item: item,
                    url: documentUrls[item.fieldKey],
                    saving:
                        saving || (uploadingDocuments[item.fieldKey] ?? false),
                    uploadProgress: uploadProgress[item.fieldKey],
                    onUpload: () => onUpload(
                      fieldKey: item.fieldKey,
                      fileName: item.fileName,
                    ),
                    onOpen: () => onOpen(documentUrls[item.fieldKey]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Licencia ambiental aplica para esta operación',
              ),
              value: licenseApplies,
              onChanged: saving ? null : onLicenseChanged,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Acepto los términos y condiciones vigentes'),
              value: termsAccepted,
              onChanged: saving
                  ? null
                  : (value) => onTermsChanged(value ?? false),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineDocumentTile extends StatelessWidget {
  final _DocumentItem item;
  final String? url;
  final bool saving;
  final double? uploadProgress;
  final VoidCallback onUpload;
  final VoidCallback onOpen;

  const _InlineDocumentTile({
    required this.item,
    required this.url,
    required this.saving,
    required this.uploadProgress,
    required this.onUpload,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = url != null && url!.isNotEmpty;
    final fileName = _fileNameFromUrl(url);
    final isUploading = saving && uploadProgress != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            uploaded ? Icons.check_circle : Icons.upload_file,
            color: uploaded ? _brandGreenSoft : _warningColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _MiniBadge(
                      label: item.required ? 'Obligatorio' : 'Opcional',
                      backgroundColor: item.required
                          ? const Color(0xFFE9F5EE)
                          : const Color(0xFFF2F4F7),
                      foregroundColor: item.required
                          ? const Color(0xFF1E7A4B)
                          : const Color(0xFF5F6B7A),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isUploading
                      ? 'Cargando documento...'
                      : uploaded
                      ? 'Documento disponible'
                      : 'Aún no cargado',
                  style: const TextStyle(color: Colors.black54),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(value: uploadProgress),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    uploadProgress == null
                        ? 'Preparando carga...'
                        : '${(uploadProgress! * 100).clamp(0, 100).toStringAsFixed(0)}% completado',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
                if (uploaded && fileName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _brandGreen),
            onPressed: saving ? null : onUpload,
            child: Text(
              isUploading
                  ? 'Cargando...'
                  : uploaded
                  ? 'Actualizar'
                  : 'Cargar',
            ),
          ),
          if (uploaded)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _brandGreenSoft),
              onPressed: onOpen,
              child: const Text('Abrir'),
            ),
        ],
      ),
    );
  }

  String? _fileNameFromUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(rawUrl);
    final pathSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : rawUrl.split('/').last;
    return Uri.decodeComponent(pathSegment.split('?').first);
  }
}

class _DocumentItem {
  final String fieldKey;
  final String label;
  final String fileName;
  final bool required;

  const _DocumentItem(this.fieldKey, this.label, this.fileName, this.required);
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _MiniBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String id;
  final String name;

  const _CategoryOption({required this.id, required this.name});
}
