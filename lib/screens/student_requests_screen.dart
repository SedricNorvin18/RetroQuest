import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retroquest/models/enrollment_request.dart';
import 'package:retroquest/services/firestore_service.dart';

class StudentRequestsScreen extends StatelessWidget {
  const StudentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
            child: Text('You need to be logged in.',
                style: TextStyle(fontFamily: 'PressStart2P'))),
      );
    }
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF1E2336),
      appBar: AppBar(
        title: const Text(
          'My Enrollment Requests',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/retro_bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<List<EnrollmentRequest>>(
              stream: firestoreService.getEnrollmentRequestsForStudent(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.pinkAccent)));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontFamily: 'PressStart2P')));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('You have not sent any requests.',
                          style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'PressStart2P')));
                }

                final requests = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: firestoreService.getUserProfile(request.teacherUid),
                      builder: (context, teacherSnapshot) {
                        String teacherName = request.teacherEmail;
                        String? teacherPhotoUrl;

                        if (teacherSnapshot.connectionState ==
                                ConnectionState.done &&
                            teacherSnapshot.hasData &&
                            teacherSnapshot.data!.exists) {
                          final teacherData = teacherSnapshot.data!.data()
                              as Map<String, dynamic>?;
                          teacherName = teacherData?['displayName'] ??
                              request.teacherEmail;
                          teacherPhotoUrl = teacherData?['photoURL'] ??
                              teacherData?['profilePicUrl'];
                        }

                        return Card(
                          color: const Color(0xFF2A2D49).withValues(alpha: 0.8),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                              color: _getStatusColor(request.status)
                                  .withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.pinkAccent,
                                  backgroundImage: (teacherPhotoUrl != null &&
                                          teacherPhotoUrl.isNotEmpty)
                                      ? NetworkImage(teacherPhotoUrl)
                                      : null,
                                  child: (teacherPhotoUrl == null ||
                                          teacherPhotoUrl.isEmpty)
                                      ? const Icon(Icons.person, size: 22)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'To: $teacherName',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Status: ${request.status.toUpperCase()}',
                                        style: TextStyle(
                                          fontFamily: 'PressStart2P',
                                          fontSize: 10,
                                          color: _getStatusColor(request.status),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(request.status),
                                      color: _getStatusColor(request.status),
                                      size: 32,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.white70),
                                      onPressed: () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        await firestoreService
                                            .deleteEnrollmentRequest(request.id);
                                        messenger.showSnackBar(
                                          const SnackBar(
                                              content: Text('Request deleted')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'accepted':
        return Colors.greenAccent;
      case 'declined':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'declined':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
