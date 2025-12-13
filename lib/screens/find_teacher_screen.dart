import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retroquest/services/firestore_service.dart';

class FindTeacherScreen extends StatefulWidget {
  const FindTeacherScreen({super.key});

  @override
  FindTeacherScreenState createState() => FindTeacherScreenState();
}

class FindTeacherScreenState extends State<FindTeacherScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Stream<QuerySnapshot>? _teacherStream;
  List<QueryDocumentSnapshot>? _searchResults;
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _teacherStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots();
  }

  void _sendEnrollmentRequest(String teacherUid, String teacherEmail) async {
    final studentUid = FirebaseAuth.instance.currentUser!.uid;
    final studentEmail = FirebaseAuth.instance.currentUser!.email!;

    try {
      await _firestoreService.createEnrollmentRequest(
        studentUid: studentUid,
        teacherUid: teacherUid,
        studentEmail: studentEmail,
        teacherEmail: teacherEmail,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Enrollment request sent!',
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
              'Error sending request: $e',
              style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: Colors.white),
            )),
      );
    }
  }

  void _runSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nameQuery = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final emailQuery = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final results = await Future.wait([nameQuery, emailQuery]);
      final nameDocs = results[0].docs;
      final emailDocs = results[1].docs;

      final allDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in nameDocs) {
        allDocs[doc.id] = doc;
      }
      for (var doc in emailDocs) {
        allDocs[doc.id] = doc;
      }

      if (mounted) {
        setState(() {
          _searchResults = allDocs.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(
                'Error searching: ${e.toString()}',
                style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 12,
                    color: Colors.white),
              )),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2336),
      appBar: AppBar(
        title: const Text(
          'Find a Teacher',
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                      filled: true,
                      fillColor: const Color(0xFF2A2D49),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 20.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                            color: Colors.pinkAccent, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                            color: Colors.pinkAccent.withValues(alpha: 0.5),
                            width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                            color: Colors.pinkAccent, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        _runSearch(value.trim());
                      });
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_searchQuery.isEmpty) {
      return StreamBuilder<QuerySnapshot>(
        stream: _teacherStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.pinkAccent)));
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No teachers found',
                    style: TextStyle(
                        color: Colors.white70, fontFamily: 'PressStart2P')));
          }

          return _buildTeacherList(snapshot.data!.docs);
        },
      );
    } else {
      if (_isLoading) {
        return const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent)));
      }

      if (_searchResults == null || _searchResults!.isEmpty) {
        return const Center(
            child: Text('No teachers found',
                style: TextStyle(
                    color: Colors.white70, fontFamily: 'PressStart2P')));
      }

      return _buildTeacherList(_searchResults!);
    }
  }

  Widget _buildTeacherList(List<QueryDocumentSnapshot> teachers) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        final data = teacher.data() as Map<String, dynamic>;
        final String displayName =
            (data['displayName'] != null && data['displayName'].isNotEmpty)
                ? data['displayName']
                : data['email'];
        final String photoURL = data['photoURL'] ?? '';

        return Card(
          color: const Color(0xFF2A2D49),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side:
                BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5), width: 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.pinkAccent,
              backgroundImage:
                  photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
              child: photoURL.isEmpty
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'PressStart2P',
                fontSize: 12,
              ),
            ),
            subtitle: Text(
              teacher['email'],
              style:
                  TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () =>
                  _sendEnrollmentRequest(teacher.id, teacher['email']),
              child: const Text(
                'Enroll',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 10,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
