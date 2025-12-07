import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
// <-- IMPORTANT for Uint8List

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

// CRITICAL FIX: Changed from File to Uint8List and putFile to putData
  Future<String> uploadQuestionImage(
      Uint8List imageBytes, String teacherUid, String imageName) async {
    try {
      // Store under a subfolder named after the teacher's ID for organization
      final destination = 'question_images/$teacherUid/$imageName';
      final ref = _storage.ref().child(destination);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      await ref.putData(imageBytes, metadata); // <--- Uses the bytes directly

      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Failed to upload question image: $e');
      rethrow;
    }
  }

}