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

    return snapshot.docs
        .map((doc) => Question.fromMap(doc.id, doc.data()))
        .toList();
  }
}
