import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String userName;
  final int score;
  final Timestamp? timestamp; // Add this line

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.score,
    this.timestamp, // Add this line
  });
}
