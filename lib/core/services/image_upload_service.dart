import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  static const int _defaultImageQuality = 80;
  static const double _defaultMaxWidth = 1600;
  static const double _defaultMaxHeight = 1600;

  static Future<String?> pickAndUploadImage(String userId) async {
    return pickAndUploadImageToFolder(
      'provider_images/$userId',
      imageQuality: _defaultImageQuality,
      maxWidth: _defaultMaxWidth,
      maxHeight: _defaultMaxHeight,
    );
  }

  static Future<String?> pickAndUploadImageToFolder(
    String folderPath, {
    int imageQuality = _defaultImageQuality,
    double maxWidth = _defaultMaxWidth,
    double maxHeight = _defaultMaxHeight,
  }) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      requestFullMetadata: false,
    );
    if (pickedFile == null) return null;

    final file = File(pickedFile.path);
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=31536000',
    );

    final ref = FirebaseStorage.instance.ref().child(
      '$folderPath/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final uploadTask = await ref.putFile(file, metadata);
    return await uploadTask.ref.getDownloadURL();
  }
}
