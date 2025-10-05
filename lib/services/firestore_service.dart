import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String role,
    String? displayName,
    String? profilePicUrl,
  }) {
    return _db.collection('users').doc(uid).set({
      'email': email,
      'role': role,
      'displayName': displayName ?? '',
      'profilePic': profilePicUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  // Subjects collection -> each subject is a doc with a 'questions' subcollection
  CollectionReference<Map<String, dynamic>> subjectQuestions(String subjectId) {
    return _db.collection('subjects').doc(subjectId).collection('questions');
  }

  Future<DocumentReference<Map<String, dynamic>>> addQuestion(String subjectId, Map<String, dynamic> data) {
    return subjectQuestions(subjectId).add(data);
  }

  Future<void> updateQuestion(String subjectId, String questionId, Map<String, dynamic> data) {
    return subjectQuestions(subjectId).doc(questionId).update(data);
  }

  Future<void> deleteQuestion(String subjectId, String questionId) {
    return subjectQuestions(subjectId).doc(questionId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamQuestions(String subjectId) {
    return subjectQuestions(subjectId).orderBy('createdAt', descending: true).snapshots();
  }
}
  