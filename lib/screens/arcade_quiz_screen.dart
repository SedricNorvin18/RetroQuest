import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/db_connect.dart';
import 'quiz_results_screen.dart';

// Helper class for the falling targets
class _Target {
  final String text;
  final bool isCorrect;
  double positionX;
  double positionY; // 0.0 = Bottom, 1.0 = Top

  _Target({
    required this.text,
    required this.isCorrect,
    required this.positionX,
    required this.positionY,
  });
}

class ArcadeQuizScreen extends StatefulWidget {
  final String subject;
  final String teacherId;
  final String difficulty; // 'Easy', 'Normal', or 'Hard'

  const ArcadeQuizScreen({
    super.key,
    required this.subject,
    required this.teacherId,
    required this.difficulty,
  });

  @override
  State<ArcadeQuizScreen> createState() => _ArcadeQuizScreenState();
}

class _ArcadeQuizScreenState extends State<ArcadeQuizScreen> {
  final DbConnect _db = DbConnect();
  List<Question> _questions = [];
  int _currentIndex = 0;

  // --- GAME STATE ---
  int _score = 0;
  int _lives = 3;
  double _gameSpeed = 0.005; // Default
  Timer? _gameTimer;
  Timer? _spawnTimer; // <--- NEW: Timer for sequential dropping
  bool _isGameOver = false;

  // --- PLAYER & PROJECTILE STATE ---
  double _shipPositionX = 0.5;
  final double _shipPositionY = 0.1;
  double _projectilePositionY = 0.0;
  double _projectilePositionX = 0.5;
  bool _isShooting = false;

