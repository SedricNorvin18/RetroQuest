import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';

class DbConnect {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Question>> fetchQuestions(
      {required String subject, String? teacherId}) async {
    var query = _firestore
        .collection("subjects")
        .doc(subject)
        .collection("questions")
        .orderBy("createdAt", descending: false);

    final snapshot = await query.get();

    final questions = <Question>[];
    for (final doc in snapshot.docs) {
      try {
        questions.add(Question.fromFirestore(doc));
      } catch (e) {
        // Error parsing question
      }
    }
    return questions;
  }

  Future<List<String>> fetchSubjects({String? teacherId}) async {
    Query query = _firestore.collection("subjects");
    if (teacherId != null) {
      query = query.where("teacherId", isEqualTo: teacherId);
    }
    final snapshot = await query.get();
    final subjects = <String>[];
    for (final doc in snapshot.docs) {
      subjects.add(doc.id);
    }
    return subjects;
  }
}
