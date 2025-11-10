import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String? imageUrl;
  final String? fileUrl;
  final String? createdBy;
  final int? timeLimit;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
    this.fileUrl,
    this.createdBy,
    this.timeLimit,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      text: data['text'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
      imageUrl: data['imageUrl'],
      fileUrl: data['fileUrl'],
      createdBy: data['createdBy'],
      timeLimit: data['timeLimit'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctAnswer': correctAnswer,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'timeLimit': timeLimit,
    };
  }
}
