import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'upload_question_screen.dart';
import '../models/subjects.dart';
import 'login_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen>
    with SingleTickerProviderStateMixin {
  String? fullName;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchUserName();

    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (doc.exists) {
      setState(() {
        fullName = "${doc['firstName']} ${doc['lastName']}";
      });
    }
  }

  Future<void> logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Confirm Logout",
          style: TextStyle(
            color: Colors.greenAccent,
            fontFamily: "PressStart2P",
            fontSize: 10,
          ),
        ),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(
            color: Colors.white70,
            fontFamily: "PressStart2P",
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "CANCEL",
              style: TextStyle(
                  color: Colors.pinkAccent,
                  fontFamily: "PressStart2P",
                  fontSize: 8),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "LOG OUT",
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: "PressStart2P",
                  fontSize: 8),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            fullName != null
                ? "Welcome, $fullName 👾"
                : "RetroQuest Teacher",
            style: const TextStyle(
              fontFamily: "PressStart2P",
              fontSize: 10,
              color: Colors.greenAccent,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.greenAccent),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade900, Colors.pink.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Profile avatar
            if (fullName != null)
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.greenAccent.withOpacity(0.8),
                child: Text(
                  fullName!.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontFamily: "PressStart2P",
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              "Choose a Subject to Upload 🎮",
              style: const TextStyle(
                fontFamily: "PressStart2P",
                fontSize: 8,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.pinkAccent.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.greenAccent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      leading: const Icon(Icons.videogame_asset,
                          color: Colors.pinkAccent),
                      title: Text(
                        subject,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: "PressStart2P",
                          fontSize: 10,
                        ),
                      ),
                      trailing: const Icon(Icons.upload_file,
                          color: Colors.greenAccent, size: 22),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UploadQuestionScreen(subject: subject),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
