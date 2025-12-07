import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _userRole;

  // Stats
  int _quizCount = 0;
  int _studentCount = 0;
  int _quizzesTaken = 0;
  double _averageScore = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndStats();
  }

  Future<void> _loadUserDataAndStats() async {
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (userDoc.exists) {
        _userData = userDoc.data();
        _userRole = _userData?['role'];
      }

      if (_userRole == 'teacher') {
        final subjectSnapshot = await FirebaseFirestore.instance
            .collection('subjects')
            .where('teacherId', isEqualTo: _user!.uid)
            .get();
        _quizCount = subjectSnapshot.docs.length;

        final studentSnapshot = await FirebaseFirestore.instance
            .collection('enrolledStudents')
            .where('teacherUid', isEqualTo: _user!.uid)
            .get();
        _studentCount = studentSnapshot.docs.length;
      } else if (_userRole == 'student') {
        final historySnapshot = await FirebaseFirestore.instance
            .collection('quiz_history')
            .where('userId', isEqualTo: _user!.uid)
            .get();
        _quizzesTaken = historySnapshot.docs.length;

        if (_quizzesTaken > 0) {
          double totalScore = 0;
          for (var doc in historySnapshot.docs) {
            totalScore += doc.data()['score'] ?? 0;
          }
          _averageScore = totalScore / _quizzesTaken;
        }
      }
    } catch (e) {
      debugPrint("Error loading profile data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
              fontFamily: "PressStart2P", color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.deepPurple.shade900.withAlpha(217),
        elevation: 0,
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
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent))
              : _user == null
                  ? const Center(child: Text('Not logged in.'))
                  : _buildProfileContent(),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final displayName =
        _userData?['displayName'] ?? _user!.displayName ?? 'No Name';
    final photoUrl = _userData?['photoURL'] ?? _user!.photoURL;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.black54,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white70)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 24,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_userRole != null)
                Chip(
                  label: Text(
                    _userRole == 'teacher' ? 'Teacher' : 'Student',
                    style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 12,
                        color: Colors.black),
                  ),
                  backgroundColor: Colors.greenAccent,
                ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'Statistics',
                style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 20,
                    color: Colors.white),
              ),
              const SizedBox(height: 24),
              _buildStatsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_userRole == 'teacher') {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildStatCard('Quizzes Created', _quizCount.toString()),
          _buildStatCard('Students Enrolled', _studentCount.toString()),
        ],
      );
    } else if (_userRole == 'student') {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildStatCard('Quizzes Taken', _quizzesTaken.toString()),
          _buildStatCard(
              'Average Score', '${_averageScore.toStringAsFixed(1)}%'),
        ],
      );
    } else {
      return const Text('No stats available for this user.',
          style: TextStyle(color: Colors.white));
    }
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      color: Colors.black54,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 28,
                  color: Colors.greenAccent),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}