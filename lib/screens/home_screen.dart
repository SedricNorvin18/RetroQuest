import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../widgets/question_widget.dart';
import '../widgets/result_box.dart';
import '../models/db_connect.dart';

class HomeScreen extends StatefulWidget {
  final String subject; // ✅ Add subject
  const HomeScreen({super.key, required this.subject});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  var db = DbConnect();
  late Future<List<Question>> _questions;

  int index = 0;
  bool isAnswered = false;
  int score = 0;
  int timeLeft = 30;
  Timer? timer;

  // RGB title animation
  late AnimationController _rgbController;
  late Animation<Color?> _rgbAnimation;

  @override
  void initState() {
    super.initState();
    // ✅ Pass subject here
    _questions = db.fetchQuestions(subject: widget.subject);

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
    timer?.cancel();
    super.dispose();
  }

  // Timer now needs questions
  void startTimer(List<Question> questions) {
    timer?.cancel();
    timeLeft = 30;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        nextQuestion(context, questions);
      }
    });
  }

  void nextQuestion(BuildContext context, List<Question> questions) {
    if (index < questions.length - 1) {
      setState(() {
        index++;
        isAnswered = false;
      });
      startTimer(questions);
    } else {
      timer?.cancel();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ResultBox(
          score: score,
          totalQuestions: questions.length,
          onRestart: () {
            Navigator.pop(context);
            setState(() {
              index = 0;
              score = 0;
              isAnswered = false;
              // ✅ Reload with subject
              _questions = db.fetchQuestions(subject: widget.subject);
            });
          },
        ),
      );
    }
  }

  void checkAnswer(String selectedOption, List<Question> questions) {
    if (!isAnswered) {
      setState(() {
        isAnswered = true;
        if (questions[index].options[selectedOption] == true) score++;
      });
      Future.delayed(
        const Duration(seconds: 1),
        () => nextQuestion(context, questions),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Question>>(
      future: _questions,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No questions available")),
          );
        }

        final questions = snapshot.data!;

        // Start the timer once data is loaded
        if (timer == null || !timer!.isActive) {
          startTimer(questions);
        }

        final options = questions[index].options;

        return Scaffold(
          appBar: AppBar(
            title: Text("Quiz - ${widget.subject}"), // ✅ Show subject in header
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

                  // Timer bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: timeLeft / 30,
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

                  // Question card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: QuestionWidget(
                      indexAction: index,
                      question: questions[index].title,
                      totalQuestions: questions.length,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Options Grid
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
                        final entry = options.entries.elementAt(i);
                        final isCorrect = questions[index].options[entry.key] == true;
                        Color cardColor = Colors.white.withOpacity(0.2);

                        if (isAnswered) {
                          if (isCorrect) {
                            cardColor = Colors.greenAccent.withOpacity(0.8);
                          } else if (entry.key ==
                              options.keys.elementAt(i)) {
                            cardColor = Colors.redAccent.withOpacity(0.8);
                          }
                        }

                        return GestureDetector(
                          onTap: () => checkAnswer(entry.key, questions),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              entry.key,
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
      },
    );
  }
}
