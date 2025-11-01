import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:retroquest/models/question_model.dart';
import 'package:retroquest/models/subjects.dart';

class UploadQuestionScreen extends StatefulWidget {
  final String subjectId;
  final Question? questionToEdit;
  final VoidCallback? onQuestionUploaded;

  const UploadQuestionScreen(
      {super.key,
      required this.subjectId,
      this.questionToEdit,
      this.onQuestionUploaded});

  @override
  State<UploadQuestionScreen> createState() => _UploadQuestionScreenState();
}

class _UploadQuestionScreenState extends State<UploadQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  String? _selectedSubject;
  int? _correctOption;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.subjectId;
    if (widget.questionToEdit != null) {
      final question = widget.questionToEdit!;
      _questionController.text = question.text;
      _option1Controller.text = question.options[0];
      _option2Controller.text = question.options[1];
      _option3Controller.text = question.options[2];
      _option4Controller.text = question.options[3];
      _correctOption = question.options.indexOf(question.correctAnswer);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    super.dispose();
  }

  Future<void> _uploadQuestion() async {
    if (_formKey.currentState?.validate() != true || _correctOption == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please fill all fields and select a correct option.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final subjectRef = FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId);

      if (widget.questionToEdit == null) {
        subjectRef.set({'teacherId': user.uid}, SetOptions(merge: true));
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
        'correctAnswer': options[_correctOption!],
        'createdAt': FieldValue.serverTimestamp(),
        'teacherId': user.uid,
      };

      if (widget.questionToEdit != null) {
        await questionCollection
            .doc(widget.questionToEdit!.id)
            .update(questionData);
      } else {
        await questionCollection.add(questionData);
      }

      widget.onQuestionUploaded?.call();

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Question ${widget.questionToEdit != null ? 'updated' : 'uploaded'} successfully!')),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.questionToEdit != null ? 'Edit Question' : 'Upload Question'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (widget.questionToEdit == null)
                      DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        items: subjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Subject'),
                        validator: (value) =>
                            value == null ? 'Please select a subject' : null,
                      ),
                    TextFormField(
                      controller: _questionController,
                      decoration: const InputDecoration(labelText: 'Question'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a question' : null,
                    ),
                    TextFormField(
                      controller: _option1Controller,
                      decoration: const InputDecoration(labelText: 'Option 1'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter an option' : null,
                    ),
                    TextFormField(
                      controller: _option2Controller,
                      decoration: const InputDecoration(labelText: 'Option 2'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter an option' : null,
                    ),
                    TextFormField(
                      controller: _option3Controller,
                      decoration: const InputDecoration(labelText: 'Option 3'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter an option' : null,
                    ),
                    TextFormField(
                      controller: _option4Controller,
                      decoration: const InputDecoration(labelText: 'Option 4'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter an option' : null,
                    ),
                    const SizedBox(height: 10),
                    const Text('Correct Option'),
                    RadioGroup(
                      correctOption: _correctOption,
                      onChanged: (value) {
                        setState(() {
                          _correctOption = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _uploadQuestion,
                      child: Text(widget.questionToEdit != null
                          ? 'Update Question'
                          : 'Upload Question'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class RadioGroup extends StatelessWidget {
  final int? correctOption;
  final ValueChanged<int?> onChanged;

  const RadioGroup({super.key, this.correctOption, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) {
        return RadioListTile<int>(
          title: Text('Option ${index + 1}'),
          value: index,
          groupValue: correctOption,
          onChanged: onChanged,
        );
      }),
    );
  }
}
