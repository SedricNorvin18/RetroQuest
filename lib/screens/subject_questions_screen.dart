import 'package:flutter/material.dart';

class SubjectScreen extends StatelessWidget {
  final String subject;
  const SubjectScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "$subject Questions",
          style: const TextStyle(
            fontFamily: "PressStart2P",
            fontSize: 12,
            color: Colors.greenAccent,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.greenAccent),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade900, Colors.pink.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.quiz_rounded,
                  color: Colors.pinkAccent,
                  size: 60,
                ),
                SizedBox(height: 20),
                Text(
                  "Here you will see\nquestions for this subject.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "PressStart2P",
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "COMING SOON...",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: "PressStart2P",
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
