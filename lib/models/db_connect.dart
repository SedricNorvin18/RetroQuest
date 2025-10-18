import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_model.dart';

class DbConnect {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Question>> fetchQuestions({required String subject}) async {
    final snapshot = await _firestore
        .collection("subjects")
        .doc(subject)
        .collection("questions")
        .orderBy("createdAt", descending: false)
        .get();

    final questions = <Question>[];
    for (final doc in snapshot.docs) {
      try {
        questions.add(Question.fromMap(doc.id, doc.data()));
      } catch (e, stackTrace) {
        print('Error parsing question ${doc.id}: $e');
        print(stackTrace);
      }
    }
    return questions;
  }
}
