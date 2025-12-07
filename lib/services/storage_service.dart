import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePicture(String userId, Uint8List imageBytes,
      String imageName, {String? mimeType}) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$userId/$imageName');
      final metadata = SettableMetadata(contentType: mimeType ?? 'image/jpeg');

      await ref.putData(imageBytes, metadata);

      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Failed to upload profile picture: $e');
      rethrow;
    }
  }

  Future<void> deleteFileByUrl(String url) async {
    if (url.isEmpty) return;

    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      debugPrint('Failed to delete file: $e');
    }
  }
}