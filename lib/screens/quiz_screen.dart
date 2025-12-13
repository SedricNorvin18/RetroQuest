import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:retroquest/models/question_model.dart';
import 'package:retroquest/models/db_connect.dart';
import 'package:retroquest/screens/quiz_results_screen.dart';

class QuizScreen extends StatefulWidget {

  final String subject;
  final String teacherId;
  const QuizScreen({super.key, required this.subject,required this.teacherId,});
  

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final DbConnect _db = DbConnect();
  late Future<List<Question>> _questionsFuture;
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  String? _selectedAnswer;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode(); // <--- ADD THIS
  bool _isAnswered = false;
  String? _teacherId;
  Timer? _timer;
  int _countdown = 0;
  final List<Map<String, dynamic>> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions().then((questions) {
      if (questions.isNotEmpty) {
        _startTimer();
      }
      return questions;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _textFocusNode.dispose(); // <--- ADD THIS
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final timeLimit = _questions[_currentIndex].timeLimit;
    if (timeLimit != null && timeLimit > 0) {
      setState(() {
        _countdown = timeLimit;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() {
            _countdown--;
          });
        } else {
          _timer?.cancel();
          _answerQuestion(""); // Timeout
        }
      });
    }
  }

  Future<List<Question>> _loadQuestions() async {
    final subjectDoc = await FirebaseFirestore.instance
        .collection('subjects')
        .doc(widget.subject)
        .get();
    if (subjectDoc.exists) {
      _teacherId = subjectDoc.data()!['teacherId'];
    }

    final fetched = await _db.fetchQuestions(subject: widget.subject);
    _questions = fetched;
    return fetched;
  }

  void _answerQuestion(String answer) {
    if (_isAnswered) return;
    _timer?.cancel();

    final currentQuestion = _questions[_currentIndex];
    final isCorrect = answer.toLowerCase() == currentQuestion.correctAnswer.toLowerCase();

    // Store the attempt details
    _userAnswers.add({
      'question': currentQuestion.text,
      'correctAnswer': currentQuestion.correctAnswer,
      'userAnswer': answer,
      'isCorrect': isCorrect,
    });

    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      if (isCorrect) {
        _score += 10;
        _correctAnswers++;
      } else {
        _incorrectAnswers++;
      }
    });

    Timer(const Duration(seconds: 2), _nextQuestion);
  }

  Future<void> _submitQuiz() async {
    if (_teacherId != null) {
      await _db.saveQuizAttempt(
        score: _score,
        subjectId: widget.subject,
        teacherId: _teacherId!,
        totalQuestions: _questions.length,
        correctAnswers: _correctAnswers,
        incorrectAnswers: _incorrectAnswers,
        attemptDetails: _userAnswers,
      );
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: _score,
          totalQuestions: _questions.length,
          correctAnswers: _correctAnswers,
          incorrectAnswers: _incorrectAnswers,
          attemptDetails: _userAnswers, // <--- PASS THE DATA HERE
        ),
      ),
    );
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
        _textController.clear();
      });
      _startTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textFocusNode.requestFocus();
      });
    } else {
      // End of the quiz
      _submitQuiz();
    }
  }

  Color _getOptionColor(String option) {
    if (!_isAnswered) {
      return const Color(0xFF2A314D);
    }
    if (option == _questions[_currentIndex].correctAnswer) {
      return Colors.green.shade700;
    } else if (option == _selectedAnswer) {
      return Colors.red.shade700;
    }
    return const Color(0xFF2A314D);
  }

  IconData _getOptionIcon(String option) {
    if (!_isAnswered) {
      return Icons.radio_button_unchecked;
    }
    if (option == _questions[_currentIndex].correctAnswer) {
      return Icons.check_circle;
    } else if (option == _selectedAnswer) {
      return Icons.cancel;
    }
    return Icons.radio_button_unchecked;
  }

  Widget _buildOptionButton(String option) {
    return GestureDetector(
      onTap: _isAnswered ? null : () => _answerQuestion(option),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _getOptionColor(option),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _isAnswered ? _getOptionColor(option) : Colors.grey.shade600,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getOptionIcon(option),
              color: Colors.white,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                option,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Question question) {
    // 1. Initialize list to hold image and answers
    final List<Widget> widgets = [];

    // 2. Add Image Display Logic (if URL exists)
    if (question.imageUrl != null && question.imageUrl!.isNotEmpty) {
      widgets.add(
        // 🔑 SURE FIX: Apply the unique Key to the parent Container/Padding
        // This forces Flutter to tear down and rebuild the entire image section
        // every time _currentIndex changes.
        Padding(
          key: ValueKey('image-section-$_currentIndex'), // 🔑 Apply Key here
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Container(
            constraints:
                const BoxConstraints(maxHeight: 200, maxWidth: double.infinity),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.greenAccent, width: 2),
              color: const Color(0xFF2A314D),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                // We keep the URL, but the parent Key ensures a full rebuild
                question.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.greenAccent,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.redAccent)),
              ),
            ),
          ),
        ),
      );
    }

    // 3. Add Answer Controls based on Question Type
    switch (question.questionType) {
      case QuestionType.trueFalse:
        // Use the new helper for both True and False options
        widgets.addAll([
          _buildOptionButton('True'),
          _buildOptionButton('False'),
        ]);
        break;

      case QuestionType.fillInTheBlank:
      case QuestionType.shortAnswer:
        // Add text field and submit button
        widgets.addAll([
          TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            enabled: !_isAnswered,
            decoration: InputDecoration(
              hintText: 'Type your answer here',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF2A314D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          if (_isAnswered)
            Text(
              'Correct Answer: ${question.correctAnswer}',
              style: const TextStyle(color: Colors.greenAccent),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isAnswered
                ? null
                : () => _answerQuestion(_textController.text),
            child: const Text('Submit'),
          ),
        ]);
        break;

      case QuestionType.multipleChoice:
        // Use the new helper for all options
        widgets.addAll(question.options.map((option) {
          return _buildOptionButton(option);
        }).toList());
        break;
    }

    // 4. Return Column containing all collected widgets (Image + Answers)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1E2336),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/retro_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withAlpha(153)),
          FutureBuilder<List<Question>>(
            future: _questionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No questions found for ${widget.subject}.',
                    style:
                        textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                );
              }

              final currentQuestion = _questions[_currentIndex];
              double progress = (_currentIndex + 1) / _questions.length;

              return SafeArea(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    margin: const EdgeInsets.all(20.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(204),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withAlpha(102),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text('Quiz: ${widget.subject}',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontFamily: "PressStart2P",
                            )),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: LinearPercentIndicator(
                            lineHeight: 20.0,
                            percent: progress,
                            center: Text(
                              "${(_currentIndex + 1)}/${_questions.length}",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.grey.shade700,
                            progressColor: Colors.greenAccent,
                            barRadius: const Radius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (currentQuestion.timeLimit != null &&
                            currentQuestion.timeLimit! > 0)
                          Text(
                            'Time: $_countdown',
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontFamily: "PressStart2P",
                            ),
                          ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A314D),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(128),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                currentQuestion.text,
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Flexible(
                          child: SingleChildScrollView(
                            // Added SingleChildScrollView
                            child: _buildQuestionWidget(currentQuestion),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Score: $_score',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineLarge?.copyWith(
                            color: Colors.greenAccent,
                            fontFamily: "PressStart2P",
                            shadows: [
                              const Shadow(
                                blurRadius: 10.0,
                                color: Colors.greenAccent,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
