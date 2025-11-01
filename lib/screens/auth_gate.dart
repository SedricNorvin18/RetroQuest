import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retroquest/screens/login_screen.dart';
import 'package:retroquest/screens/student_dashboard_screen.dart';
import 'package:retroquest/screens/teacher_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (userDocSnapshot.hasError) {
              return const Scaffold(body: Center(child: Text("Error fetching user data.")));
            }

            if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
              final userRole = (userDocSnapshot.data!.data() as Map<String, dynamic>)['role'];
              if (userRole == 'teacher') {
                return const TeacherDashboardScreen();
              } else {
                return const StudentDashboardScreen();
              }
            }
            
            return const LoginScreen();
          },
        );
      },
    );
  }
}
