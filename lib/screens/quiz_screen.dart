import 'package:flutter/material.dart';
import '../models/db_connect.dart';
import '../models/question_model.dart';

class QuizScreen extends StatefulWidget {
  final String subject;
  const QuizScreen({super.key, required this.subject});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final DbConnect _db = DbConnect();
  List<Question> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final fetched = await _db.fetchQuestions(subject: widget.subject);

    if (!mounted) return;
    setState(() {
      _questions = fetched;
      _isLoading = false;
    });
  }

  void _checkAnswer(String? option) {
    if (option == null) return;
    setState(() {
      _selectedAnswer = option;
    });
    final current = _questions[_currentIndex];
    final isCorrect = current.correctAnswer == option;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "✅ Correct!" : "❌ Wrong!"),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Quiz - ${widget.subject}")),
        body: const Center(child: Text('No questions found for this subject.')),
      );
    }

    final current = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text("Quiz - ${widget.subject}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q${_currentIndex + 1}: ${current.text}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RadioGroup(
              options: current.options,
              selectedAnswer: _selectedAnswer,
              onChanged: _checkAnswer,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex--;
                        _selectedAnswer = null;
                      });
                    },
                    child: const Text("Previous"),
                  ),
                if (_currentIndex < _questions.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex++;
                        _selectedAnswer = null;
                      });
                    },
                    child: const Text("Next"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RadioGroup extends StatelessWidget {
  final List<String> options;
  final String? selectedAnswer;
  final ValueChanged<String?> onChanged;

  const RadioGroup(
      {super.key,
      required this.options,
      this.selectedAnswer,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: selectedAnswer,
          onChanged: onChanged,
        );
      }).toList(),
    );
  }
}
