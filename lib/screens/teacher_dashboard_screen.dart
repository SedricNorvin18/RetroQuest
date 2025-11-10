import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retroquest/models/question_model.dart';
import 'package:retroquest/screens/history_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  // General state
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  String? _selectedSubjectForQuestions;
  String _currentView =
      'quizzes'; // 'quizzes', 'upload', 'questions', or 'history'

  // Quiz list state
  List<Map<String, dynamic>> _subjects = [];

  // Upload form state
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _questionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  final _timeLimitController =
      TextEditingController(); // Controller for the time limit
  final ValueNotifier<int?> _correctOption = ValueNotifier(null);
  bool _isUploading = false;
  Question? _questionToEdit;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    _timeLimitController.dispose(); // Dispose the controller
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final subjectDocs = await FirebaseFirestore.instance
          .collection('subjects')
          .where('teacherId', isEqualTo: user.uid)
          .orderBy('order')
          .get();
      final subjects = subjectDocs.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate will handle navigation
  }

  void _showQuizList() {
    setState(() {
      _currentView = 'quizzes';
      _questionToEdit = null; // Clear any question being edited
      _selectedSubjectForQuestions = null;
      _clearForm();
    });
  }

  void _showUploadForm({
  Question? question,
  String? subjectId,
  bool isNewQuiz = false,
}) {
  setState(() {
    _currentView = 'upload';

    // Reset form first to avoid stray values
    _clearForm();

    // Remember whether we are editing a question
    _questionToEdit = question;

    // 1) If editing an existing question -> populate everything (take precedence)
    if (question != null) {
      // If subjectId provided use it; otherwise keep whatever (could be null)
      _selectedSubjectForQuestions = subjectId;
      _subjectController.text = subjectId ?? '';

      _questionController.text = question.text;
      _option1Controller.text = question.options.isNotEmpty ? question.options[0] : '';
      _option2Controller.text = question.options.length > 1 ? question.options[1] : '';
      _option3Controller.text = question.options.length > 2 ? question.options[2] : '';
      _option4Controller.text = question.options.length > 3 ? question.options[3] : '';
      _correctOption.value = question.options.indexOf(question.correctAnswer);
      _timeLimitController.text = question.timeLimit?.toString() ?? '';
      return; // done — editing wins
    }

    // 2) If explicitly creating a NEW QUIZ, clear selected subject so Subject input shows empty
    if (isNewQuiz) {
      _selectedSubjectForQuestions = null;
      _subjectController.text = '';
      return;
    }

    // 3) Otherwise, if a subjectId was provided (Add Question flow), set it
    if (subjectId != null) {
      _selectedSubjectForQuestions = subjectId;
      _subjectController.text = subjectId;
      return;
    }

    // 4) Default: nothing to prefill (keeps form cleared)
    _selectedSubjectForQuestions = null;
    _subjectController.text = '';
  });
}


  void _showQuestionsForSubject(String subjectId) {
    setState(() {
      _currentView = 'questions';
      _selectedSubjectForQuestions = subjectId;
    });
  }

  void _showHistory() {
    setState(() {
      _currentView = 'history';
    });
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _subjectController.clear();
    _questionController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    _timeLimitController.clear();
    _correctOption.value = null;
  }

  Future<void> _uploadQuestion() async {
    if (_formKey.currentState?.validate() != true ||
        _correctOption.value == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please fill all fields and select a correct option.')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final subject = _subjectController.text;

      final subjectRef =
          FirebaseFirestore.instance.collection('subjects').doc(subject);
      final doc = await subjectRef.get();
      if (!doc.exists) {
        await subjectRef
            .set({'teacherId': user.uid, 'order': _subjects.length});
      }

      final questionCollection = subjectRef.collection('questions');
      final options = [
        _option1Controller.text,
        _option2Controller.text,
        _option3Controller.text,
        _option4Controller.text,
      ];
      final questionData = {
        'text': _questionController.text,
        'options': options,
        'correctAnswer': options[_correctOption.value!],
        'createdAt': FieldValue.serverTimestamp(),
        'teacherId': user.uid,
        'timeLimit':
            int.tryParse(_timeLimitController.text) ?? 30, // Default to 30 seconds if not specified
      };

      if (_questionToEdit != null) {
        await questionCollection.doc(_questionToEdit!.id).update(questionData);
      } else {
        await questionCollection.add(questionData);
      }

      await _loadSubjects(); // Refresh the list

      if (_selectedSubjectForQuestions != null) {
        _showQuestionsForSubject(subject);
      } else {
        _showQuizList();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Question ${_questionToEdit != null ? 'updated' : 'uploaded'} successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload question: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteSubject(String subjectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text(
            'Are you sure you want to delete this subject and all its questions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final subjectRef =
            FirebaseFirestore.instance.collection('subjects').doc(subjectId);
        final questions = await subjectRef.collection('questions').get();

        for (final question in questions.docs) {
          await question.reference.delete();
        }

        await subjectRef.delete();
        _loadSubjects();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete subject: $e')),
          );
        }
      }
    }
  }

  Future<void> _editSubject(String oldSubjectId) async {
    final newSubjectController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subject'),
        content: TextFormField(
          controller: newSubjectController,
          decoration: const InputDecoration(labelText: 'New Subject Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newSubjectId = newSubjectController.text;
      if (newSubjectId.isNotEmpty) {
        try {
          final oldSubjectRef = FirebaseFirestore.instance
              .collection('subjects')
              .doc(oldSubjectId);
          final newSubjectRef = FirebaseFirestore.instance
              .collection('subjects')
              .doc(newSubjectId);

          final questions = await oldSubjectRef.collection('questions').get();

          for (final question in questions.docs) {
            await newSubjectRef
                .collection('questions')
                .doc(question.id)
                .set(question.data());
            await question.reference.delete();
          }
          final oldDoc = await oldSubjectRef.get();
          final order = oldDoc.data()?['order'] ?? 0;

          await newSubjectRef
              .set({'teacherId': _user!.uid, 'order': order});
          await oldSubjectRef.delete();

          _loadSubjects();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subject updated successfully!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update subject: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _updateSubjectOrder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _subjects.removeAt(oldIndex);
      _subjects.insert(newIndex, item);
    });

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < _subjects.length; i++) {
      final subject = _subjects[i];
      final docRef =
          FirebaseFirestore.instance.collection('subjects').doc(subject['id']);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2336),
      body: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/retro_bg.jpg',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withAlpha(153)),
            (constraints.maxWidth < 800)
                ? _buildMobileLayout()
                : _buildWebLayout(),
          ],
        );
      }),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        Container(
          width: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade900.withAlpha(217),
                Colors.pink.shade700.withAlpha(217),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _buildSidebar(),
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900.withAlpha(217),
        elevation: 0,
        title: Text(
          _currentView == 'upload'
              ? 'Create a Quiz'
              : _currentView == 'questions'
                  ? _selectedSubjectForQuestions ?? 'Questions'
                  : _currentView == 'history'
                      ? 'History'
                      : "RetroQuest",
          style: const TextStyle(
              fontFamily: "PressStart2P", color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: (_currentView == 'upload' ||
                _currentView == 'questions' ||
                _currentView == 'history')
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _showQuizList,
              )
            : null,
      ),
      drawer: _currentView == 'quizzes'
          ? Drawer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade900.withAlpha(217),
                      Colors.pink.shade700.withAlpha(217),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _buildSidebar(),
              ),
            )
          : null,
      body: _buildContent(),
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _user?.photoURL != null
                  ? NetworkImage(_user!.photoURL!)
                  : null,
              child: _user?.photoURL == null
                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(_user?.uid).get(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  // if (snapshot.connectionState == ConnectionState.waiting) {
                  //    return const Text(
                  //       'Loading...',
                  //       style: TextStyle(
                  //           fontWeight: FontWeight.bold,
                  //           fontSize: 16,
                  //           color: Colors.white),
                  //       overflow: TextOverflow.ellipsis,
                  //     );
                  // }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data() == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.displayName ?? 'Student',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'RetroQuest Teacher',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      );
                  }
                  
                  Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                  
                  // Robust name fetching to support old and new data structures
                  String firstName = data['first'] ?? data['firstName'] ?? '';
                  String lastName = data['last'] ?? data['lastName'] ?? '';
                  String displayName = '$firstName $lastName'.trim();

                  if (displayName.isEmpty) {
                    displayName = data['displayName'] ?? data['name'] ?? 'Student';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'RetroQuest Teacher',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildUpgradeButton(),
        const SizedBox(height: 24),
        _buildNavSectionTitle('MANAGE'),
        _buildNavItem(Icons.add, 'New quiz',
            isSelected: _currentView == 'upload',
            onTap: () => _showUploadForm(isNewQuiz: true)),
        _buildNavItem(Icons.quiz_outlined, 'Quizzes',
            isSelected: _currentView == 'quizzes', onTap: _showQuizList),
        _buildNavItem(Icons.history_outlined, 'History',
            isSelected: _currentView == 'history', onTap: _showHistory),
        const Spacer(),
        _buildNavSectionTitle('PRODUCT'),
        _buildNavItem(Icons.help_outline, 'Help', onTap: () {}),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent));
    }
    if (_currentView == 'upload') {
      return Center(
        child: _buildUploadForm(),
      );
    }
    if (_currentView == 'questions') {
      return _buildQuestionsList();
    }
    if (_currentView == 'history') {
      return const HistoryScreen();
    }
    return _subjects.isEmpty ? _buildEmptyState() : _buildSubjectList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No quizzes yet!',
            style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'PressStart2P'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Click the button below to create your first quiz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showUploadForm(),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Create a Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'PressStart2P'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Quizzes',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'PressStart2P'),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSubjects,
              color: Colors.greenAccent,
              backgroundColor: const Color(0xFF1E2336),
              child: ReorderableListView.builder(
                itemCount: _subjects.length,
                onReorder: _updateSubjectOrder,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  return Card(
                    key: ValueKey(subject['id']),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    color: Colors.black54,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(subject['id'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'PressStart2P')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: () => _editSubject(subject['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.pinkAccent),
                            onPressed: () => _deleteSubject(subject['id']),
                          ),
                        ],
                      ),
                      onTap: () => _showQuestionsForSubject(subject['id']),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .doc(_selectedSubjectForQuestions)
            .collection('questions')
            .where('teacherId', isEqualTo: _user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data!.docs
              .map((doc) => Question.fromFirestore(doc))
              .toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      color: Colors.black54,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(question.text,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var option in question.options)
                              Text(
                                option,
                                style: TextStyle(
                                  color: question.correctAnswer == option
                                      ? Colors.greenAccent
                                      : Colors.pinkAccent,
                                ),
                              ),
                            if (question.timeLimit != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Time: ${question.timeLimit}s',
                                    style: const TextStyle(
                                        color: Colors.white70)),
                              )
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.white70),
                              onPressed: () => _showUploadForm(
                                  question: question,
                                  subjectId: _selectedSubjectForQuestions),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.pinkAccent),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('subjects')
                                    .doc(_selectedSubjectForQuestions)
                                    .collection('questions')
                                    .doc(question.id)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showUploadForm(subjectId: _selectedSubjectForQuestions),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52),
                    textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PressStart2P'),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildUploadForm() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6, // 60% of screen width
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withAlpha(100),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: _isUploading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _questionToEdit != null
                            ? 'Edit Question'
                            : 'Create a New Quiz',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'PressStart2P')),
                    const SizedBox(height: 24),
                    if (_questionToEdit == null &&
                        _selectedSubjectForQuestions == null)
                      TextFormField(
                        controller: _subjectController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            labelText: 'Subject',
                            labelStyle: const TextStyle(color: Colors.white70),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade600)),
                            focusedBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.greenAccent))),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a subject' : null,
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _questionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      minLines: 3,
                      decoration: InputDecoration(
                          labelText: 'Question',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade600)),
                          focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.greenAccent))),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a question' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text('Options',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'PressStart2P')),
                    ..._buildOptionFields(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timeLimitController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          labelText: 'Time Limit (seconds)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey.shade600)),
                          focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.greenAccent))),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final time = int.tryParse(value);
                          if (time == null || time <= 0) {
                            return 'Please enter a valid time limit';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Correct Option',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'PressStart2P')),
                    _buildRadioGroup(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _uploadQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 52),
                        textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PressStart2P'),
                      ),
                      child: Text(_questionToEdit != null
                          ? 'Update Question'
                          : 'Upload Question'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildOptionFields() {
    final controllers = [
      _option1Controller,
      _option2Controller,
      _option3Controller,
      _option4Controller
    ];
    return List.generate(4, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: controllers[index],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              labelText: 'Option ${index + 1}',
              labelStyle: const TextStyle(color: Colors.white70),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade600)),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent))),
          validator: (value) =>
              value!.isEmpty ? 'Please enter an option' : null,
        ),
      );
    });
  }

  Widget _buildRadioGroup() {
  return ValueListenableBuilder<int?>(
    valueListenable: _correctOption,
    builder: (context, selected, child) {
      return RadioGroup<int>( // Wrap with RadioGroup
        groupValue: selected, // Move groupValue here
        onChanged: (int? value) { // Move onChanged here
          _correctOption.value = value;
        },
        child: Column(
          children: List.generate(4, (index) {
            return RadioListTile<int>(
              title: Text('Option ${index + 1}',
                  style: const TextStyle(color: Colors.white)),
              value: index,
              // groupValue and onChanged are now managed by RadioGroup
              activeColor: Colors.greenAccent,
            );
          }),
        ),
      );
    },
  );
}


  Widget _buildUpgradeButton() {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.upgrade, color: Colors.greenAccent),
      label: const Text('Upgrade',
          style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontFamily: 'PressStart2P')),
    );
  }

  Widget _buildNavSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.bold,
            fontSize: 12),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title,
      {bool isSelected = false, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black54 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? Colors.white : Colors.grey.shade400),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'PressStart2P',
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.grey.shade400),
      title: Text('Logout',
          style: TextStyle(
              color: Colors.grey.shade400, fontFamily: 'PressStart2P')),
      onTap: _logout,
      dense: true,
    );
  }
}