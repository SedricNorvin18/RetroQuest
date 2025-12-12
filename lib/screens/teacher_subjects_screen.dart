import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retroquest/screens/quiz_screen.dart';
import 'package:retroquest/services/firestore_service.dart';
import 'package:retroquest/screens/arcade_quiz_screen.dart'; // <--- NEW IMPORT
import 'package:retroquest/screens/dungeon_quiz_screen.dart';

class TeacherSubjectsScreen extends StatelessWidget {
  final String teacherId;
  final String teacherName;

  const TeacherSubjectsScreen(
      {super.key, required this.teacherId, required this.teacherName});

  // START: Methods copied from StudentDashboardScreen to enable quiz mode selection
  void _showQuizModeSelection(
      BuildContext context, String subjectName, String teacherId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2336),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: Colors.pinkAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                "SELECT MODE",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PressStart2P',
                    fontSize: 14),
              ),
              const Divider(color: Colors.white38),
              const SizedBox(height: 10),

              // 1. Classic Quiz Button
              ElevatedButton.icon(
                icon: const Icon(Icons.class_outlined, color: Colors.black),
                label: const Text('Classic Quiz'),
                onPressed: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                          subject: subjectName, teacherId: teacherId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 12, fontFamily: 'PressStart2P'),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Dungeon Mode Button
              ElevatedButton.icon(
                icon: const Icon(Icons.fort, color: Colors.white),
                label: const Text('Dungeon Battle (Typing)'),
                onPressed: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DungeonQuizScreen(
                          subject: subjectName, teacherId: teacherId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // RPG Theme color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 12, fontFamily: 'PressStart2P'),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "RETRO BLASTER (ARCADE)",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.yellowAccent,
                    fontFamily: 'PressStart2P',
                    fontSize: 10),
              ),
              const SizedBox(height: 10),

              // 2. Arcade Difficulty Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDifficultyButton(
                      context, 'Easy', Colors.green, subjectName, teacherId),
                  const SizedBox(width: 8),
                  _buildDifficultyButton(
                      context, 'Normal', Colors.orange, subjectName, teacherId),
                  const SizedBox(width: 8),
                  _buildDifficultyButton(
                      context, 'Hard', Colors.red, subjectName, teacherId),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Helper widget for difficulty buttons
  Widget _buildDifficultyButton(BuildContext context, String level, Color color,
      String subject, String teacherId) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context); // Close modal
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArcadeQuizScreen(
                  subject: subject,
                  teacherId: teacherId,
                  difficulty: level // Pass the selected difficulty
                  ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          level,
          style: const TextStyle(fontFamily: 'PressStart2P', fontSize: 10),
        ),
      ),
    );
  }
  // END: Methods copied from StudentDashboardScreen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2336),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          teacherName,
          style: const TextStyle(
              fontFamily: "PressStart2P", color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/retro_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withAlpha(153)),
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().getTeacherQuizzes(teacherId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No subjects found for this teacher.',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'PressStart2P')));
              }

              final subjects = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  final subjectName = subject.id;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    color: Colors.black54,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(subjectName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'PressStart2P')),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.greenAccent),
                      onTap: () {
                        // FIX: Call the mode selection dialog instead of navigating directly
                        _showQuizModeSelection(context, subjectName, teacherId);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
