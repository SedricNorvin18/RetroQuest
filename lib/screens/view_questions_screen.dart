import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retroquest/models/question_model.dart';
import 'package:retroquest/screens/upload_question_screen.dart';

class ViewQuestionsScreen extends StatefulWidget {
  final String subjectId;

  const ViewQuestionsScreen({super.key, required this.subjectId});

  @override
  State<ViewQuestionsScreen> createState() => _ViewQuestionsScreenState();
}

class _ViewQuestionsScreenState extends State<ViewQuestionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Questions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('questions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data!.docs
              .map((doc) => Question.fromFirestore(doc))
              .toList();
          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return ListTile(
                title: Text(question.text),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var option in question.options)
                      Text(
                        option,
                        style: TextStyle(
                          color: question.correctAnswer == option
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UploadQuestionScreen(
                              subjectId: widget.subjectId,
                              questionToEdit: question,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('subjects')
                            .doc(widget.subjectId)
                            .collection('questions')
                            .doc(question.id)
                            .delete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadQuestionScreen(
                subjectId: widget.subjectId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
