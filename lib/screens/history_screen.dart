import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/quiz_attempt_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  StreamSubscription<QuerySnapshot<QuizAttempt>>? _subscription;
  Map<String, List<QuizAttempt>> _groupedAttempts = {};
  bool _isLoading = true;
  String? _error;
  String? _userRole;
  Map<String, String> _teacherNames = {};

  final Set<String> _pendingDeletions = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedAttempts = {};
  final Set<String> _expandedSubjects = {};

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndListenToAttempts();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserRoleAndListenToAttempts() async {
    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'You are not logged in.';
        });
      }
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (mounted) {
        setState(() {
          _userRole = userDoc.data()?['role'];
          _listenToAttempts();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to fetch user role. Please try again.';
        });
      }
    }
  }

   Query<QuizAttempt> _getAttemptsQuery() {
    if (_userRole == 'teacher') {
      return FirebaseFirestore.instance
          .collection('quiz_attempts')
          .where('teacherId', isEqualTo: _currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .withConverter<QuizAttempt>(
            fromFirestore: QuizAttempt.fromFirestore,
            toFirestore: (QuizAttempt attempt, _) => attempt.toFirestore(),
          );
    } else {
      return FirebaseFirestore.instance
          .collection('quiz_attempts')
          .where('studentId', isEqualTo: _currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .withConverter<QuizAttempt>(
            fromFirestore: QuizAttempt.fromFirestore,
            toFirestore: (QuizAttempt attempt, _) => attempt.toFirestore(),
          );
    }
  }

  void _listenToAttempts() {
    if (_currentUser == null || _userRole == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _userRole == null
              ? 'Could not determine user role.'
              : 'You are not logged in.';
        });
      }
      return;
    }

    _subscription = _getAttemptsQuery().snapshots().listen((snapshot) {
      if (!mounted) return;
      _processSnapshot(snapshot);
    }, onError: (error, stackTrace) {
      debugPrint('Error in stream: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error loading data. Please try again.';
        });
      }
    });
  }

  Future<void> _processSnapshot(QuerySnapshot<QuizAttempt> snapshot) async {
    final newGroupedAttempts = <String, List<QuizAttempt>>{};
    final teacherIds = <String>{};
    for (final attemptDoc in snapshot.docs) {
      final attempt = attemptDoc.data();

      if (_userRole == 'teacher' && attempt.hiddenFromTeacher) {
        continue;
      } else if (_userRole != 'teacher' && attempt.hiddenFromStudent) {
        continue;
      }

      final subject = attempt.subjectId;
      if (newGroupedAttempts.containsKey(subject)) {
        newGroupedAttempts[subject]!.add(attempt);
      } else {
        newGroupedAttempts[subject] = [attempt];
      }
      if (_userRole != 'teacher') {
        teacherIds.add(attempt.teacherId);
      }
    }

    for (var subjectGroup in newGroupedAttempts.values) {
      subjectGroup.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    if (teacherIds.isNotEmpty) {
      await _fetchTeacherNames(teacherIds);
    }

    if (mounted) {
      setState(() {
        _groupedAttempts = Map.fromEntries(newGroupedAttempts.entries.toList()
          ..sort((e1, e2) => e1.key.compareTo(e2.key)));
        _isLoading = false;
        _error = null;
      });
    }
  }

  Future<void> _fetchTeacherNames(Set<String> teacherIds) async {
    final newTeacherNames = Map<String, String>.from(_teacherNames);
    for (final teacherId in teacherIds) {
      if (!newTeacherNames.containsKey(teacherId)) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(teacherId)
              .get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            newTeacherNames[teacherId] =
                data['displayName'] ?? data['name'] ?? 'Unknown Teacher';
          }
        } catch (e) {
          debugPrint('Error fetching teacher name: $e');
        }
      }
    }
    if (mounted) {
      setState(() {
        _teacherNames = newTeacherNames;
      });
    }
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedAttempts.clear();
    });
  }

  void _onAttemptSelected(String attemptId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedAttempts.add(attemptId);
      } else {
        _selectedAttempts.remove(attemptId);
      }
    });
  }

  Set<String> _getVisibleAttemptIds() {
    return _expandedSubjects
        .where((subject) => _groupedAttempts.containsKey(subject))
        .expand((subject) => _groupedAttempts[subject]!.map((a) => a.id))
        .toSet();
  }

  void _toggleSelectAll() {
    final allVisibleIds = _getVisibleAttemptIds();
    final isAllSelected = allVisibleIds.isNotEmpty &&
        _selectedAttempts.containsAll(allVisibleIds);

    setState(() {
      if (isAllSelected) {
        _selectedAttempts.removeAll(allVisibleIds);
      } else {
        _selectedAttempts.addAll(allVisibleIds);
      }
    });
  }

  void _enterSelectionAndSelectAll() {
    final allVisibleIds = _getVisibleAttemptIds();
    setState(() {
      _isSelectionMode = true;
      if (allVisibleIds.isNotEmpty) {
        _selectedAttempts.addAll(allVisibleIds);
      }
    });
  }

  Future<void> _deleteAttempt(String attemptId) async {
    final isTeacher = _userRole == 'teacher';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Attempt'),
          content: const Text(
              'Are you sure you want to delete this quiz attempt?'),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _pendingDeletions.add(attemptId);
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('quiz_attempts').doc(attemptId);
      if (isTeacher) {
        await docRef.update({'hiddenFromTeacher': true});
      } else {
        await docRef.update({'hiddenFromStudent': true});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Attempt deleted.'),
              duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint('Operation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete item.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingDeletions.remove(attemptId);
        });
      }
    }
  }

  Future<void> _deleteSelectedAttempts() async {
    final isTeacher = _userRole == 'teacher';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Selected Attempts'),
          content: Text(
              'Are you sure you want to delete ${_selectedAttempts.length} selected attempts?'),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _pendingDeletions.addAll(_selectedAttempts);
    });

    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final attemptId in _selectedAttempts) {
        final docRef = FirebaseFirestore.instance
            .collection('quiz_attempts')
            .doc(attemptId);
        if (isTeacher) {
          batch.update(docRef, {'hiddenFromTeacher': true});
        } else {
          batch.update(docRef, {'hiddenFromStudent': true});
        }
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_selectedAttempts.length} attempts deleted.')),
        );
      }
    } catch (e) {
      debugPrint('Batch operation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete attempts.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingDeletions.removeAll(_selectedAttempts);
          _selectedAttempts.clear();
          _isSelectionMode = false;
        });
      }
    }
  }

  Future<void> _deleteAllAttempts() async {
    final allAttemptIds = _groupedAttempts.values
        .expand((list) => list.map((a) => a.id))
        .toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Attempts'),
          content: Text(
              'Are you sure you want to delete all ${allAttemptIds.length} quiz attempts?'),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _pendingDeletions.addAll(allAttemptIds);
    });

    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      final isTeacher = _userRole == 'teacher';
      for (final attemptId in allAttemptIds) {
        final docRef = FirebaseFirestore.instance
            .collection('quiz_attempts')
            .doc(attemptId);
        if (isTeacher) {
          batch.update(docRef, {'hiddenFromTeacher': true});
        } else {
          batch.update(docRef, {'hiddenFromStudent': true});
        }
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'All ${allAttemptIds.length} attempts have been deleted.')),
        );
      }
    } catch (e) {
      debugPrint('Delete all failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete all attempts.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingDeletions.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleGroupedAttempts = <String, List<QuizAttempt>>{};
    _groupedAttempts.forEach((subject, attempts) {
      final visibleAttempts =
          attempts.where((a) => !_pendingDeletions.contains(a.id)).toList();
      if (visibleAttempts.isNotEmpty) {
        visibleGroupedAttempts[subject] = visibleAttempts;
      }
    });

    final allVisibleAttemptIds = _getVisibleAttemptIds();
    final isAllVisibleSelected = allVisibleAttemptIds.isNotEmpty &&
        _selectedAttempts.containsAll(allVisibleAttemptIds);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: const Color.fromARGB(255, 42, 49, 77),
              title: Text('${_selectedAttempts.length} selected'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelSelectionMode,
              ),
              actions: [
                IconButton(
                  icon: Icon(isAllVisibleSelected
                      ? Icons.done_all
                      : Icons.select_all),
                  onPressed: _toggleSelectAll,
                  tooltip: isAllVisibleSelected
                      ? 'Deselect All'
                      : 'Select All Visible',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _selectedAttempts.isNotEmpty
                      ? _deleteSelectedAttempts
                      : null,
                  tooltip: 'Delete Selected',
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Quiz History',
                  style: TextStyle(color: Colors.white)),
              actions: [
                if (visibleGroupedAttempts.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.select_all, color: Color(0xFF2ECC71)),
                    onPressed: _enterSelectionAndSelectAll,
                    tooltip: 'Select All Visible',
                  ),
                if (visibleGroupedAttempts.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    onPressed: _deleteAllAttempts,
                    tooltip: 'Delete all attempts',
                  )
              ],
            ),
      body: _buildBody(visibleGroupedAttempts),
    );
  }

  Widget _buildBody(
      Map<String, List<QuizAttempt>> visibleGroupedAttempts) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16))));
    }

    if (visibleGroupedAttempts.isEmpty && !_isLoading) {
      return const Center(
          child: Text('No quiz attempts found.',
              style: TextStyle(color: Colors.white)));
    }

    final subjects = visibleGroupedAttempts.keys.toList();
    final isTeacher = _userRole == 'teacher';

    return ListView.builder(
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final subjectAttempts = visibleGroupedAttempts[subject]!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Card(
            color: const Color(0xFF2A314D),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              key: PageStorageKey(subject), // Preserve expansion state
              initiallyExpanded: _expandedSubjects.contains(subject),
              onExpansionChanged: (isExpanded) {
                setState(() {
                  if (isExpanded) {
                    _expandedSubjects.add(subject);
                  } else {
                    _expandedSubjects.remove(subject);
                  }
                });
              },
              title: Text(subject,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              children: subjectAttempts.map((attempt) {
                final isSelected = _selectedAttempts.contains(attempt.id);
                return ListTile(
                  onTap: () {
                    if (_isSelectionMode) {
                      _onAttemptSelected(attempt.id, !isSelected);
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedAttempts.add(attempt.id);
                      });
                    }
                  },
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            if (value != null) {
                              _onAttemptSelected(attempt.id, value);
                            }
                          },
                        )
                      : null,
                  title: Text(
                      isTeacher
                          ? attempt.studentName
                          : _teacherNames[attempt.teacherId] ?? 'Unknown Teacher',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                    'Score: ${attempt.score} | ${DateFormat.yMd().add_jm().format(attempt.timestamp.toDate())}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: !_isSelectionMode
                      ? IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAttempt(attempt.id),
                          tooltip: 'Delete Attempt',
                        )
                      : null,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
