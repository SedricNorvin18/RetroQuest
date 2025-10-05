import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import '../models/subjects.dart';
import 'login_screen.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  String? fullName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final firstName = doc.data()?['firstName'] ?? '';
        final lastName = doc.data()?['lastName'] ?? '';
        setState(() {
          fullName = "$firstName $lastName".trim();
        });
      }
    } catch (e) {
      print("Error fetching name: $e");
    } finally {
      setState(() => isLoading = false);
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
              fontSize: 10),
        ),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(
              color: Colors.white70,
              fontFamily: "PressStart2P",
              fontSize: 8,
              letterSpacing: 1),
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
        title: Text(
          isLoading
              ? "Loading..."
              : (fullName != null
                  ? "Welcome, $fullName 👋"
                  : "Select Subject"),
          style: const TextStyle(
            fontFamily: "PressStart2P",
            fontSize: 12,
            color: Colors.greenAccent,
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent, width: 1.5),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: const Icon(Icons.book_rounded,
                    color: Colors.pinkAccent, size: 30),
                title: Text(
                  subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: "PressStart2P",
                    fontSize: 9,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Colors.greenAccent, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(subject: subject),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
