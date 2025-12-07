import 'package:cloud_firestore/cloud_firestore.dart';

class EnrolledStudent {
  final String studentUid;
  final String teacherUid;
  final String studentEmail;
  final String? id; // Document ID from Firestore

  EnrolledStudent({
    required this.studentUid,
    required this.teacherUid,
    required this.studentEmail,
    this.id,
  });

  // Factory constructor for creating an EnrolledStudent from a Firestore document
  factory EnrolledStudent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EnrolledStudent(
      id: doc.id,
      studentUid: data['studentUid'] ?? '',
      teacherUid: data['teacherUid'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
    );
  }

  // Convert an EnrolledStudent object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'studentUid': studentUid,
      'teacherUid': teacherUid,
      'studentEmail': studentEmail,
      'timestamp': FieldValue
          .serverTimestamp(), // Optional: for ordering/tracking enrollment
    };
  }
}
