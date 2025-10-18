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
    final Map<String, bool> newOptions = {};
    if (map['options'] is Map) {
      (map['options'] as Map).forEach((key, value) {
        if (value is bool) {
          newOptions[key.toString()] = value;
        }
      });
    }

    return Question(
      id: id,
      title: map['title'] is String ? map['title'] : '',
      options: newOptions,
      imageUrl: map['imageUrl'] is String ? map['imageUrl'] : null,
      fileUrl: map['fileUrl'] is String ? map['fileUrl'] : null,
      createdBy: map['createdBy'] is String ? map['createdBy'] : null,
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