  // --- QUIZ DATA ---
  List<_Target> _targets = [];
  List<String> _pendingOptions = []; // <--- NEW: Options yet to be spawned
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  final List<Map<String, dynamic>> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _setDifficulty();
    _loadQuestions();
  }

  void _setDifficulty() {
    switch (widget.difficulty) {
      case 'Easy':
        _gameSpeed = 0.003; // Slightly faster than original 0.002 for action
        break;
      case 'Hard':
        _gameSpeed = 0.009; // Adjusted fast drop
        break;
      case 'Normal':
      default:
        _gameSpeed = 0.006; // Moderate drop
        break;
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel(); // <--- Cancel spawn timer
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final allQuestions = await _db.fetchQuestions(subject: widget.subject);

    // FILTER: Only keep questions that have options (Multiple Choice / True-False)
    final arcadeQuestions = allQuestions
        .where((q) => q.options.isNotEmpty)
        .toList();

    if (mounted) {
      setState(() {
        _questions = arcadeQuestions;

        if (_questions.isNotEmpty) {
          _setupNextQuestion();
          _startGameLoop();
        } else {
          _showIncompatibleDialog();
        }
      });
    }
  }

  void _showIncompatibleDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2336),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.pinkAccent, width: 2)),
        title: const Text("Mode Unavailable",
            style: TextStyle(
                color: Colors.white,
                fontFamily: "PressStart2P",
                fontSize: 14)),
        content: const Text(
          "This quiz contains only text-based questions which cannot be played in Arcade Mode.\n\nPlease play Classic Mode instead.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit screen
            },
            child: const Text("Go Back",
                style: TextStyle(color: Colors.greenAccent)),
          )
        ],
      ),
    );
  }

  // NEW: Logic to spawn targets one by one
  void _startTargetSpawner() {
    _spawnTimer?.cancel();
    // Spawn rate based on difficulty: Easy (2.5s), Normal (1.8s), Hard (1.2s)
    final spawnDuration = widget.difficulty == 'Easy'
        ? 2500
        : widget.difficulty == 'Normal'
            ? 1800
            : 1200;

    _spawnTimer = Timer.periodic(Duration(milliseconds: spawnDuration), (timer) {
      if (_isGameOver || !mounted) {
        timer.cancel();
        return;
      }

      // Only spawn if we have pending options and not too many targets on screen
      if (_pendingOptions.isNotEmpty && _targets.length < 4) {
        setState(() {
          // Use Random() to pick a target to drop next, not just the first one
          final randomIndex = Random().nextInt(_pendingOptions.length);
          final optionToDrop = _pendingOptions.removeAt(randomIndex);
          final isCorrect = optionToDrop == _questions[_currentIndex].correctAnswer;

          // Randomize the X position for spawning (between 0.1 and 0.9)
          final randomX = Random().nextDouble().clamp(0.1, 0.9);

          _targets.add(_Target(
            text: optionToDrop,
            isCorrect: isCorrect,
            positionX: randomX,
            positionY: 1.05, // Start completely OFF SCREEN TOP
          ));
        });
      } else if (_pendingOptions.isEmpty && _targets.isEmpty) {
        // Stop spawning if all options are gone and no targets are on screen
        // This case should ideally only occur if the correct answer escaped (handled in _handleTargetEscape)
        timer.cancel();
      }
    });
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      // NOTE: _targets.isEmpty is only checked when loading questions/setup
      // The game loop should rely on the completion logic in the handlers
      if (_isGameOver || !mounted) {
        timer.cancel();
        if (_isGameOver) _submitQuiz();
        return;
      }

      setState(() {
        // 1. Move Targets DOWN (decrease Y)
        // Use a temporary list to prevent concurrent modification if one escapes
        final targetsToRemove = <_Target>[];
        for (var target in _targets) {
          target.positionY -= _gameSpeed;

          // Check if target hit the bottom (passed ship)
          if (target.positionY < _shipPositionY - 0.05) {
            targetsToRemove.add(target);
            continue; // Go to next target
          }
        }

        // Handle escape events outside the main movement loop
        for (var escapedTarget in targetsToRemove) {
          _handleTargetEscape(escapedTarget);
        }

        // 2. Move Projectile UP (increase Y)
        if (_isShooting) {
          _projectilePositionY += 0.05;
          _checkCollision();
          if (_projectilePositionY > 1.0) {
            _isShooting = false;
          }
        }
      });
    });
  }

  void _setupNextQuestion() {
    if (_currentIndex >= _questions.length) {
      _isGameOver = true;
      _gameTimer?.cancel();
      _spawnTimer?.cancel(); // Cancel spawner at game end
      return;
    }

    final currentQuestion = _questions[_currentIndex];
    final options = [...currentQuestion.options];
    options.shuffle(Random()); // Shuffle options for random drop sequence

    _pendingOptions = options; // Populate the pending list
    _targets = []; // Clear current targets

    _isShooting = false;
    _projectilePositionY = _shipPositionY + 0.01;
    _projectilePositionX = _shipPositionX;

    _startTargetSpawner(); // Start spawning targets

    // Slight speed increase per level, but capped
    if (_gameSpeed < 0.02) {
      _gameSpeed *= 1.02;
    }
  }

  void _handleTargetEscape(_Target escapedTarget) {
    if (!_isGameOver) {
      setState(() {
        _targets.remove(escapedTarget); // Always remove the escaped target

        // Only penalize if the correct answer escapes
        if (escapedTarget.isCorrect) {
          _lives--;
          _incorrectAnswers++;
          _userAnswers.add({
            'question': _questions[_currentIndex].text,
            'correctAnswer': _questions[_currentIndex].correctAnswer,
            'userAnswer': '(Missed Correct Answer)', // Updated answer text
            'isCorrect': false,
          });

          // End game or move to next question
          if (_lives <= 0) {
            _isGameOver = true;
            _gameTimer?.cancel();
            _spawnTimer?.cancel(); // Cancel spawner
            _submitQuiz();
          } else {
            // Correct answer missed: Penalty + Next Question
            _gameTimer?.cancel();
            _spawnTimer?.cancel(); // Cancel spawner
            Timer(const Duration(milliseconds: 800), () {
              _currentIndex++;
              _setupNextQuestion();
              _startGameLoop();
            });
          }
        }
        // If an incorrect target escapes, it is only removed (no penalty, loop continues)
      });
    }
  }

  void _checkCollision() {
    if (!_isShooting) return;

    for (int i = 0; i < _targets.length; i++) {
      final target = _targets[i];
      const targetSize = 0.15;

      if (_projectilePositionY < target.positionY + targetSize / 2 &&
          _projectilePositionY > target.positionY - targetSize / 2 &&
          _projectilePositionX < target.positionX + targetSize / 2 &&
          _projectilePositionX > target.positionX - targetSize / 2) {
        _isShooting = false;
        
        // Remove the target that was hit
        setState(() {
          _targets.removeAt(i);
        });

        if (target.isCorrect) {
          _handleCorrectAnswer(target.text);
        } else {
          _handleIncorrectAnswer(target.text);
        }
        return;
      }
    }
  }

  void _handleCorrectAnswer(String selectedAnswer) {
    _score += 20;
    _correctAnswers++;

    _userAnswers.add({
      'question': _questions[_currentIndex].text,
      'correctAnswer': _questions[_currentIndex].correctAnswer,
      'userAnswer': selectedAnswer,
      'isCorrect': true,
    });

    // Correct hit: Score + Next Question
    _gameTimer?.cancel();
    _spawnTimer?.cancel(); // Cancel spawner
    
    // Clear any remaining targets for a clean transition
    _targets.clear();

    Timer(const Duration(milliseconds: 500), () {
      _currentIndex++;
      _setupNextQuestion();
      _startGameLoop();
    });
  }

  void _handleIncorrectAnswer(String selectedAnswer) {
    _lives--;
    _incorrectAnswers++;

    _userAnswers.add({
      'question': _questions[_currentIndex].text,
      'correctAnswer': _questions[_currentIndex].correctAnswer,
      'userAnswer': selectedAnswer,
      'isCorrect': false,
    });

    if (_lives <= 0) {
      _isGameOver = true;
      _gameTimer?.cancel();
      _spawnTimer?.cancel(); // Cancel spawner
      _submitQuiz();
    } else {
      // Incorrect hit: Penalty + Next Question
      _gameTimer?.cancel();
      _spawnTimer?.cancel(); // Cancel spawner
      
      // Clear any remaining targets for a clean transition
      _targets.clear();
      
      Timer(const Duration(milliseconds: 500), () {
        _currentIndex++;
        _setupNextQuestion();
        _startGameLoop();
      });
    }
  }

  void _moveShip(double deltaX) {
    setState(() {
      _shipPositionX = (_shipPositionX + deltaX).clamp(0.1, 0.9);
      if (!_isShooting) {
        _projectilePositionX = _shipPositionX;
      }
    });
  }

  void _fireProjectile() {
    if (_isShooting || _isGameOver) return;
    setState(() {
      _isShooting = true;
      _projectilePositionX = _shipPositionX;
      _projectilePositionY = _shipPositionY + 0.01;
    });
  }

  Future<void> _submitQuiz() async {
    final totalQuestions = _questions.length;

    await _db.saveQuizAttempt(
      score: _score,
      subjectId: widget.subject,
      teacherId: widget.teacherId,
      totalQuestions: totalQuestions,
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
          totalQuestions: totalQuestions,
          correctAnswers: _correctAnswers,
          incorrectAnswers: _incorrectAnswers,
          attemptDetails: _userAnswers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    final currentQuestion = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/galaxy.jpg', fit: BoxFit.cover),
          Container(
              color: Colors.black.withValues(alpha: 0.3)), // Dim background

          // Question Display (Top)
          Align(
            alignment: const Alignment(0, -0.9),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.8),
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                currentQuestion.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'PressStart2P',
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Targets
          ..._targets.map((target) {
            return Positioned.fill(
              child: Align(
                alignment: Alignment(
                  target.positionX * 2 - 1,
                  1.0 - (target.positionY * 2),
                ),
                child: _buildTargetWidget(target),
              ),
            );
          }),

          // Projectile
          if (_isShooting)
            Positioned.fill(
              child: Align(
                alignment: Alignment(
                  _projectilePositionX * 2 - 1,
                  1.0 - (_projectilePositionY * 2),
                ),
                child: Container(
                  width: 5,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [BoxShadow(color: Colors.red, blurRadius: 8)],
                  ),
                ),
              ),
            ),

          // Player Ship
          Positioned.fill(
            child: Align(
              alignment: Alignment(
                _shipPositionX * 2 - 1,
                1.0 - (_shipPositionY * 2),
              ),
              child: Image.asset(
                'assets/images/ship.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // HUD & Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHud(),
                  const SizedBox(height: 20),
                  _buildControls(),
                ],
              ),
            ),
          ),

          if (_isGameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildTargetWidget(_Target target) {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.9),
        border: Border.all(color: Colors.pinkAccent, width: 2),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        target.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'PressStart2P',
          fontSize: 10,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildHud() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'SCORE: $_score',
          style: const TextStyle(
            color: Colors.yellowAccent,
            fontFamily: 'PressStart2P',
            fontSize: 16,
          ),
        ),
        Row(
          children: List.generate(
              _lives,
              (index) => const Icon(Icons.favorite,
                  color: Colors.redAccent, size: 20)),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () => _moveShip(-0.1),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
        ),
        GestureDetector(
          onTap: _fireProjectile,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.pinkAccent,
              shape: BoxShape.circle,
            ),
            child: const Text('FIRE',
                style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 10,
                    color: Colors.white)),
          ),
        ),
        GestureDetector(
          onTap: () => _moveShip(0.1),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      alignment: Alignment.center,
      child: const Text(
        'GAME OVER',
        style: TextStyle(
          color: Colors.redAccent,
          fontFamily: 'PressStart2P',
          fontSize: 32,
        ),
      ),
    );
  }
}