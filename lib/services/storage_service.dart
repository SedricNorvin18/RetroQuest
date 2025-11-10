import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Deletes a file from Firebase Storage using its URL.
  Future<void> deleteFileByUrl(String url) async {
    if (url.isEmpty) return;

    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } on FirebaseException catch (e) {
      // Log the error for debugging, but don't throw an exception.
      // This is because we don't want to crash the app if a file fails to delete.
      debugPrint('Failed to delete file: $e');
    }
  }
}
