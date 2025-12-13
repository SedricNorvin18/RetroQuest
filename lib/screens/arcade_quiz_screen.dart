import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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

class _ArcadeQuizScreenState extends State<ArcadeQuizScreen>
    with TickerProviderStateMixin {
  Timer? _fireTimer;
  Timer? _movementTimer;
  double _currentMovementDelta = 0.0; // The direction/magnitude of movement

// --- CONSTANTS ---
  static const double kShipWidth = 125.0; // The visual width of the ship
  static const double kShipHeight = 125.0; // The visual height of the ship

// For movement, use a small, fast step
  final double _movementStep = 0.02;
  final DbConnect _db = DbConnect();
  List<Question> _questions = [];
  int _currentIndex = 0;

  // --- GAME STATE ---
  int _score = 0;
  int _lives = 3;
  double _gameSpeed = 0.005; // Default
  Timer? _gameTimer;
  Timer? _spawnTimer;
  bool _isGameOver = false;

  // --- PLAYER & PROJECTILE STATE ---
  double _shipPositionX = 0.5;
  final double _shipPositionY = 0.1;
  double _projectilePositionY = 0.0;
  double _projectilePositionX = 0.5;
  bool _isShooting = false;

  // --- QUIZ DATA ---
  List<_Target> _targets = [];
  List<String> _pendingOptions = [];
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  String? _userRole;
  final List<Map<String, dynamic>> _userAnswers = [];

  // --- AUDIO PLAYERS ---
  late AudioPlayer _backgroundMusicPlayer;
  late AudioPlayer _sfxPlayer;

  // --- ANIMATION CONTROLLER FOR BACKGROUND ---
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();

    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.multiRoute,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );

    _initializeAudioPlayers();
    _setDifficulty();
    _loadQuestions();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _backgroundAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_backgroundController);
  }

  Future<void> _fetchUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (mounted) {
        setState(() {
          _userRole = userDoc.data()?['role'];
        });
      }
    }
  }

  // Made async so we can set player modes and start music safely.
  Future<void> _initializeAudioPlayers() async {
    _backgroundMusicPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();

    // No need to set a PlayerMode for BGM — ReleaseMode.loop is sufficient.
// Keep the SFX player low-latency for snappy sound effects.
    try {
      await _sfxPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    } catch (_) {}

    // Start background music (non-blocking)
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      // Use AssetSource to play packaged asset
      await _backgroundMusicPlayer.play(AssetSource('audio/arcade_music.mp3'));
    } catch (e) {
      // Fail silently so missing asset won't crash the game
      // You can log or show debug message in development
      // debugPrint('BGM play error: $e');
    }
  }

  Future<void> _playSfx(String asset) async {
    try {
      // Use lowLatency mode for snappy SFX playback; this won't interrupt the BGM player.
      await _sfxPlayer.play(AssetSource('audio/$asset'),
          mode: PlayerMode.mediaPlayer);
    } catch (e) {
      // debugPrint('SFX play error: $e');
    }
  }

  void _setDifficulty() {
    switch (widget.difficulty) {
      case 'Easy':
        _gameSpeed = 0.003;
        break;
      case 'Hard':
        _gameSpeed = 0.009;
        break;
      case 'Normal':
      default:
        _gameSpeed = 0.006;
        break;
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();

    // stop then dispose players to be safe
    try {
      _backgroundMusicPlayer.stop();
    } catch (_) {}
    try {
      _sfxPlayer.stop();
    } catch (_) {}

    _backgroundMusicPlayer.dispose();
    _sfxPlayer.dispose();

    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final allQuestions = await _db.fetchQuestions(subject: widget.subject);

    final arcadeQuestions =
        allQuestions.where((q) => q.options.isNotEmpty).toList();

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
                color: Colors.white, fontFamily: "PressStart2P", fontSize: 14)),
        content: const Text(
          "This quiz contains only text-based questions which cannot be played in Arcade Mode.\n\nPlease play Classic Mode instead.",
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

  void _startTargetSpawner() {
    _spawnTimer?.cancel();
    final spawnDuration = widget.difficulty == 'Easy'
        ? 2500
        : widget.difficulty == 'Normal'
            ? 1800
            : 1200;

    _spawnTimer =
        Timer.periodic(Duration(milliseconds: spawnDuration), (timer) {
      if (_isGameOver || !mounted) {
        timer.cancel();
        return;
      }

      if (_pendingOptions.isNotEmpty && _targets.length < 4) {
        setState(() {
          final randomIndex = Random().nextInt(_pendingOptions.length);
          final optionToDrop = _pendingOptions.removeAt(randomIndex);
          final isCorrect =
              optionToDrop == _questions[_currentIndex].correctAnswer;

          final randomX = Random().nextDouble().clamp(0.1, 0.9);

          _targets.add(_Target(
            text: optionToDrop,
            isCorrect: isCorrect,
            positionX: randomX,
            positionY: 1.05,
          ));
        });
      } else if (_pendingOptions.isEmpty && _targets.isEmpty) {
        timer.cancel();
      }
    });
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isGameOver || !mounted) {
        timer.cancel();
        if (_isGameOver) _submitQuiz();
        return;
      }

      setState(() {
        final targetsToRemove = <_Target>[];
        for (var target in _targets) {
          target.positionY -= _gameSpeed;

          if (target.positionY < _shipPositionY - 0.05) {
            targetsToRemove.add(target);
            continue;
          }
        }

        for (var escapedTarget in targetsToRemove) {
          _handleTargetEscape(escapedTarget);
        }

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
      _spawnTimer?.cancel();
      _playSfx('game_over.wav');
      return;
    }

    final currentQuestion = _questions[_currentIndex];
    final options = [...currentQuestion.options];
    options.shuffle(Random());

    _pendingOptions = options;
    _targets = [];

    _isShooting = false;
    _projectilePositionY = _shipPositionY + 0.01;
    _projectilePositionX = _shipPositionX;

    _startTargetSpawner();

    if (_gameSpeed < 0.02) {
      _gameSpeed *= 1.02;
    }
  }

  void _handleTargetEscape(_Target escapedTarget) {
    if (!_isGameOver) {
      setState(() {
        _targets.remove(escapedTarget);

        if (escapedTarget.isCorrect) {
          _lives--;
          _incorrectAnswers++;
          _playSfx('explosion_lives.wav');
          _userAnswers.add({
            'question': _questions[_currentIndex].text,
            'correctAnswer': _questions[_currentIndex].correctAnswer,
            'userAnswer': '(Missed Correct Answer)',
            'isCorrect': false,
          });

          if (_lives <= 0) {
            _isGameOver = true;
            _gameTimer?.cancel();
            _spawnTimer?.cancel();
            _playSfx('game_over.wav');
            _submitQuiz();
          } else {
            _gameTimer?.cancel();
            _spawnTimer?.cancel();
            Timer(const Duration(milliseconds: 800), () {
              _currentIndex++;
              _setupNextQuestion();
              _startGameLoop();
            });
          }
        }
      });
    }
  }

  void _checkCollision() {
    if (!_isShooting) return;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // TARGET DIMENSIONS
    const double targetPixelWidth = 150.0;
    const double targetPixelHeight = 50.0;

    // Normalize target dimensions
    final double targetNormalizedW = targetPixelWidth / screenWidth;
    final double targetNormalizedH = targetPixelHeight / screenHeight;

    // PROJECTILE DIMENSIONS
    // The projectile is effectively a point in the center of the ship.
    // We don't need the full ship width for the hitbox, just the laser point.
    // However, we must ensure the _projectilePositionX variable represents
    // the exact CENTER of the ship.

    // "Forgiveness" area (optional, makes game feel better)
    const double forgivenessPixels = 40.0;
    final double forgivenessNormalized = forgivenessPixels / screenHeight;

    for (int i = 0; i < _targets.length; i++) {
      final target = _targets[i];

      // Calculate Boundaries
      final double targetLeftX = target.positionX - (targetNormalizedW / 2);
      final double targetRightX = target.positionX + (targetNormalizedW / 2);
      final double targetTopY = target.positionY + (targetNormalizedH / 2);
      final double targetBottomY =
          target.positionY - (targetNormalizedH / 2) - forgivenessNormalized;

      // Check Collision
      // We check if the projectile's center (X, Y) is inside the target box
      if (_projectilePositionY < targetTopY &&
          _projectilePositionY > targetBottomY &&
          _projectilePositionX < targetRightX &&
          _projectilePositionX > targetLeftX) {
        _isShooting = false;

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
    _playSfx('explosion_correct.wav');

    _userAnswers.add({
      'question': _questions[_currentIndex].text,
      'correctAnswer': _questions[_currentIndex].correctAnswer,
      'userAnswer': selectedAnswer,
      'isCorrect': true,
    });

    _gameTimer?.cancel();
    _spawnTimer?.cancel();

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
    _playSfx('explosion_lives.wav');

    _userAnswers.add({
      'question': _questions[_currentIndex].text,
      'correctAnswer': _questions[_currentIndex].correctAnswer,
      'userAnswer': selectedAnswer,
      'isCorrect': false,
    });

    if (_lives <= 0) {
      _isGameOver = true;
      _gameTimer?.cancel();
      _spawnTimer?.cancel();
      _playSfx('game_over.wav');
      _submitQuiz();
    } else {
      _gameTimer?.cancel();
      _spawnTimer?.cancel();

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
      _shipPositionX = (_shipPositionX + deltaX).clamp(0.05, 0.95);
      if (!_isShooting) {
        _projectilePositionX = _shipPositionX;
      }
    });
  }

  void _startMoving(double deltaX) {
    _currentMovementDelta = deltaX;

    // Prevent starting a new timer if one is already running
    if (_movementTimer != null && _movementTimer!.isActive) return;

    _movementTimer = Timer.periodic(
      const Duration(milliseconds: 50), // Adjust this duration for speed
      (timer) {
        if (_currentMovementDelta != 0.0) {
          _moveShip(_currentMovementDelta);
        }
      },
    );
  }

  void _stopMoving() {
    _currentMovementDelta = 0.0;
    _movementTimer?.cancel();
  }

  void _fireProjectile() {
    if (_isShooting || _isGameOver) return;
    setState(() {
      _isShooting = true;
      _projectilePositionX = _shipPositionX;
      _projectilePositionY = _shipPositionY + 0.01;
    });
    _playSfx('laser_shot.wav');
  }

  void _startRapidFire() {
    // Check if a rapid fire timer is already active to prevent duplicates
    if (_fireTimer != null && _fireTimer!.isActive) return;

    // Set the fire rate: e.g., fire every 150 milliseconds
    const Duration fireRate = Duration(milliseconds: 150);

    _fireTimer = Timer.periodic(
      fireRate,
      (timer) {
        // Call the existing fire logic
        _fireProjectile();
      },
    );
  }

  void _stopRapidFire() {
    _fireTimer?.cancel();
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
          userRole: _userRole,
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
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: MediaQuery.of(context).size.height *
                        (_backgroundAnimation.value - 1),
                    child: Image.asset('assets/images/galaxy.jpg',
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height *
                        _backgroundAnimation.value,
                    child: Image.asset('assets/images/galaxy.jpg',
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height),
                  ),
                ],
              );
            },
          ),

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
                // FIX: Wrapper SizedBox ensures alignment matches the ship's center
                child: SizedBox(
                  width: kShipWidth,
                  height: 15,
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        boxShadow: [
                          BoxShadow(color: Colors.red, blurRadius: 8)
                        ],
                      ),
                    ),
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
                'assets/images/ship.gif',
                width: kShipWidth, // Use constant
                height: kShipHeight, // Use constant
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
      width: 150,
      height: 50,
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
        overflow: TextOverflow.visible,
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
          onTap: () => _moveShip(-_movementStep), // Single tap move
          onLongPressStart: (_) => _startMoving(
              -_movementStep), // Hold to start continuous movement left
          onLongPressEnd: (_) => _stopMoving(), // Release to stop
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
          // Use onLongPressStart to begin rapid fire as soon as the button is pressed
          onLongPressStart: (_) => _startRapidFire(),

          // Use onLongPressEnd to stop rapid fire when the button is released
          onLongPressEnd: (_) => _stopRapidFire(),

          // You can keep onTap to allow for a single quick shot if they just tap and release
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
          onTap: () => _moveShip(_movementStep), // Single tap move
          onLongPressStart: (_) => _startMoving(
              _movementStep), // Hold to start continuous movement right
          onLongPressEnd: (_) => _stopMoving(), // Release to stop
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
