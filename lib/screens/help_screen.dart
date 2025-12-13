import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help for Students'),
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
              'How to Use RetroQuest',
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
                  'The main dashboard shows your progress and gives you quick access to browse quizzes.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.school,
              title: 'Enrollments',
              content:
                  'Here you can find teachers to enroll with. You need to be enrolled with a teacher to access their quizzes. You can also view your pending enrollment requests.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.search,
              title: 'Browse',
              content:
                  'You can browse quizzes by subject or by teacher. Select a quiz to start playing.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.games,
              title: 'Quiz Modes',
              content:
                  'After selecting a quiz, you can choose from different game modes:\n'
                  '- Classic Quiz: A standard multiple-choice, true or false, fill in blank and short answer quiz.\n'
                  '- Dungeon Battle: A typing-based game where you defeat monsters by typing the answer correctly.\n'
                  '- Retro Blaster (Arcade): An arcade shooter where you answer questions to power up your ship. You can hold the directional buttons to move the ship and hold the fire button for rapid fire.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.history,
              title: 'History',
              content: 'View your past quiz attempts and scores.',
            ),
            _buildHelpCard(
              context,
              icon: Icons.leaderboard,
              title: 'Leaderboard',
              content:
                  'See how you rank against other players in different quizzes.',
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
