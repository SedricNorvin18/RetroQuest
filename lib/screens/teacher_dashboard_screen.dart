import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retroquest/models/db_connect.dart';
import 'package:retroquest/screens/view_questions_screen.dart';
import 'login_screen.dart';
import 'view_subjects_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final DbConnect _db = DbConnect();
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
    });
    final subjects = await _db.fetchSubjects();
    setState(() {
      _subjects = subjects;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    if (!mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFFf7f7f7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: _user?.photoURL != null
                          ? NetworkImage(_user!.photoURL!)
                          : null,
                      child: _user?.photoURL == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.displayName ?? 'Teacher',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'QuizWhizzer Starter',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildUpgradeButton(),
                const SizedBox(height: 16),
                _buildNewQuizButton(),
                const SizedBox(height: 24),
                _buildNavSectionTitle('MANAGE'),
                _buildNavItem(Icons.quiz_outlined, 'Quizzes', isSelected: true),
                _buildNavItem(Icons.subject_outlined, 'Subjects'),
                _buildNavItem(Icons.map_outlined, 'Maps'),
                _buildNavItem(Icons.question_answer_outlined, 'Question Bank'),
                _buildNavItem(Icons.star_outline, 'Avatars'),
                _buildNavItem(Icons.group_outlined, 'Group'),
                const SizedBox(height: 24),
                _buildNavSectionTitle('PLAY'),
                _buildNavItem(Icons.play_arrow_outlined, 'Active'),
                _buildNavItem(Icons.bar_chart_outlined, 'Reports'),
                _buildNavItem(Icons.explore_outlined, 'Browse'),
                const Spacer(),
                _buildNavSectionTitle('PRODUCT'),
                _buildNavItem(Icons.notifications_none_outlined, 'What\'s new'),
                _buildNavItem(Icons.help_outline, 'Help'),
                const SizedBox(height: 16),
                _buildLogoutButton(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subjects.isEmpty
                    ? const Center(
                        child: Text(
                          'No subjects found. Create a subject to get started.',
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSubjects,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(subject,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ViewQuestionsScreen(subjectId: subject),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.upgrade, color: Color(0xFF28a745)),
      label: const Text(
        'Upgrade',
        style: TextStyle(color: Color(0xFF28a745), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNewQuizButton() {
    return ElevatedButton.icon(
      onPressed: () {
        if (mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ViewQuestionsScreen(
                        subjectId: 'flutter',
                      )));
        }
      },
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('New quiz'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF28a745),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNavSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withAlpha(26) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? const Color(0xFF28a745) : Colors.grey.shade700),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (title == 'Quizzes') {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ViewQuestionsScreen(
                        subjectId: 'flutter',
                      )),
            );
          } else if (title == 'Subjects') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewSubjectsScreen()),
            );
          }
        },
        dense: true,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.grey),
      title: const Text('Logout', style: TextStyle(color: Colors.black87)),
      onTap: _logout,
      dense: true,
    );
  }
}
