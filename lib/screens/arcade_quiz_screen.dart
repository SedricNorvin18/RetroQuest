import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/db_connect.dart';
import 'quiz_results_screen.dart'; // To navigate to results after the game

// Helper class for the falling targets (answers)
class _Target {
  final String text;
  final bool isCorrect;
  double positionX; // Normalized X position (0.0 to 1.0)
  double positionY; // Normalized Y position (0.0 to 1.0)

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
  const ArcadeQuizScreen({super.key, required this.subject,required this.teacherId,});

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
  double _gameSpeed = 0.005; // Target drop speed
  Timer? _gameTimer;
  bool _isGameOver = false;

  // --- PLAYER & PROJECTILE STATE ---
  double _shipPositionX = 0.5; // Player X position (0.0 to 1.0)
  double _projectilePositionY = 1.0;
  double _projectilePositionX = 0.5;
  bool _isShooting = false;
  
  // --- QUIZ & TARGET STATE ---
  List<_Target> _targets = [];
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  final List<Map<String, dynamic>> _userAnswers = []; // For persistence

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  Future<List<Question>> _loadQuestions() async {
    final questions = await _db.fetchQuestions(subject: widget.subject);
    if (mounted) {
      setState(() {
        _questions = questions;
        if (_questions.isNotEmpty) {
          _setupNextQuestion();
          _startGameLoop();
        }
      });
    }
    return questions;
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isGameOver || _targets.isEmpty || !mounted) {
        timer.cancel();
        if (_isGameOver) _submitQuiz();
        return;
      }
      
