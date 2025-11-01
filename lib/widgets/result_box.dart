import 'package:flutter/material.dart';
import 'dart:math';

class ResultBox extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final VoidCallback onRestart;

  const ResultBox({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.onRestart,
  });

  @override
  State<ResultBox> createState() => _ResultBoxState();
}

class _ResultBoxState extends State<ResultBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _medalBounce;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _medalBounce = Tween<double>(begin: 0, end: -12)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> getMedal() {
    double percent = widget.score / widget.totalQuestions;
    if (percent == 1) return {"emoji": "🥇", "color": Colors.amberAccent};
    if (percent >= 0.7) return {"emoji": "🥈", "color": Colors.blueGrey};
    if (percent >= 0.4) return {"emoji": "🥉", "color": Colors.deepOrange};
    return {"emoji": "👾", "color": Colors.purpleAccent};
  }

  List<Widget> _buildParticles(int count, Size size) {
    return List.generate(count, (index) {
      final top = _random.nextDouble() * size.height;
      final left = _random.nextDouble() * size.width;
      final color = Colors.primaries[_random.nextInt(Colors.primaries.length)];
      final sizeParticle = 2.0 + _random.nextDouble() * 3;
      return Positioned(
        top: top,
        left: left,
        child: Container(
          width: sizeParticle,
          height: sizeParticle,
          decoration: BoxDecoration(
            color: color.withAlpha(38),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(26),
                blurRadius: 2,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final medalData = getMedal();
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          ..._buildParticles(25, size), // subtle background glow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0f0c29),
                  Color(0xFF302b63),
                  Color(0xFF24243e),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(153),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "✨ RetroQuest Complete! ✨",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent.shade100,
                    shadows: [
                      Shadow(
                        color: Colors.cyanAccent.withAlpha(128),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Medal bounce animation
                AnimatedBuilder(
                  animation: _medalBounce,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _medalBounce.value),
                    child: child,
                  ),
                  child: Text(
                    medalData["emoji"],
                    style: TextStyle(
                      fontSize: 80,
                      color: medalData["color"],
                      shadows: [
                        Shadow(
                          color: medalData["color"].withAlpha(102),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.black.withAlpha(77),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: medalData["color"].withAlpha(77),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    "${widget.score} / ${widget.totalQuestions}",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: medalData["color"],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _retroButton("Restart", Icons.refresh, Colors.cyanAccent,
                        widget.onRestart),
                    _retroButton("Close", Icons.close, Colors.pinkAccent,
                        () => Navigator.pop(context)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _retroButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withAlpha(179),
              color.withAlpha(230),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(102),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
