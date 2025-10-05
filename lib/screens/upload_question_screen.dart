import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadQuestionScreen extends StatefulWidget {
  final String subject;
  const UploadQuestionScreen({super.key, required this.subject});

  @override
  State<UploadQuestionScreen> createState() => _UploadQuestionScreenState();
}

class _UploadQuestionScreenState extends State<UploadQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  int? _correctIndex;

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate() && _correctIndex != null) {
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection("subjects")
          .doc(widget.subject)
          .collection("questions")
          .add({
        "title": _titleController.text.trim(),
        "options": {
          for (int i = 0; i < _optionControllers.length; i++)
            _optionControllers[i].text.trim(): i == _correctIndex,
        },
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Question added successfully!")),
      );

      _titleController.clear();
      for (var controller in _optionControllers) {
        controller.clear();
      }
      setState(() => _correctIndex = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please complete all fields")),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Question - ${widget.subject}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Question Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Question"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter question" : null,
              ),
              const SizedBox(height: 16),

              // Options
              for (int i = 0; i < _optionControllers.length; i++)
                ListTile(
                  title: TextFormField(
                    controller: _optionControllers[i],
                    decoration: InputDecoration(labelText: "Option ${i + 1}"),
                    validator: (value) => value == null || value.isEmpty
                        ? "Enter option ${i + 1}"
                        : null,
                  ),
                  leading: Radio<int>(
                    value: i,
                    groupValue: _correctIndex,
                    onChanged: (value) {
                      setState(() => _correctIndex = value);
                    },
                  ),
                ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Question"),
                onPressed: _saveQuestion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
