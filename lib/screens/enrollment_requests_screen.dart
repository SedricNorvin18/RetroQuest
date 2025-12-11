import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retroquest/models/enrollment_request.dart';
import 'package:retroquest/services/firestore_service.dart';

class EnrollmentRequestsScreen extends StatefulWidget {
  const EnrollmentRequestsScreen({super.key});

  @override
  EnrollmentRequestsScreenState createState() =>
      EnrollmentRequestsScreenState();
}

class EnrollmentRequestsScreenState extends State<EnrollmentRequestsScreen> {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser!;

  void _acceptRequest(EnrollmentRequest request) async {
    try {
      await _firestoreService.enrollStudent(
        teacherUid: request.teacherUid,
        studentUid: request.studentUid,
        studentEmail: request.studentEmail,
      );
      await _firestoreService.updateEnrollmentRequestStatus(
          request.id, 'accepted');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Enrollment request accepted!',
              style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white),
            )),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Error accepting request: $e',
              style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white),
            )),
      );
    }
  }

  void _declineRequest(String requestId) async {
    try {
      await _firestoreService.updateEnrollmentRequestStatus(
          requestId, 'declined');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              'Enrollment request declined.',
              style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white),
            )),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Error declining request: $e',
              style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white),
            )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2336),
      appBar: AppBar(
        title: const Text(
          'Enrollment Requests',
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
        child: StreamBuilder<List<EnrollmentRequest>>(
          stream: _firestoreService.getPendingEnrollmentRequests(_user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'PressStart2P')));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.pinkAccent)));
            }

            if (snapshot.data!.isEmpty) {
              return const Center(
                  child: Text('No pending enrollment requests',
                      style: TextStyle(
                          color: Colors.white70, fontFamily: 'PressStart2P')));
            }

            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final request = snapshot.data![index];
                return FutureBuilder<DocumentSnapshot>(
                  future: _firestoreService.getUserProfile(request.studentUid),
                  builder: (context, userSnapshot) {
                    String displayName = request.studentEmail;
                    String? profilePicUrl;

                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>?;
                      displayName =
                          userData?['displayName'] ?? request.studentEmail;
                      profilePicUrl =
                          userData?['photoURL'] ?? userData?['profilePicUrl'];
                    }

                    return Card(
                      color: const Color(0xFF2A2D49),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                            color: Colors.blueAccent.withValues(alpha:0.5), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.pinkAccent,
                              backgroundImage: (profilePicUrl != null &&
                                      profilePicUrl.isNotEmpty)
                                  ? NetworkImage(profilePicUrl)
                                  : null,
                              child: (profilePicUrl == null ||
                                      profilePicUrl.isEmpty)
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request.studentEmail,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _buildActionButton(
                                  icon: Icons.check,
                                  color: Colors.green,
                                  onPressed: () => _acceptRequest(request),
                                ),
                                const SizedBox(width: 10),
                                _buildActionButton(
                                  icon: Icons.close,
                                  color: Colors.red,
                                  onPressed: () => _declineRequest(request.id),
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
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
      child: Icon(icon, size: 24),
    );
  }
}
