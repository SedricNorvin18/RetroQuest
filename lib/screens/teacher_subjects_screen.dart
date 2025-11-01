import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retroquest/models/db_connect.dart';
import 'package:retroquest/screens/quiz_screen.dart';

class TeacherSubjectsScreen extends StatefulWidget {
  final String teacherId;

  const TeacherSubjectsScreen({super.key, required this.teacherId});

  @override
  State<TeacherSubjectsScreen> createState() => _TeacherSubjectsScreenState();
}

class _TeacherSubjectsScreenState extends State<TeacherSubjectsScreen> {
  final DbConnect _db = DbConnect();
  List<String> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
    });
    final subjects = await _db.fetchSubjects(teacherId: widget.teacherId);
    setState(() {
      _subjects = subjects;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const Center(
                  child: Text('This teacher has not created any subjects yet.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadSubjects,
                  child: ListView.builder(
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      return ListTile(
                        title: Text(subject),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(subject: subject),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
