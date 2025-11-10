import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retroquest/screens/history_screen.dart';
import 'package:retroquest/screens/leaderboard_screen.dart';
import 'package:retroquest/screens/quiz_screen.dart';
import 'package:retroquest/screens/teacher_subjects_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String _currentView =
      'dashboard'; // 'dashboard', 'browse', 'history', or 'leaderboard'
  String _browseView = 'main'; // 'main', 'subjects', or 'teachers'

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate will handle navigation
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
        Row(
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
                future: FirebaseFirestore.instance.collection('users').doc(_user?.uid).get(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  // if (snapshot.connectionState == ConnectionState.waiting) {
                  //    return const Text(
                  //       'Loading...',
                  //       style: TextStyle(
                  //           fontWeight: FontWeight.bold,
                  //           fontSize: 16,
                  //           color: Colors.white),
                  //       overflow: TextOverflow.ellipsis,
                  //     );
                  // }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data() == null) {
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
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      );
                  }
                  
                  Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                  
                  // Robust name fetching to support old and new data structures
                  String firstName = data['first'] ?? data['firstName'] ?? '';
                  String lastName = data['last'] ?? data['lastName'] ?? '';
                  String displayName = '$firstName $lastName'.trim();

                  if (displayName.isEmpty) {
                    displayName = data['displayName'] ?? data['name'] ?? 'Student';
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
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNavSectionTitle('PLAY'),
        _buildNavItem(Icons.play_arrow_outlined, 'Active',
            isSelected: false, onTap: () {}),
        _buildNavItem(Icons.search_outlined, 'Browse',
            isSelected: _currentView == 'browse', onTap: _showBrowseView),
        _buildNavItem(Icons.history_outlined, 'History',
            isSelected: _currentView == 'history', onTap: _showHistoryView),
        _buildNavItem(Icons.leaderboard_outlined, 'Leaderboard',
            isSelected: _currentView == 'leaderboard',
            onTap: _showLeaderboardView),
        const SizedBox(height: 24),
        _buildNavSectionTitle('PRODUCT'),
        _buildNavItem(Icons.help_outline, 'Help',
            isSelected: false, onTap: () {}),
        const Spacer(),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                      subtitle: const Text('by Unknown Teacher',
                          style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.greenAccent),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                QuizScreen(subject: subjectName),
                          ),
                        );
                      },
                    ),
                  );
                }

                final teacherId = subjectData['teacherId'];
                final teacherData = teachersMap[teacherId];

                final teacherName = _getTeacherName(teacherData);

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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuizScreen(subject: subjectName),
                        ),
                      );
                    },
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
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.greenAccent),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(subject: subjectName),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherSubjectsScreen(
                          teacherId: teacher.id, teacherName: teacherName),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
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
        leading: Icon(icon,
            color: isSelected ? Colors.white : Colors.grey.shade400),
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
          style: TextStyle(color: Colors.grey.shade400, fontFamily: 'PressStart2P')),
      onTap: _logout,
      dense: true,
    );
  }
}
