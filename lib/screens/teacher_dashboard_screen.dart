import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retroquest/models/question_model.dart';
import 'package:retroquest/screens/history_screen.dart';
import 'package:retroquest/screens/teacher_help_screen.dart';
import 'package:retroquest/services/firestore_service.dart'; // <--- ADD THIS
import 'package:retroquest/models/enrolled_student.dart'; // <--- ADD THIS
import 'package:retroquest/screens/account_settings_screen.dart'; // <--- ADD THIS
import 'package:retroquest/screens/profile_screen.dart'; // <--- ADD THIS
import 'package:retroquest/models/enrollment_request.dart'; // <--- ADD THIS
import 'package:retroquest/screens/enrollment_requests_screen.dart'; // <--- ADD THIS
// Required for File handling
// Required for file upload
import 'package:image_picker/image_picker.dart'; // Required for image selection
import 'package:path/path.dart' as path;
import 'package:retroquest/services/storage_service.dart'; // For file path manipulation

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  // NEW: Initialize StorageService
  final StorageService _storageService = StorageService(); // <--- ADD THIS
  final FirestoreService _firestoreService = FirestoreService();
  // General state
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  String? _selectedSubjectForQuestions;
  String _currentView =
      'quizzes'; // 'quizzes', 'upload', 'questions', or 'history'

