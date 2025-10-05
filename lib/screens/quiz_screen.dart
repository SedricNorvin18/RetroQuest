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
  final DbConnect db = DbConnect();
  List<Question> questions = [];
  int currentIndex = 0;
  String? selectedAnswer;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final fetched = await db.fetchQuestions(subject: widget.subject);
    setState(() => questions = fetched);
  }

  void checkAnswer(String optionKey) {
    setState(() {
      selectedAnswer = optionKey;
    });
    final current = questions[currentIndex];
    final isCorrect = current.options[optionKey] ?? false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? "✅ Correct!" : "❌ Wrong!"),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final current = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text("Quiz - ${widget.subject}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q${currentIndex + 1}: ${current.title}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...current.options.entries.map((entry) {
              final key = entry.key;

              return ListTile(
                title: Text(key),
                leading: Radio<String>(
                  value: key,
                  groupValue: selectedAnswer,
                  onChanged: (val) => checkAnswer(val!),
                ),
              );
            }),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentIndex--;
                        selectedAnswer = null;
                      });
                    },
                    child: const Text("Previous"),
                  ),
                if (currentIndex < questions.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentIndex++;
                        selectedAnswer = null;
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
