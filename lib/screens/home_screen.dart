import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../widgets/question_widget.dart';
import '../widgets/result_box.dart';
import '../models/db_connect.dart';

class HomeScreen extends StatefulWidget {
  final String subject;
  const HomeScreen({super.key, required this.subject});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final db = DbConnect(); // 1. Make db final

  List<Question>? _questions;
  bool _isLoading = true;
  String? _selectedAnswer;

  int index = 0;
  int score = 0;

  static const _kTimerDuration = 30;
  int timeLeft = _kTimerDuration;
  Timer? _timer;

  late AnimationController _rgbController;
  late Animation<Color?> _rgbAnimation;

  @override
  void initState() {
    super.initState();
    _loadAndShuffleQuestions();

    _rgbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _rgbAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.red.shade300, end: Colors.green.shade300),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.green.shade300, end: Colors.blue.shade300),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.blue.shade300, end: Colors.red.shade300),
        weight: 1,
      ),
    ]).animate(_rgbController);
  }

  @override
  void dispose() {
    _rgbController.dispose();
    _timer?.cancel(); // 6. Cancel timer on dispose
    super.dispose();
  }

  Future<void> _loadAndShuffleQuestions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final fetchedQuestions = await db.fetchQuestions(subject: widget.subject);
    fetchedQuestions.shuffle(Random());

    // 2. Add mounted check
    if (mounted) {
      setState(() {
        _questions = fetchedQuestions;
        _isLoading = false;
      });
      if (fetchedQuestions.isNotEmpty) {
        startTimer();
      }
    }
  }

  void startTimer() {
    _timer?.cancel();
    timeLeft = _kTimerDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      // 2. Add mounted check
      if (!mounted) {
        t.cancel();
        return;
      }
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        nextQuestion();
      }
    });
  }

  void nextQuestion() {
    _timer?.cancel();
    final questions = _questions!;
    if (index < questions.length - 1) {
      setState(() {
        index++;
        _selectedAnswer = null; // 4. Simplify state logic
      });
      startTimer();
    } else {
      // 3. Use BuildContext safely
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => ResultBox(
            score: score,
            totalQuestions: questions.length,
            onRestart: () {
              if (mounted) {
                Navigator.pop(ctx);
              }
              setState(() {
                index = 0;
                score = 0;
                _selectedAnswer = null;
              });
              _loadAndShuffleQuestions();
            },
          ),
        );
      }
    }
  }

  void checkAnswer(String selectedOption) {
    if (_selectedAnswer != null) return; // 4. Simplify state logic

    setState(() {
      _selectedAnswer = selectedOption;
      if (selectedOption == _questions![index].correctAnswer) {
        score++;
      }
    });

    Future.delayed(
      const Duration(seconds: 1),
      // 2. Add mounted check
      () {
        if (mounted) {
          nextQuestion();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions == null || _questions!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Quiz - ${widget.subject}")),
        body: const Center(child: Text("No questions available for this subject.")),
      );
    }

    final questions = _questions!;
    final options = questions[index].options;

    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz - ${widget.subject}"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _rgbAnimation,
                builder: (context, child) => Text(
                  "RetroQuiz",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: _rgbAnimation.value,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: timeLeft / _kTimerDuration,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(
                      timeLeft < 10 ? Colors.redAccent : Colors.greenAccent,
                    ),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text("Time Left: $timeLeft s",
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38), // Replaced withOpacity
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51), // Replaced withOpacity
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: QuestionWidget(
                  indexAction: index,
                  question: questions[index].text,
                  totalQuestions: questions.length,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: options.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 3,
                  ),
                  itemBuilder: (context, i) {
                    final option = options[i];
                    final isCorrect = option == questions[index].correctAnswer;

                    Color cardColor = Colors.white.withAlpha(51); // Replaced withOpacity
                    if (_selectedAnswer != null) {
                      if (isCorrect) {
                        cardColor = Colors.greenAccent.withAlpha(204); // Replaced withOpacity
                      } else if (_selectedAnswer == option) {
                        cardColor = Colors.redAccent.withAlpha(204); // Replaced withOpacity
                      }
                    }

                    return GestureDetector(
                      onTap: () => checkAnswer(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51), // Replaced withOpacity
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
