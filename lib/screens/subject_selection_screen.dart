import 'package:flutter/material.dart';
import 'home_screen.dart';

class SubjectSelectionScreen extends StatelessWidget {
  final List<String> subjects = [
    "Math",
    "History",
    "Arts",
    "Biology",
    "Chemistry",
    "IT",
    "Computer Science",
    "Geography",
  ];

  SubjectSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose a Subject")),
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(subjects[index]),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(subject: subjects[index]),
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
