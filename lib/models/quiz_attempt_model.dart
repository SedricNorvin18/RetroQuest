import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAttempt {
  final String id;
  final String studentId;
  final String studentName;
  final String subjectId;
  final num score;
  final String teacherId;
  final Timestamp timestamp;
  final bool hiddenFromStudent;
  final bool hiddenFromTeacher;

  QuizAttempt({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.score,
    required this.teacherId,
    required this.timestamp,
    this.hiddenFromStudent = false,
    this.hiddenFromTeacher = false,
  });

  factory QuizAttempt.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return QuizAttempt(
      id: snapshot.id,
      studentId: data?['studentId'] ?? '',
      studentName: data?['studentName'] ?? 'Unknown Student',
      subjectId: data?['subjectId'] ?? 'Uncategorized',
      score: data?['score'] ?? 0,
      teacherId: data?['teacherId'] ?? '',
      timestamp: data?['timestamp'] ?? Timestamp.now(),
      hiddenFromStudent: data?['hiddenFromStudent'] ?? false,
      hiddenFromTeacher: data?['hiddenFromTeacher'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'subjectId': subjectId,
      'score': score,
      'teacherId': teacherId,
      'timestamp': timestamp,
      'hiddenFromStudent': hiddenFromStudent,
      'hiddenFromTeacher': hiddenFromTeacher,
    };
  }
}
