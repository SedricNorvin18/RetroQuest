import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/question_model.dart';
import '../models/db_connect.dart';
import 'quiz_results_screen.dart';

class DungeonQuizScreen extends StatefulWidget {
  final String subject;
  final String teacherId;

  const DungeonQuizScreen({
    super.key,
    required this.subject,
    required this.teacherId,
  });

  @override
  State<DungeonQuizScreen> createState() => _DungeonQuizScreenState();
}

class _DungeonQuizScreenState extends State<DungeonQuizScreen>
    with TickerProviderStateMixin {
  final DbConnect _db = DbConnect();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Data
  List<Question> _questions = [];
  int _currentIndex = 0;

  // Game State
  int _score = 0;
  int _playerHp = 3; // "Hearts" or Health
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  final List<Map<String, dynamic>> _userAnswers = [];

  // Animation State
  bool _isPlayerAttacking = false;
  bool _isEnemyAttacking = false;
  bool _isDamaged = false; // Screen shake/red flash effect

  // Timer for "Enemy Attack Turn"
  Timer? _attackTimer;
  double _timeToAttack = 1.0; // 1.0 = Full time, 0.0 = Attack triggers
  static const int _secondsPerQuestion = 15; // Time to answer before hit

  late AudioPlayer _sfxPlayer;

  @override
  void initState() {
    super.initState();
    _sfxPlayer = AudioPlayer();
    _loadQuestions();
  }

  @override
  void dispose() {
    _attackTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final allQuestions = await _db.fetchQuestions(subject: widget.subject);

    // FILTER: Only allow text-based questions for this mode
    final textQuestions = allQuestions
        .where((q) =>
            q.questionType == QuestionType.shortAnswer ||
            q.questionType == QuestionType.fillInTheBlank)
        .toList();

    if (mounted) {
      if (textQuestions.isEmpty) {
        _showIncompatibleDialog();
      } else {
        setState(() {
          _questions = textQuestions;
          _startTurn();
        });
      }
    }
  }

  void _showIncompatibleDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2336),
        title: const Text("No Text Questions",
            style: TextStyle(
                color: Colors.white, fontFamily: "PressStart2P", fontSize: 12)),
        content: const Text(
          "This subject has no Fill-in-the-Blank or Short Answer questions suitable for Dungeon Mode.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Go Back",
                style: TextStyle(color: Colors.greenAccent)),
          )
        ],
      ),
    );
  }

  // --- GAME LOGIC ---

  void _startTurn() {
    _timeToAttack = 1.0;
    _textController.clear();

    // Auto-focus the text field so user can type immediately
    FocusScope.of(context).requestFocus(_focusNode);

    _attackTimer?.cancel();
    _attackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _timeToAttack -= (1 / (_secondsPerQuestion * 10)); // Decrement bar

        if (_timeToAttack <= 0) {
          _handleTimeRunOut();
        }
      });
    });
  }

  void _handleTimeRunOut() {
    _attackTimer?.cancel();
    _takeDamage(isTimeOut: true);
  }

  void _submitAnswer() {
    if (_textController.text.trim().isEmpty) return;

    _attackTimer?.cancel();
    final question = _questions[_currentIndex];
    final userAnswer = _textController.text.trim();

    // Case-insensitive comparison
    final isCorrect =
        userAnswer.toLowerCase() == question.correctAnswer.toLowerCase();

    _userAnswers.add({
      'question': question.text,
      'correctAnswer': question.correctAnswer,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    });

    if (isCorrect) {
      _performPlayerAttack();
    } else {
      _takeDamage(isTimeOut: false);
    }
  }

void _performPlayerAttack() {
    setState(() {
      _isPlayerAttacking = true;
    });

    // Change this to a hero sound, e.g., 'sword_hit.wav' or 'laser.wav'
    _sfxPlayer.play(AssetSource('audio/sword_hit.wav')); 

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isPlayerAttacking = false;
        _score += 100 + (100 * _timeToAttack).toInt();
        _correctAnswers++;
        _nextQuestion();
      });
    });
  }

