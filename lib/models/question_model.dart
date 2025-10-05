import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String title;
  final Map<String, bool> options;
  final String? imageUrl;
  final String? fileUrl;
  final String? createdBy;

  Question({
    required this.id,
    required this.title,
    required this.options,
    this.imageUrl,
    this.fileUrl,
    this.createdBy,
  });

  factory Question.fromMap(String id, Map<String, dynamic> map) {
    return Question(
      id: id,
      title: map['title'] ?? '',
      options: Map<String, bool>.from(map['options'] ?? {}),
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'options': options,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
