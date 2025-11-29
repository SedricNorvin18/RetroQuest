
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _selectedSubjectId != null
              ? '$_selectedSubjectId Leaderboard'
              : _selectedTeacherId != null
                  ? '${_selectedTeacherName ?? 'Teacher'}'' Subjects'
                  : 'Select a Teacher',
          style: const TextStyle(
              fontFamily: 'PressStart2P', color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: (_selectedTeacherId != null || _selectedSubjectId != null)
            ? BackButton(onPressed: () {
                setState(() {
                  if (_selectedSubjectId != null) {
                    _selectedSubjectId = null;
                  } else if (_selectedTeacherId != null) {
                    _selectedTeacherId = null;
                    _selectedTeacherName = null;
                  }
                });
              })
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedSubjectId != null) {
      return _buildLeaderboardView();
    } else if (_selectedTeacherId != null) {
      return _buildSubjectView();
    } else {
      return _buildTeacherView();
    }
  }

  Widget _buildTeacherView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No teachers found.',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          );
        }

        final teachers = snapshot.data!.docs;

        return ListView.builder(
          itemCount: teachers.length,
          itemBuilder: (context, index) {
            final teacher = teachers[index];
            final teacherName = teacher['displayName'] ?? 'Unknown Teacher';

            return _buildRetroCard(
              title: teacherName,
              onTap: () {
                setState(() {
                  _selectedTeacherId = teacher.id;
                  _selectedTeacherName = teacherName;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSubjectView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subjects')
          .where('teacherId', isEqualTo: _selectedTeacherId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No subjects found for this teacher.',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          );
        }

        final subjects = snapshot.data!.docs;

        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            final subjectName = subject.id; // Assuming subject ID is the name

            return _buildRetroCard(
              title: subjectName,
              onTap: () {
                setState(() {
                  _selectedSubjectId = subject.id;
                });
              },
            );
          },
        );
      },
    );
  }

  Future<List<LeaderboardEntry>> _getHighestScoresForSubject() async {
    if (_selectedSubjectId == null) {
      return [];
    }

    final attemptsSnapshot = await FirebaseFirestore.instance
        .collection('quiz_attempts')
        .where('subjectId', isEqualTo: _selectedSubjectId)
        .get();

    final Map<String, LeaderboardEntry> highestScoresPerStudent = {};

    for (var attempt in attemptsSnapshot.docs) {
      final data = attempt.data();
      final studentId = data['studentId'] as String?;
      final studentName = data['studentName'] as String? ?? 'Unknown Student';
      final score = (data['score'] ?? 0) as int;
      final timestamp = data['timestamp'] as Timestamp?;

      if (studentId != null && studentId.isNotEmpty) {
        if (!highestScoresPerStudent.containsKey(studentId) ||
            score > highestScoresPerStudent[studentId]!.score) {
          highestScoresPerStudent[studentId] = LeaderboardEntry(
            userId: studentId,
            userName: studentName,
            score: score,
            timestamp: timestamp,
          );
        }
      }
    }

    final List<LeaderboardEntry> leaderboardEntries = highestScoresPerStudent.values.toList();
    leaderboardEntries.sort((a, b) => b.score.compareTo(a.score)); // Sort by score descending

    return leaderboardEntries;
  }

  Widget _buildLeaderboardView() {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: _getHighestScoresForSubject(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No quiz attempts found for this subject.',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          );
        }

        final entries = snapshot.data!;

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = index + 1;

            return _buildLeaderboardTile(entry, rank);
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry, int rank) {
    final date = entry.timestamp != null
        ? DateFormat('MMM d, yyyy - h:mm a').format(entry.timestamp!.toDate())
        : 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Adjusted vertical margin
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjusted vertical padding
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.5 * 255).round()), // Fixed deprecated withOpacity
        borderRadius: BorderRadius.circular(8), // Slightly smaller border radius
        border: Border.all(color: Colors.cyanAccent, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.cyanAccent,
            blurRadius: 4, // Slightly smaller blur
            spreadRadius: 0.5, // Slightly smaller spread
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              color: Colors.white,
              fontSize: 18, // Slightly smaller font size
              shadows: [
                Shadow(color: Colors.cyan, blurRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 12), // Slightly smaller space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    color: Colors.white,
                    fontSize: 14, // Slightly smaller font size
                  ),
                ),
                const SizedBox(height: 2), // Smaller space
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    color: Colors.grey,
                    fontSize: 10, // Slightly smaller font size
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.score}',
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              color: Colors.yellowAccent,
              fontSize: 20, // Slightly smaller font size
              shadows: [
                Shadow(color: Colors.yellow, blurRadius: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroCard({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Adjusted vertical margin
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjusted vertical padding
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.5 * 255).round()), // Fixed deprecated withOpacity
          borderRadius: BorderRadius.circular(8), // Slightly smaller border radius
          border: Border.all(color: Colors.purpleAccent, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.purpleAccent,
              blurRadius: 4, // Slightly smaller blur
              spreadRadius: 0.5, // Slightly smaller spread
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.white,
                fontSize: 16, // Slightly smaller font size
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18, // Slightly smaller icon size
            ),
          ],
        ),
      ),
    );
  }
}