void _takeDamage({required bool isTimeOut}) {
    setState(() {
      _isEnemyAttacking = true;
      _playerHp--;
      _incorrectAnswers++;
    });

    // Flash Screen Red
    setState(() => _isDamaged = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _isDamaged = false);
    });

    // --- FIX: Play Dragon Attack Sound Here ---
    // Previously, this was only playing 'damage.wav'. 
    // Now it plays the attack sound when the timer runs out or you miss.
    _sfxPlayer.play(AssetSource('audio/dragon_attack.wav'));

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_playerHp <= 0) {
        _endGame();
      } else {
        setState(() {
          _isEnemyAttacking = false;
          _nextQuestion();
        });
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _startTurn();
    } else {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    _attackTimer?.cancel();

    await _db.saveQuizAttempt(
      score: _score,
      subjectId: widget.subject,
      teacherId: widget.teacherId,
      totalQuestions: _questions.length,
      correctAnswers: _correctAnswers,
      incorrectAnswers: _incorrectAnswers,
      attemptDetails: _userAnswers,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: _score,
          totalQuestions: _questions.length,
          correctAnswers: _correctAnswers,
          incorrectAnswers: _incorrectAnswers,
          attemptDetails: _userAnswers,
        ),
      ),
    );
  }

  // --- WIDGETS ---

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // Allow keyboard to push UI up
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // HEALTH BAR
            Row(
              children: List.generate(
                  3,
                  (index) => Icon(
                        index < _playerHp
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.redAccent,
                      )),
            ),
            // SCORE
            Text("SCORE: $_score",
                style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 12,
                    color: Colors.yellow)),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. BACKGROUND (Dungeon)
          Positioned.fill(
            child: Image.asset(
              'assets/images/dungeon.jpg',
              fit: BoxFit.fill,
              // All coloring and opacity properties have been removed!
              // The image will now show in its original, full clarity.
            ),
          ),

          // 2. DAMAGE FLASH EFFECT
          if (_isDamaged)
            Positioned.fill(
                child: Container(color: Colors.red.withOpacity(0.3))),

          Column(
            children: [
              const SizedBox(height: 20),

              // 3. ENEMY AREA (The Question Visualized)
              Expanded(
                flex: 4,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.translationValues(
                        _isEnemyAttacking
                            ? 0
                            : (_isPlayerAttacking ? 20 : 0), // Hit react
                        _isEnemyAttacking ? 50 : 0, // Attack lunge
                        0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ENEMY SPRITE (Use a placeholder icon if you don't have an image)
                        Image.asset('assets/images/monster.gif'),

                        const SizedBox(height: 10),
                        // TIME BAR
                        SizedBox(
                          width: 150,
                          child: LinearProgressIndicator(
                            value: _timeToAttack,
                            backgroundColor: Colors.grey[800],
                            color: _timeToAttack < 0.3
                                ? Colors.red
                                : Colors.orange,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. DIALOGUE BOX (The Question Text)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[900]!.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "MONSTER ASKS:",
                      style: TextStyle(
                          color: Colors.yellowAccent,
                          fontFamily: 'PressStart2P',
                          fontSize: 10),
                    ),
                    const SizedBox(height: 10),
                    // --- NEW CODE START: Display Image if available ---
                    if (_questions[_currentIndex].imageUrl != null &&
                        _questions[_currentIndex].imageUrl!.isNotEmpty) ...[
                      Container(
                        height:
                            120, // Limit height to prevent covering the screen
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Image.network(
                          _questions[_currentIndex].imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                    Text(
                      _questions[_currentIndex].text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'PressStart2P',
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 5. INPUT COMMAND (Answer Field)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black87,
                child: Row(
                  children: [
                    const Text("> ",
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 18,
                            fontFamily: 'PressStart2P')),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'PressStart2P',
                            fontSize: 14),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type answer...",
                          hintStyle: TextStyle(
                              color: Colors.white24,
                              fontFamily: 'PressStart2P',
                              fontSize: 12),
                        ),
                        onSubmitted: (_) => _submitAnswer(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.greenAccent),
                      onPressed: _submitAnswer,
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
