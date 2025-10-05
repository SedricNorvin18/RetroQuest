import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subject_screen.dart';
import 'login_screen.dart';

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

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
                fontSize: 8,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "LOG OUT",
              style: TextStyle(
                color: Colors.greenAccent,
                fontFamily: "PressStart2P",
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You have been logged out successfully.",
            style: TextStyle(
              fontFamily: "PressStart2P",
              fontSize: 8,
            ),
          ),
          backgroundColor: Colors.greenAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Get the current logged-in user
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
          style: TextStyle(
            fontFamily: "PressStart2P",
            fontSize: 14,
            color: Colors.greenAccent,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.greenAccent),
            onPressed: () => logout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "Logged in as: ${user.email}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: "PressStart2P",
                    fontSize: 8,
                  ),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(
                  fontFamily: "PressStart2P",
                  fontSize: 10,
                ),
              ),
              child: const Text("Go to Subjects"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SubjectScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
