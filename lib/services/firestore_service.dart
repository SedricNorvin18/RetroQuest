import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enrolled_student.dart'; // Import the new model

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

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    return _db.collection('users').doc(uid).update(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserProfileByEmail(
      String email) async {
    final querySnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
  }

  // Subjects collection -> each subject is a doc with a 'questions' subcollection
  CollectionReference<Map<String, dynamic>> subjectQuestions(String subjectId) {
    return _db.collection('subjects').doc(subjectId).collection('questions');
  }

  Future<DocumentReference<Map<String, dynamic>>> addQuestion(
      String subjectId, Map<String, dynamic> data) {
    return subjectQuestions(subjectId).add(data);
  }

  Future<void> updateQuestion(
      String subjectId, String questionId, Map<String, dynamic> data) {
    return subjectQuestions(subjectId).doc(questionId).update(data);
  }

  Future<void> deleteQuestion(String subjectId, String questionId) {
    return subjectQuestions(subjectId).doc(questionId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamQuestions(
      String subjectId) {
    return subjectQuestions(subjectId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- New methods for student enrollment ---

  Future<void> enrollStudent({
    required String teacherUid,
    required String studentUid,
    required String studentEmail,
  }) async {
    // Check if the student is already enrolled by this teacher
    final existingEnrollment = await _db
        .collection('enrolledStudents')
        .where('teacherUid', isEqualTo: teacherUid)
        .where('studentUid', isEqualTo: studentUid)
        .limit(1)
        .get();

    if (existingEnrollment.docs.isNotEmpty) {
      throw Exception('Student is already enrolled with this teacher.');
    }

    final enrollmentRef = _db.collection('enrolledStudents').doc();
    await enrollmentRef.set(EnrolledStudent(
      studentUid: studentUid,
      teacherUid: teacherUid,
      studentEmail: studentEmail,
    ).toFirestore());
  }

  Stream<List<EnrolledStudent>> getEnrolledStudents(String teacherUid) {
    return _db
        .collection('enrolledStudents')
        .where('teacherUid', isEqualTo: teacherUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnrolledStudent.fromFirestore(doc))
            .toList());
  }

  Future<void> unenrollStudent(String enrollmentId) {
    return _db.collection('enrolledStudents').doc(enrollmentId).delete();
  }

  Future<bool> isStudentEnrolled({
    required String teacherUid,
    required String studentUid,
  }) async {
    final querySnapshot = await _db
        .collection('enrolledStudents')
        .where('teacherUid', isEqualTo: teacherUid)
        .where('studentUid', isEqualTo: studentUid)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Fetch quizzes created by a specific teacher
  Stream<QuerySnapshot<Map<String, dynamic>>> getTeacherQuizzes(
      String teacherUid) {
    return _db
        .collection('subjects')
        .where('teacherId',
            isEqualTo:
                teacherUid) // Assuming 'subjects' have a 'teacherUid' field
        .snapshots();
  }
}