// NEW: State for the question type dropdown
  QuestionType _selectedQuestionType =
      QuestionType.multipleChoice; // <--- ADD THIS

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
  // NEW/UPDATED: Image Upload State
  Uint8List? _selectedImageBytes; // The image data (bytes)
  String? _selectedImageName; // The original file name
  String? _existingImageUrl; // URL if editing an existing question
  bool _isUploadingImage = false;
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

  Future<void> _addStudentDialog() async {
    final TextEditingController emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll New Student'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Student Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              Navigator.of(context).pop(); // Close dialog

              await _enrollStudent(email);
            },
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }

  Future<void> _enrollStudent(String studentEmail) async {
    final teacherUid = _user?.uid;
    if (teacherUid == null) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // 1. Find the student's UID by email
      final studentDoc =
          await FirestoreService().getUserProfileByEmail(studentEmail);

      if (studentDoc == null) {
        throw Exception('No user found with that email.');
      }

      final studentUid = studentDoc.id;
      final studentData = studentDoc.data() as Map<String, dynamic>;
      final studentRole = studentData['role'];

      if (studentRole != 'student') {
        throw Exception('User is not a student.');
      }

      // 2. Perform the enrollment
      await FirestoreService().enrollStudent(
        teacherUid: teacherUid,
        studentUid: studentUid,
        studentEmail: studentEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Student $studentEmail enrolled successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to enroll student: ${e.toString().split(':').last}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unenrollStudent(
      String enrollmentId, String studentEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unenroll Student'),
        content: Text('Are you sure you want to unenroll $studentEmail?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unenroll'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().unenrollStudent(enrollmentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$studentEmail unenrolled successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unenroll student: $e')),
          );
        }
      }
    }
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
      final subjects =
          subjectDocs.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
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

  void _showStudentsView() {
    setState(() {
      _currentView = 'students';
    });
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
        _option1Controller.text =
            question.options.isNotEmpty ? question.options[0] : '';
        _option2Controller.text =
            question.options.length > 1 ? question.options[1] : '';
        _option3Controller.text =
            question.options.length > 2 ? question.options[2] : '';
        _option4Controller.text =
            question.options.length > 3 ? question.options[3] : '';

        // --- START FIX/UPDATE: Handle question type and options for non-MC/TF types ---
        _selectedQuestionType = question.questionType; // <--- ADD THIS LINE

        if (question.questionType == QuestionType.multipleChoice ||
            question.questionType == QuestionType.trueFalse) {
          _correctOption.value =
              question.options.indexOf(question.correctAnswer);
        } else {
          // For FillInTheBlank and ShortAnswer, the correct answer is stored in 'correctAnswer'
          // and should be placed into the first option field (_option1Controller)
          _option1Controller.text = question.correctAnswer;
          _correctOption.value = null; // No radio button selection needed
        }
        // --- END FIX/UPDATE ---

        _timeLimitController.text = question.timeLimit?.toString() ?? '';

        // NEW: Populate image URL for editing
        _selectedImageBytes =
            null; // <--- MAKE SURE THIS IS _selectedImageBytes
        _selectedImageName = null; // <--- ADD/CONFIRM THIS IS PRESENT

        // CRITICAL UPDATE: Retain existing image URL if present when editing
        _existingImageUrl = question.imageUrl; // <--- ADD/UPDATE THIS LINE

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

    // NEW: Clear image state
    _selectedImageBytes = null; // <--- UPDATE THIS
    _selectedImageName = null; // <--- ADD THIS
    _existingImageUrl = null;
    _isUploadingImage = false;

    // NEW: Reset the question type
    _selectedQuestionType = QuestionType.multipleChoice; // <--- ADD THIS
  }

  Future<void> _uploadQuestion() async {
    // Modify validation based on question type
    final requiresOptions =
        _selectedQuestionType == QuestionType.multipleChoice ||
            _selectedQuestionType == QuestionType.trueFalse;

    if (_formKey.currentState?.validate() != true ||
        (requiresOptions && _correctOption.value == null)) {
      // <--- MODIFIED
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please fill all required fields and select a correct option.')), // <--- MODIFIED
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    String? finalImageUrl = _existingImageUrl; // Start with the existing URL
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check for bytes and name
    if (_selectedImageBytes != null && _selectedImageName != null) {
      setState(() => _isUploadingImage = true);

      try {
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}_${_selectedImageName!}';

        finalImageUrl = await _storageService.uploadQuestionImage(
          _selectedImageBytes!,
          user.uid,
          uniqueName,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Image upload failed. Please try again.')));
        }
        setState(() {
          _isUploading = false;
          _isUploadingImage = false;
        });
        return;
      }

      setState(() => _isUploadingImage = false);
    }
    // END NEW: Handle Image Upload

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

      // NEW: Dynamic options and correct answer based on type
      List<String> options;
      String correctAnswer;

      if (_selectedQuestionType == QuestionType.multipleChoice) {
        options = [
          _option1Controller.text,
          _option2Controller.text,
          _option3Controller.text,
          _option4Controller.text,
        ];
        correctAnswer = options[_correctOption.value!];
      } else if (_selectedQuestionType == QuestionType.trueFalse) {
        options = ['True', 'False'];
        correctAnswer = options[_correctOption.value!];
      } else {
        // FillInTheBlank or ShortAnswer
        // For these types, the 'correctAnswer' is just the text from the first option/controller
        // And 'options' is typically empty or just contains the answer for simplicity in Firestore
        options = [];
        correctAnswer =
            _option1Controller.text.trim(); // Use option1 for the answer field
      }

      final questionData = {
        'text': _questionController.text,
        'options': options, // <--- MODIFIED
        'correctAnswer': correctAnswer, // <--- MODIFIED
        'questionType':
            _selectedQuestionType.toString().split('.').last, // <--- ADD THIS
        'imageUrl': finalImageUrl, // <--- ADD/UPDATE THIS LINE
        'createdAt': FieldValue.serverTimestamp(),
        'teacherId': user.uid,
        'timeLimit': int.tryParse(_timeLimitController.text) ??
            30, // Default to 30 seconds if not specified
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // CRITICAL CHANGE: Read the bytes from the XFile
      final bytes = await pickedFile.readAsBytes();
      final fileName = path.basename(pickedFile.name);

      setState(() {
        _selectedImageBytes = bytes; // Store bytes
        _selectedImageName = fileName; // Store name
        _existingImageUrl = null; // A new file is selected, so discard old URL
      });
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

          await newSubjectRef.set({'teacherId': _user!.uid, 'order': order});
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

  Future<void> _confirmAndDeleteQuestion(
      Question question, String subjectId) async {
    // 1. Show the dialog and await its result
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
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

    // CRITICAL: Check mounted after the await returns
    if (!mounted) return;

    if (confirmed == true) {
      try {
        // 2. Perform deletion
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(subjectId)
            .collection('questions')
            .doc(question.id)
            .delete();

        // 3. Show success message (check mounted again, just in case)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question deleted successfully!')),
          );
        }
      } catch (e) {
        // 4. Show error message (check mounted again)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete question: $e')),
          );
        }
      }
    }
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
                      : _currentView == 'students' // <--- ADD THIS
                          ? 'Enrolled Students' // <--- ADD THIS
                          : "RetroQuest",
          style: const TextStyle(
              fontFamily: "PressStart2P", color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: (_currentView == 'upload' ||
                _currentView == 'questions' ||
                _currentView == 'history' ||
                _currentView == 'students') // <--- ADD THIS
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // <--- MODIFIED TO USE A FUNCTION
                  if (_currentView == 'upload' &&
                      _questionToEdit != null &&
                      _selectedSubjectForQuestions != null) {
                    // When editing a question, go back to the subject's question list
                    _showQuestionsForSubject(_selectedSubjectForQuestions!);
                  } else {
                    // For all other cases (new quiz, history, students, or just viewing questions) go to quiz list
                    _showQuizList();
                  }
                }, // <--- MODIFIED
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
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'account') {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen()));
            } else if (value == 'profile') {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ProfileScreen()));
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'account',
              child: Text('Account'),
            ),
            const PopupMenuItem<String>(
              value: 'profile',
              child: Text('View profile'),
            ),
          ],
          child: Row(
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
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user?.uid)
                      .get(),
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
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data?.data() == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.displayName ??
                                'Teacher', // NOTE: Changed 'Student' to 'Teacher'
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'RetroQuest Teacher',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      );
                    }

                    Map<String, dynamic> data =
                        snapshot.data!.data() as Map<String, dynamic>;

                    // Robust name fetching to support old and new data structures
                    String firstName = data['first'] ?? data['firstName'] ?? '';
                    String lastName = data['last'] ?? data['lastName'] ?? '';
                    String displayName = '$firstName $lastName'.trim();

                    if (displayName.isEmpty) {
                      displayName = data['displayName'] ??
                          data['name'] ??
                          'Teacher'; // NOTE: Changed 'Student' to 'Teacher'
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
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildNavSectionTitle('MANAGE'),
        _buildEnrollmentRequestsDrawerItem(),
        _buildNavItem(Icons.people_alt_outlined, 'Students', // <--- ADD THIS
            isSelected: _currentView == 'students',
            onTap: _showStudentsView), // <--- ADD THIS
        _buildNavItem(Icons.add, 'New quiz',
            isSelected: _currentView == 'upload',
            onTap: () => _showUploadForm(isNewQuiz: true)),
        _buildNavItem(Icons.quiz_outlined, 'Quizzes',
            isSelected: _currentView == 'quizzes', onTap: _showQuizList),
        _buildNavItem(Icons.history_outlined, 'History',
            isSelected: _currentView == 'history', onTap: _showHistory),
        const Spacer(),
        _buildNavSectionTitle('PRODUCT'),
        _buildNavItem(
          Icons.help_outline,
          'Help',
          isSelected: false,
          onTap: () {
            // This is the key part: use Navigator.push to navigate to the HelpScreen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const TeacherHelpScreen(), // The screen you want to go to
              ),
            );
          },
        ),
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

    if (_currentView == 'students') {
      // <--- ADD THIS
      return _buildStudentsView(); // <--- ADD THIS
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

          // --- NEW: Empty State Check ---
          if (questions.isEmpty) {
            return _buildQuestionsEmptyState(); // Use a dedicated helper function
          }
          // --- END NEW ---

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
                            Text(
                              'Type: ${question.questionType.toString().split('.').last.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')}',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            // --- Conditional Answer Display ---
                            if (question.questionType ==
                                    QuestionType.fillInTheBlank ||
                                question.questionType ==
                                    QuestionType.shortAnswer)
                              Text(
                                'Correct Answer: "${question.correctAnswer}"',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                              ),
                            if (question.questionType ==
                                    QuestionType.multipleChoice ||
                                question.questionType == QuestionType.trueFalse)
                              ...question.options.map((option) {
                                return Text(
                                  option,
                                  style: TextStyle(
                                    color: question.correctAnswer == option
                                        ? Colors.greenAccent
                                        : Colors.pinkAccent,
                                  ),
                                );
                              }),
                            // --- End Conditional Answer Display ---
                            if (question.timeLimit != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Time: ${question.timeLimit}s',
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              )
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, color: Colors.white70),
                              onPressed: () => _showUploadForm(
                                  question: question,
                                  subjectId: _selectedSubjectForQuestions),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.pinkAccent),
                              onPressed: () {
                                // Calls the new method that handles all async logic and mounted checks
                                _confirmAndDeleteQuestion(
                                    question, _selectedSubjectForQuestions!);
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

  Widget _buildQuestionsEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No questions yet!',
            style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'PressStart2P'),
          ),
          const SizedBox(height: 16),
          Text(
            'Click the button below to add questions to the $_selectedSubjectForQuestions quiz.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          // The "Add Question" button is in the Column's Padding, so we omit it here
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    // Get the current screen width
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      // --- MODIFIED WIDTH LOGIC ---
      width: screenWidth > 800
          ? screenWidth * 0.6 // On web (wide screen), use 60% of width
          : screenWidth * 0.9, // On mobile (narrow screen), use 90% of width
      // --- END MODIFIED WIDTH LOGIC ---
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(200, 0, 0, 0),
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
                    DropdownButtonFormField<QuestionType>(
                      decoration: InputDecoration(
                        labelText: 'Question Type',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey.shade600)),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.greenAccent)),
                        filled: true,
                        fillColor: Colors.black45,
                      ),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      initialValue: _selectedQuestionType,
                      items: QuestionType.values.map((QuestionType type) {
                        return DropdownMenuItem<QuestionType>(
                          value: type,
                          child: Text(
                            type.toString().split('.').last.replaceAllMapped(
                                RegExp(r'([A-Z])'),
                                (match) => ' ${match.group(0)}'),
                          ),
                        );
                      }).toList(),
                      onChanged: (QuestionType? newValue) {
                        setState(() {
                          _selectedQuestionType =
                              newValue ?? QuestionType.multipleChoice;
                          // Clear options/answer input when changing type
                          _option1Controller.clear();
                          _option2Controller.clear();
                          _option3Controller.clear();
                          _option4Controller.clear();
                          _correctOption.value = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // START OF FIX: This block adds the missing Subject TextFormField
                    if (_questionToEdit == null &&
                        _selectedSubjectForQuestions == null)
                      TextFormField(
                        controller: _subjectController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            labelText: 'Quiz Subject / Title',
                            labelStyle: const TextStyle(color: Colors.white70),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade600)),
                            focusedBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.greenAccent))),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter a subject name'
                            : null,
                      ),
                    const SizedBox(height: 16),
                    if (_questionToEdit == null &&
                        _selectedSubjectForQuestions == null)
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

                    // NEW: Image Upload Section
                    _buildImageUploadSection(), // <--- ADD THIS CALL

                    const SizedBox(height: 24), // Add separation

                    // NEW: Conditional 'Options' label
                    if (_selectedQuestionType == QuestionType.multipleChoice)

                      // NEW: Conditional 'Options' label
                      if (_selectedQuestionType == QuestionType.multipleChoice)
                        const Text('Options',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'PressStart2P')),
                    // NEW: Conditional option fields/answer fields
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
                    // NEW: Conditional 'Correct Option' label
                    if (_selectedQuestionType == QuestionType.multipleChoice ||
                        _selectedQuestionType == QuestionType.trueFalse)
                      const Text('Correct Option',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'PressStart2P')),
                    // NEW: Conditional radio group
                    _buildRadioGroup(),
                    const SizedBox(height: 32),
                    // NEW: Conditional Button Layout
                    if (_questionToEdit != null)
                      Row(
                        children: [
                          // NEW: Cancel Button for Edit Mode
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate back to the specific subject list
                                if (_selectedSubjectForQuestions != null) {
                                  _showQuestionsForSubject(
                                      _selectedSubjectForQuestions!);
                                } else {
                                  // Fallback: Go back to the main quiz list
                                  _showQuizList();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .pinkAccent, // Use a distinct color for Cancel
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                                textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'PressStart2P'),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Existing Update Button
                          Expanded(
                            child: ElevatedButton(
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
                              child: const Text(
                                'Update Question',
                                textAlign: TextAlign.center, // Ensure centering
                              ),
                              // --- END MODIFIED TEXT CHILD ---
                            ),
                          ),
                        ],
                      )
                    else
                      // Existing Upload Button for New Quiz/Question
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
                        // --- MODIFIED TEXT CHILD ---
                        child: const Text(
                          'Upload Question',
                          textAlign: TextAlign.center, // Ensure centering
                        ),
                        // --- END MODIFIED TEXT CHILD ---
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Question Image',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'PressStart2P')),
            if (_isUploadingImage)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.greenAccent),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF2A314D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: InkWell(
            onTap: _isUploadingImage ? null : _pickImage,
            child: Center(
              child: _selectedImageBytes != null
                  ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                  : _existingImageUrl != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(_existingImageUrl!,
                                fit: BoxFit.contain),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _existingImageUrl = null;
                                    _selectedImageBytes = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Tap to select image (Optional)',
                          style: TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic),
                        ),
            ),
          ),
        ),
        if (_selectedImageName != null)
          Text(
            'New file selected: $_selectedImageName', // <--- Use the new variable
            style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildStudentListItem(EnrolledStudent student) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirestoreService().getUserProfile(student.studentUid),
      builder: (context, snapshot) {
        String displayName = student.studentEmail; // Default to email

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final data = snapshot.data?.data();
          // Check for 'displayName' field from the /users collection
          displayName = data?['displayName'] ?? student.studentEmail;
        }

        return Card(
          key: ValueKey(student.id),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: Colors.black54,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.white70),
            title: Text(displayName, // Display the name/email
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'PressStart2P')),
            // REMOVED SUBTITLE: The UID is no longer displayed
            trailing: IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.pinkAccent),
              onPressed: () =>
                  _unenrollStudent(student.id!, student.studentEmail),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildOptionFields() {
    // NEW: Conditional rendering
    if (_selectedQuestionType == QuestionType.trueFalse) {
      return [
        const Text('Correct Answer:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'PressStart2P')),
        // True/False correct option handled by the radio group below
      ];
    }

    if (_selectedQuestionType == QuestionType.fillInTheBlank ||
        _selectedQuestionType == QuestionType.shortAnswer) {
      return [
        const Text('Correct Answer Text', // <--- Modified label
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'PressStart2P')),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller:
                _option1Controller, // Reuse controller for correct answer
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                labelText: _selectedQuestionType == QuestionType.fillInTheBlank
                    ? 'Fill-in Text'
                    : 'Short Answer Text',
                labelStyle: const TextStyle(color: Colors.white70),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.greenAccent))),
            validator: (value) =>
                value!.isEmpty ? 'Please enter the correct answer' : null,
          ),
        ),
      ];
    }

    // Default: Multiple Choice
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
    // NEW: Only display radio group for Multiple Choice and True/False
    if (_selectedQuestionType == QuestionType.fillInTheBlank ||
        _selectedQuestionType == QuestionType.shortAnswer) {
      return const SizedBox.shrink();
    }

    // Determine the list of options for the radio buttons
    List<String> radioOptions;
    if (_selectedQuestionType == QuestionType.trueFalse) {
      radioOptions = ['True', 'False'];
    } else {
      // Multiple Choice
      radioOptions = ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
    }

    return ValueListenableBuilder<int?>(
      valueListenable: _correctOption,
      builder: (context, selected, child) {
        return RadioGroup<int>(
          // Wrap with RadioGroup
          groupValue: selected, // Move groupValue here
          onChanged: (int? value) {
            // Move onChanged here
            _correctOption.value = value;
          },
          child: Column(
            children: List.generate(radioOptions.length, (index) {
              // <--- MODIFIED size
              return RadioListTile<int>(
                title: Text(radioOptions[index], // <--- MODIFIED title
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
        leading:
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade400),
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

  Widget _buildStudentsView() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudentDialog,
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
      body: StreamBuilder<List<EnrolledStudent>>(
        stream: FirestoreService().getEnrolledStudents(_user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No students enrolled.',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PressStart2P'),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tap the + button to enroll a student by email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return _buildStudentListItem(
                  student); // Use the new nested builder
            },
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
      String view, String title, IconData icon, VoidCallback onTap,
      {int badgeCount = 0}) {
    // <--- MODIFIED
    final isSelected = _currentView == view;

    return Material(
      color: isSelected ? Colors.grey.shade800 : Colors.transparent,
      child: ListTile(
        leading:
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade400),
        title: Row(
          // <--- ADDED Row for badge
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'PressStart2P',
                fontSize: 12,
              ),
            ),
            if (badgeCount > 0) // <--- ADDED Badge logic
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PressStart2P',
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildEnrollmentRequestsDrawerItem() {
    // <--- ADD NEW FUNCTION
    final teacherUid = _user?.uid;

    if (teacherUid == null) {
      return const SizedBox.shrink(); // Hide if user is null
    }

    return StreamBuilder<List<EnrollmentRequest>>(
      stream: _firestoreService.getPendingEnrollmentRequests(teacherUid),
      builder: (context, snapshot) {
        int pendingCount = snapshot.data?.length ?? 0;

        return _buildDrawerItem(
          'enrollments',
          'Enrollment Requests',
          Icons.person_add,
          () {
            Navigator.of(context).pop();
            Navigator.pushNamed(
                context, '/enrollment-requests'); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const EnrollmentRequestsScreen()),
            );
          },
          badgeCount: pendingCount, // Pass the count for the notification badge
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: Icon(Icons.logout, color: Colors.grey.shade400),
      title: Text('Logout',
          style: TextStyle(
              color: Colors.grey.shade400, fontFamily: 'PressStart2P')),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Close the dialog
                  },
                ),
                TextButton(
                  child: const Text('Logout'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog first
                    _logout(); // Then execute the logout function
                  },
                ),
              ],
            );
          },
        );
      },
      dense: true,
    );
  }
}
