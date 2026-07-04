import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
    /// Sube un documento/certificaciÃ³n (PDF/JPG/PNG) y retorna la URL pÃºblica
    static Future<String?> uploadProviderDocument(File file, String uid) async {
      try {
        // Verifica autenticaciÃ³n
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print('No hay usuario autenticado.');
          return 'ERROR: Usuario no autenticado';
        }
        print('Usuario autenticado: ${user.uid} (esperado: $uid)');
        final ext = file.path.split('.').last.toLowerCase();
        final ref = _storage.ref().child('provider_docs/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext');
        await ref.putFile(file);
        return await ref.getDownloadURL();
      } catch (e) {
        print('Error al subir documento: $e');
        return 'ERROR: $e';
      }
    }
  static final _storage = FirebaseStorage.instance;

  /// Sube una imagen y retorna la URL pÃºblica
  static Future<String?> uploadProviderImage(File image, String uid) async {
    try {
      // Verifica autenticaciÃ³n
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No hay usuario autenticado.');
        return 'ERROR: Usuario no autenticado';
      }
      print('Usuario autenticado: ${user.uid} (esperado: $uid)');
      final ref = _storage.ref().child('provider_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return 'ERROR: $e';
    }
  }
}