      setState(() {
        // 1. Target movement
        for (var target in _targets) {
          target.positionY -= _gameSpeed;
          
          // Check for targets hitting the bottom (game failure)
          if (target.positionY < 0.1) {
            _handleTargetEscape(target);
            return; // Stop processing targets and handle failure
          }
        }
        
        // 2. Projectile movement (only if shooting)
        if (_isShooting) {
          _projectilePositionY += 0.05; // Projectile speed
          
          // Check for collision
          _checkCollision();
          
          // Check if projectile missed the screen
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
      return;
    }
    
    final currentQuestion = _questions[_currentIndex];
    final options = [...currentQuestion.options];
    options.shuffle(Random());
    
    // Define target positions (X positions for 4 targets)
    final List<double> targetXs = [0.2, 0.4, 0.6, 0.8];

    _targets = List.generate(options.length, (i) {
      return _Target(
        text: options[i],
        isCorrect: options[i] == currentQuestion.correctAnswer,
        positionX: targetXs[i],
        positionY: 0.95, // Start near the top
      );
    });

    // Reset projectile
    _isShooting = false;
    _projectilePositionY = 1.0;
    _projectilePositionX = _shipPositionX;
    
    // Gradually increase difficulty
    _gameSpeed *= 1.05;
  }
  
  void _handleTargetEscape(_Target escapedTarget) {
    if (!_isGameOver) {
      _lives--;
      _incorrectAnswers++;
      // Record the missed question as incorrect
      _userAnswers.add({
        'question': _questions[_currentIndex].text,
        'correctAnswer': _questions[_currentIndex].correctAnswer,
        'userAnswer': '(Missed)',
        'isCorrect': false,
      });

      if (_lives <= 0) {
        _isGameOver = true;
        _gameTimer?.cancel();
        _submitQuiz();
      } else {
        // Move to next question after a brief pause
        _gameTimer?.cancel();
        Timer(const Duration(milliseconds: 800), () {
          _currentIndex++;
          _setupNextQuestion();
          _startGameLoop();
        });
      }
    }
  }

  void _checkCollision() {
    if (!_isShooting) return;
    
    // Collision detection is simplified: check if projectile is near a target's position
    for (int i = 0; i < _targets.length; i++) {
      final target = _targets[i];
      
      // Target box area check (simple square region)
      const targetSize = 0.15; // Target size in normalized coordinates
      if (_projectilePositionY < target.positionY + targetSize / 2 &&
          _projectilePositionY > target.positionY - targetSize / 2 &&
          _projectilePositionX < target.positionX + targetSize / 2 &&
          _projectilePositionX > target.positionX - targetSize / 2) {
        
        // Collision detected!
        _isShooting = false;
        
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
    _score += 20; // Increased score for game mode
    _correctAnswers++;
    
    _userAnswers.add({
      'question': _questions[_currentIndex].text,
      'correctAnswer': _questions[_currentIndex].correctAnswer,
      'userAnswer': selectedAnswer,
      'isCorrect': true,
    });
    
    // Move to next question
    _gameTimer?.cancel();
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
      _submitQuiz();
    } else {
      // Just reset the question targets, don't move index
      _gameTimer?.cancel();
      Timer(const Duration(milliseconds: 500), () {
        _setupNextQuestion();
        _startGameLoop();
      });
    }
  }

  void _moveShip(double deltaX) {
    setState(() {
      _shipPositionX = (_shipPositionX + deltaX).clamp(0.1, 0.9);
      // If not shooting, projectile follows the ship
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
      _projectilePositionY = 0.2; // Starting height above the ship
    });
  }
  
  Future<void> _submitQuiz() async {
    // Reuse the existing submission logic
    final totalQuestions = _questions.length;
    
    // Note: Since _teacherId is not readily available in this game flow, 
    // you'll need to pass it from the navigation screen, 
    // or remove the teacherId check if not needed for arcade attempts. 
    // Assuming for now you need the score to be submitted.
    await _db.saveQuizAttempt(
        score: _score,
        subjectId: widget.subject,
        teacherId: 'ARCADE_MODE', // Placeholder: Use a valid teacherId if needed
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

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background - Retro Starfield
          Image.asset('assets/images/retro_bg.jpg', fit: BoxFit.cover),
          
          // Question Display Area
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
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          // Targets (Answer Options)
          ..._targets.map((target) {
            return Positioned.fill(
              child: Align(
                alignment: Alignment(
                  target.positionX * 2 - 1, // Convert 0-1 to -1 to 1
                  target.positionY * 2 - 1,
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
                  _projectilePositionY * 2 - 1,
                ),
                child: Container(
                  width: 5,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(color: Colors.red, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),

          // Player Ship (or a placeholder)
          Positioned.fill(
            child: Align(
              alignment: Alignment(_shipPositionX * 2 - 1, 0.7),
              child: Image.asset(
                // Use the correct path to your ship image
                'assets/images/ship.png', 
                width: 70, // Adjust width/height as needed for your image size
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Game Controls and HUD
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
          
          // Game Over Screen Overlay
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
          fontSize: 8,
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
            fontSize: 14,
          ),
        ),
        Row(
          children: List.generate(_lives, (index) => const Icon(
            Icons.favorite, 
            color: Colors.redAccent, 
            size: 20
          )),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Left button
        ElevatedButton(
          onPressed: () => _moveShip(-0.05),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(15),
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.arrow_back_ios_new),
        ),
        
        // Fire button
        ElevatedButton(
          onPressed: _fireProjectile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(25),
            shape: const CircleBorder(),
          ),
          child: const Text(
            'FIRE', 
            style: TextStyle(fontFamily: 'PressStart2P', fontSize: 10)
          ),
        ),
        
        // Right button
        ElevatedButton(
          onPressed: () => _moveShip(0.05),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(15),
            shape: const CircleBorder(),
          ),
          child: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'GAME OVER',
            style: TextStyle(
              color: Colors.redAccent,
              fontFamily: 'PressStart2P',
              fontSize: 32,
              shadows: [
                Shadow(color: Colors.red, blurRadius: 10),
              ]
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // SubmitQuiz is already called when _isGameOver is set
              Navigator.pop(context); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'VIEW RESULTS',
              style: TextStyle(fontFamily: 'PressStart2P', fontSize: 14)
            ),
          ),
        ],
      ),
    );
  }
}