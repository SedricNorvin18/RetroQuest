import 'package:flutter/material.dart';

class TeacherHelpScreen extends StatelessWidget {
  const TeacherHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help for Teachers'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E2336),
              Color(0xFF2C3E50),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'How to Use RetroQuest for Teachers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'PressStart2P',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildHelpCard(
              context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              content:
                  'The main dashboard gives you an overview of your subjects and recent activity.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.quiz,
              title: 'My Quizzes',
              content:
                  'This is where you can create and manage your subjects and quizzes. Click on a subject to add, edit, or delete questions.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.add_circle_outline,
              title: 'Adding Questions',
              content:
                  'Inside a subject, you can add new questions. Each question needs a question text, a correct answer, and three incorrect options.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.how_to_reg,
              title: 'Enrollment Requests',
              content:
                  'Here you can see pending enrollment requests from students. You can approve or deny them.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.analytics,
              title: 'Analytics',
              content:
                  'View analytics for your quizzes to see how your students are performing.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.account_circle,
              title: 'Profile & Account',
              content:
                  'Click on your profile picture at the top of the sidebar to view your profile or manage your account settings.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: const Color(0xFF2C3E50).withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
          color: Colors.pinkAccent.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.pinkAccent, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                    fontFamily: 'PressStart2P',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
