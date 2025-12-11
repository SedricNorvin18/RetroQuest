
import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentRequest {
  final String id;
  final String studentUid;
  final String teacherUid;
  final String studentEmail;
  final String teacherEmail;
  final String status;

  EnrollmentRequest({
    required this.id,
    required this.studentUid,
    required this.teacherUid,
    required this.studentEmail,
    required this.teacherEmail,
    required this.status,
  });

  factory EnrollmentRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return EnrollmentRequest(
      id: doc.id,
      studentUid: data['studentUid'] ?? '',
      teacherUid: data['teacherUid'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      teacherEmail: data['teacherEmail'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentUid': studentUid,
      'teacherUid': teacherUid,
      'studentEmail': studentEmail,
      'teacherEmail': teacherEmail,
      'status': status,
    };
  }
}
