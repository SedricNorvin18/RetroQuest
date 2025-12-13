import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retroquest/screens/account_settings_screen.dart';
import 'package:retroquest/screens/find_teacher_screen.dart';
import 'package:retroquest/screens/help_screen.dart';
import 'package:retroquest/screens/history_screen.dart';
import 'package:retroquest/screens/leaderboard_screen.dart';
import 'package:retroquest/screens/profile_screen.dart';
import 'package:retroquest/screens/quiz_screen.dart';
import 'package:retroquest/screens/student_requests_screen.dart';
import 'package:retroquest/screens/teacher_subjects_screen.dart';
import 'package:retroquest/services/firestore_service.dart';
import 'package:retroquest/models/enrolled_student.dart';
import 'package:retroquest/screens/arcade_quiz_screen.dart';
import 'package:retroquest/screens/dungeon_quiz_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String _currentView =
      'dashboard'; // 'dashboard', 'browse', 'history', or 'leaderboard' or 'enrollments' //
  String _browseView = 'main'; // 'main', 'subjects', or 'teachers'

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate will handle navigation
  }

  Future<String> _getTeacherDisplayName(String teacherUid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(teacherUid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        return _getTeacherName(data);
      }
      return 'Unknown Teacher (UID: $teacherUid)';
    } catch (e) {
      return 'Error fetching teacher name';
    }
  }

  void _showEnrollmentsView() {
    setState(() {
      _currentView = 'enrollments';
    });
  }

  void _showBrowseView() {
    setState(() {
      _currentView = 'browse';
      _browseView = 'main';
    });
  }

  void _showHistoryView() {
    setState(() {
      _currentView = 'history';
    });
  }

  void _showLeaderboardView() {
    setState(() {
      _currentView = 'leaderboard';
    });
  }

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

  // Helper function to get teacher name from various possible fields
  String _getTeacherName(Map<String, dynamic>? teacherData) {
    if (teacherData == null) {
      return 'Unknown Teacher';
    }
    if (teacherData.containsKey('displayName') &&
        teacherData['displayName'] != null) {
      return teacherData['displayName'];
    }
    if (teacherData.containsKey('name') && teacherData['name'] != null) {
      return teacherData['name'];
    }
    if (teacherData.containsKey('first') &&
        teacherData.containsKey('last') &&
        teacherData['first'] != null &&
        teacherData['last'] != null) {
      return '${teacherData['first']} ${teacherData['last']}';
    }
    return 'Unknown Teacher';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2336),
      body: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/retro_bg.jpg',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withAlpha(153)),
            (constraints.maxWidth < 800)
                ? _buildMobileLayout()
                : _buildWebLayout(),
          ],
        );
      }),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        Container(
          width: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade900.withAlpha(217),
                Colors.pink.shade700.withAlpha(217),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _buildSidebar(),
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900.withAlpha(217),
        elevation: 0,
        title: Text(
          _currentView == 'browse'
              ? 'Browse'
              : _currentView == 'history'
                  ? 'History'
                  : _currentView == 'leaderboard'
                      ? 'Leaderboard'
                      : "RetroQuest",
          style: const TextStyle(
              fontFamily: "PressStart2P", color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _currentView != 'dashboard'
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                      if (_browseView != 'main') {
                        _browseView = 'main';
                      } else {
                        _currentView = 'dashboard';
                      }
                    }))
            : null,
      ),
      drawer: _currentView == 'dashboard'
          ? Drawer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade900.withAlpha(217),
                      Colors.pink.shade700.withAlpha(217),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _buildSidebar(),
              ),
            )
          : null,
      body: _buildContent(),
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'account') {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen()));
            } else if (value == 'profile') {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ProfileScreen()));
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'account',
              child: Text('Account'),
            ),
            const PopupMenuItem<String>(
              value: 'profile',
              child: Text('View profile'),
            ),
          ],
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : null,
                child: _user?.photoURL == null
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user?.uid)
                      .get(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data?.data() == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.displayName ?? 'Student',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'RetroQuest Player',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      );
                    }

                    Map<String, dynamic> data =
                        snapshot.data!.data() as Map<String, dynamic>;

                    String firstName = data['first'] ?? data['firstName'] ?? '';
                    String lastName = data['last'] ?? data['lastName'] ?? '';
                    String displayName = '$firstName $lastName'.trim();

                    if (displayName.isEmpty) {
                      displayName =
                          data['displayName'] ?? data['name'] ?? 'Student';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'RetroQuest Player',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildNavSectionTitle('PLAY'),
        _buildNavItem(Icons.group_outlined, 'Enrollments', // <--- ADD THIS
            isSelected: _currentView == 'enrollments', // <--- ADD THIS
            onTap: _showEnrollmentsView), // <--- ADD THIS
        _buildNavItem(Icons.search_outlined, 'Browse',
            isSelected: _currentView == 'browse', onTap: _showBrowseView),
        _buildNavItem(Icons.history_outlined, 'History',
            isSelected: _currentView == 'history', onTap: _showHistoryView),
        _buildNavItem(Icons.leaderboard_outlined, 'Leaderboard',
            isSelected: _currentView == 'leaderboard',
            onTap: _showLeaderboardView),
        const Spacer(),
        _buildNavSectionTitle('PRODUCT'),
        _buildNavItem(
          Icons.help_outline,
          'Help',
          isSelected: false,
          onTap: () {
            // This is the key part: use Navigator.push to navigate to the HelpScreen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const HelpScreen(), // The screen you want to go to
              ),
            );
          },
        ),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildContent() {
    if (_currentView == 'browse') {
      return _buildBrowseView();
    }
    if (_currentView == 'history') {
      return const HistoryScreen();
    }
    if (_currentView == 'leaderboard') {
      return const LeaderboardScreen();
    }
    if (_currentView == 'enrollments') {
      // <--- ADD THIS
      return _buildEnrollmentsView(); // <--- ADD THIS
    }
    return _buildDashboardContent();
  }

  Widget _buildDashboardContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ready to Play?',
            style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'PressStart2P'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Browse subjects and teachers to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showBrowseView,
            icon: const Icon(Icons.search, color: Colors.black),
            label: const Text('Browse Quizzes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'PressStart2P'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBrowseView() {
    switch (_browseView) {
      case 'subjects':
        return _buildSubjectsList();
      case 'teachers':
        return _buildTeachersList();
      case 'main':
      default:
        return _buildBrowseMenu();
    }
  }

  Widget _buildBrowseMenu() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () => setState(() => _browseView = 'subjects'),
            icon: const Icon(Icons.library_books, color: Colors.black),
            label: const Text('Browse by Subject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'PressStart2P'),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _browseView = 'teachers'),
            icon: const Icon(Icons.person_search, color: Colors.black),
            label: const Text('Browse by Teacher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'PressStart2P'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subjects')
          .orderBy('order')
          .snapshots(),
      builder: (context, subjectSnapshot) {
        if (subjectSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (subjectSnapshot.hasError) {
          return Center(child: Text('Error: ${subjectSnapshot.error}'));
        }
        if (!subjectSnapshot.hasData || subjectSnapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No quizzes found.',
                  style: TextStyle(
                      color: Colors.white, fontFamily: 'PressStart2P')));
        }

        final subjects = subjectSnapshot.data!.docs;
        final teacherIds = subjects
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data != null &&
                  data.containsKey('teacherId') &&
                  data['teacherId'] != null) {
                return data['teacherId'];
              }
              return null;
            })
            .where((id) => id != null)
            .toSet()
            .toList();

        if (teacherIds.isEmpty) {
          return _buildSubjectListWithoutTeachers(subjects);
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(teacherIds
              .map((id) =>
                  FirebaseFirestore.instance.collection('users').doc(id).get())
              .toList()),
          builder: (context, teacherSnapshot) {
            if (teacherSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (teacherSnapshot.hasError) {
              return Center(child: Text('Error: ${teacherSnapshot.error}'));
            }

            final teachers = teacherSnapshot.data ?? [];
            final teachersMap = {
              for (var doc in teachers)
                if (doc.exists) doc.id: doc.data() as Map<String, dynamic>?
            };

            return ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final subjectData = subject.data() as Map<String, dynamic>;
                final subjectName = subject.id;

                if (!subjectData.containsKey('teacherId') ||
                    subjectData['teacherId'] == null) {
                  // NEW LOGIC FOR NO TEACHER ID: Prevent access.
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
                      subtitle: const Text('by Unknown Teacher (Unprotected)',
                          style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.lock_outline,
                          color: Colors.redAccent),
                      onTap: () {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'This quiz is not linked to a teacher and cannot be accessed.')),
                          );
                        }
                      },
                    ),
                  );
                }

                final teacherId = subjectData['teacherId'];
                final teacherData = teachersMap[teacherId];

                final teacherName = _getTeacherName(teacherData);
                final studentUid = _user?.uid; // <--- ADD THIS

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
                    subtitle: Text('by $teacherName',
                        style: const TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.greenAccent),
                    onTap: () async {
                      // <--- MODIFIED TO ASYNC
                      if (studentUid == null) return; // Should not happen

                      final isEnrolled =
                          await FirestoreService() // <--- ADD CHECK
                              .isStudentEnrolled(
                                  teacherUid: teacherId,
                                  studentUid: studentUid);

                      if (!context.mounted) return;

                      if (isEnrolled) {
                        // Show the mode selection dialog instead of navigating directly
                        _showQuizModeSelection(context, subjectName, teacherId);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'You must be enrolled with $teacherName to access this quiz.')),
                          );
                        }
                      }
                    }, // <--- END OF MODIFIED onTap
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectListWithoutTeachers(
      List<QueryDocumentSnapshot> subjects) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(subjectName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'PressStart2P')),
            subtitle: const Text('by Unknown Teacher',
                style: TextStyle(color: Colors.white70)),
            trailing:
                const Icon(Icons.arrow_forward_ios, color: Colors.greenAccent),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    subject: subjectName,
                    teacherId: '',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTeachersList() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No teachers found.',
                  style: TextStyle(
                      color: Colors.white, fontFamily: 'PressStart2P')));
        }

        final teachers = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: teachers.length,
          itemBuilder: (context, index) {
            final teacher = teachers[index];
            final teacherData = teacher.data() as Map<String, dynamic>?;
            final teacherName = _getTeacherName(teacherData);
            final studentUid = _user?.uid; // <--- ADD THIS

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              color: Colors.black54,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(teacherName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'PressStart2P')),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Colors.greenAccent),
                onTap: () async {
                  if (studentUid == null) return; // Should not happen

                  final isEnrolled = await FirestoreService() // <--- ADD CHECK
                      .isStudentEnrolled(
                          teacherUid: teacher.id, studentUid: studentUid);

                  if (!context.mounted) return;

                  if (isEnrolled) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherSubjectsScreen(
                            teacherId: teacher.id, teacherName: teacherName),
                      ),
                    );
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'You must be enrolled with $teacherName to view their quizzes.')),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEnrollmentsView() {
    final studentUid = _user?.uid;
    if (studentUid == null) {
      return const Center(
          child: Text('User not logged in.',
              style:
                  TextStyle(color: Colors.white, fontFamily: 'PressStart2P')));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Button: Find a Teacher
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const FindTeacherScreen()), // Navigate to FindTeacherScreen
              );
            },
            icon: const Icon(Icons.person_search, color: Colors.black),
            label: const Text('Find a Teacher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellowAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'PressStart2P'),
            ),
          ),
          const SizedBox(height: 16),

          // New Button: My Requests
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const StudentRequestsScreen()), // Navigate to StudentRequestsScreen
              );
            },
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text('View My Sent Requests'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'PressStart2P'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'MY ENROLLED TEACHERS',
            style: TextStyle(
                color: Colors.pinkAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'PressStart2P'),
          ),
          const Divider(color: Colors.white38),

          // Existing StreamBuilder for Enrolled Teachers
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('enrolledStudents')
                  .where('studentUid', isEqualTo: studentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final enrollments = snapshot.data!.docs
                    .map((doc) => EnrolledStudent.fromFirestore(doc))
                    .toList();

                if (enrollments.isEmpty) {
                  return const Center(
                      child: Text('Not enrolled with any teacher.',
                          style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'PressStart2P',
                              fontSize: 10)));
                }

                return ListView.builder(
                  // physics: const NeverScrollableScrollPhysics(), // Use this if you wrap it in a SingleChildScrollView
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = enrollments[index];
                    return FutureBuilder<String>(
                      future: _getTeacherDisplayName(enrollment.teacherUid),
                      builder: (context, teacherNameSnapshot) {
                        final teacherName =
                            teacherNameSnapshot.data ?? 'Loading...';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          color: Colors.black54,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.school,
                                color: Colors.greenAccent),
                            title: Text(teacherName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'PressStart2P')),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title,
      {bool isSelected = false, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black54 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading:
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade400),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'PressStart2P',
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.grey.shade400),
      title: Text('Logout',
          style: TextStyle(
              color: Colors.grey.shade400, fontFamily: 'PressStart2P')),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                TextButton(
                  child: const Text('Logout'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog first
                    _logout(); // Then execute the logout function
                  },
                ),
              ],
            );
          },
        );
      },
      dense: true,
    );
  }
}
