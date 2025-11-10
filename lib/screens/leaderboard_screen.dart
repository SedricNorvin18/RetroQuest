
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _leaderboardEntries;

  @override
  void initState() {
    super.initState();
    _leaderboardEntries = _getLeaderboardEntries();
  }

  Future<List<LeaderboardEntry>> _getLeaderboardEntries() async {
    // 1. Fetch all quiz attempts
    final attemptsSnapshot = await FirebaseFirestore.instance.collection('quiz_attempts').get();

    // 2. Aggregate scores by user
    final Map<String, int> userScores = {};
    for (var attempt in attemptsSnapshot.docs) {
      final data = attempt.data();

      // Add robust check for userId and score
      if (data.containsKey('userId') &&
          data['userId'] is String &&
          (data['userId'] as String).isNotEmpty) {
        final userId = data['userId'] as String;
        final score = (data['score'] ?? 0) as int;

        if (userScores.containsKey(userId)) {
          userScores[userId] = userScores[userId]! + score;
        } else {
          userScores[userId] = score;
        }
      }
    }

    // 3. Fetch user data for the top scorers
    final userIds = userScores.keys.toList();
    if (userIds.isEmpty) {
      return [];
    }

    final List<LeaderboardEntry> leaderboardEntries = [];
    // Firestore 'in' query supports a maximum of 10 elements.
    // We need to fetch users in batches.
    for (var i = 0; i < userIds.length; i += 10) {
      final batchIds =
          userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10);
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();
      final usersData = {for (var doc in usersSnapshot.docs) doc.id: doc.data()};

      for (var userId in batchIds) {
        final score = userScores[userId]!;
        final userName = usersData[userId]?['displayName'] ?? 'Unknown Player';
        leaderboardEntries.add(
            LeaderboardEntry(userId: userId, userName: userName, score: score));
      }
    }

    // 4. Sort by score
    leaderboardEntries.sort((a, b) => b.score.compareTo(a.score));

    return leaderboardEntries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Leaderboard',
            style: TextStyle(fontFamily: 'PressStart2P', color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _leaderboardEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No leaderboard data available.',
                    style: TextStyle(
                        color: Colors.white, fontFamily: 'PressStart2P')));
          }

          final entries = snapshot.data!;

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'PressStart2P')),
                title: Text(entry.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PressStart2P')),
                trailing: Text(entry.score.toString(),
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontFamily: 'PressStart2P')),
              );
            },
          );
        },
      ),
    );
  }
}
