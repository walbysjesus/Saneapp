import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderProfileStatus {
  final bool isAuthenticated;
  final bool isProfileComplete;
  final bool hasDocuments;
  final String accountStatus;
  final int completionPercent;

  const ProviderProfileStatus({
    required this.isAuthenticated,
    required this.isProfileComplete,
    required this.hasDocuments,
    required this.accountStatus,
    required this.completionPercent,
  });

  bool get canOperate => isAuthenticated && isProfileComplete;

  String get headline {
    if (!isAuthenticated) {
      return 'No autenticado';
    }
    if (isProfileComplete) {
      return 'Perfil operativo habilitado';
    }
    if (hasDocuments) {
      return 'Documentos cargados, validación pendiente';
    }
    return 'Perfil y documentos pendientes';
  }

  String get detail {
    if (!isAuthenticated) {
      return 'Inicia sesión para gestionar tu operación como proveedor.';
    }
    if (isProfileComplete) {
      return 'Ya puedes publicar servicios, cotizar y operar dentro del marketplace.';
    }
    if (hasDocuments) {
      return 'Tu perfil básico y tus documentos ya fueron enviados. Continúa completando la información operativa si hace falta.';
    }
    return 'Completa tu registro para publicar servicios, enviar cotizaciones y aceptar servicios.';
  }
}

class ProviderProfileStatusService {
  const ProviderProfileStatusService();

  Stream<ProviderProfileStatus> watchCurrentUserStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(
        const ProviderProfileStatus(
          isAuthenticated: false,
          isProfileComplete: false,
          hasDocuments: false,
          accountStatus: 'anonymous',
          completionPercent: 0,
        ),
      );
    }

    final userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
    final providerStream = FirebaseFirestore.instance
        .collection('providers')
        .doc(user.uid)
        .snapshots();

    return userStream.asyncMap((userSnapshot) async {
      try {
        final providerSnapshot = await providerStream.first;
        return _buildStatus(userSnapshot.data(), providerSnapshot.data());
      } catch (_) {
        return _buildStatus(userSnapshot.data(), null);
      }
    }).handleError((_) {
      return const ProviderProfileStatus(
        isAuthenticated: true,
        isProfileComplete: false,
        hasDocuments: false,
        accountStatus: 'offline',
        completionPercent: 0,
      );
    });
  }

  Future<ProviderProfileStatus> loadCurrentUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const ProviderProfileStatus(
        isAuthenticated: false,
        isProfileComplete: false,
        hasDocuments: false,
        accountStatus: 'anonymous',
        completionPercent: 0,
      );
    }

    try {
      final snapshots = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        FirebaseFirestore.instance.collection('providers').doc(user.uid).get(),
      ]);

      return _buildStatus(
        snapshots[0].data(),
        snapshots[1].data(),
      );
    } catch (_) {
      return const ProviderProfileStatus(
        isAuthenticated: true,
        isProfileComplete: false,
        hasDocuments: false,
        accountStatus: 'offline',
        completionPercent: 0,
      );
    }
  }

  ProviderProfileStatus _buildStatus(
    Map<String, dynamic>? userData,
    Map<String, dynamic>? providerData,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const ProviderProfileStatus(
        isAuthenticated: false,
        isProfileComplete: false,
        hasDocuments: false,
        accountStatus: 'anonymous',
        completionPercent: 0,
      );
    }

    final accountStatus = (userData?['status'] as String?) ?? 'pending_documents';
    final profileCompleted =
        (userData?['profileCompleted'] == true) || (providerData?['profileCompleted'] == true);
    final hasBasicProfile =
        ((providerData?['companyName'] as String?)?.trim().isNotEmpty ?? false) &&
        ((providerData?['nit'] as String?)?.trim().isNotEmpty ?? false) &&
        ((providerData?['email'] as String?)?.trim().isNotEmpty ?? false);
    final hasCategories =
        (providerData?['selectedCategories'] as List?)?.isNotEmpty ?? false;
    final hasDocuments = _hasUploadedDocuments(providerData);

    var completion = 10;
    if (hasBasicProfile) {
      completion += 35;
    }
    if (hasCategories) {
      completion += 20;
    }
    if (hasDocuments) {
      completion += 25;
    }
    if (profileCompleted) {
      completion = 100;
    }

    return ProviderProfileStatus(
      isAuthenticated: true,
      isProfileComplete: profileCompleted,
      hasDocuments: hasDocuments,
      accountStatus: accountStatus,
      completionPercent: completion.clamp(0, 100),
    );
  }

  bool _hasUploadedDocuments(Map<String, dynamic>? providerData) {
    if (providerData == null) {
      return false;
    }
    const fields = [
      'rutUrl',
      'camaraComercioUrl',
      'cedulaUrl',
      'certificadoBancarioUrl',
    ];
    return fields.every(
      (field) => (providerData[field] as String?)?.trim().isNotEmpty ?? false,
    );
  }
}