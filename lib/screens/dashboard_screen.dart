import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'upload_question_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<String> subjects = [
    "Math",
    "History",
    "Arts",
    "Biology",
    "Chemistry",
  ];

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(subject),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(subject: subject),
                  ),
                );
              },
              onLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadQuestionScreen(subject: subject),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
