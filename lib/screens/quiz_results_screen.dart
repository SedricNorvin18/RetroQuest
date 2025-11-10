import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = totalQuestions > 0 ? (correctAnswers / totalQuestions) : 0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/retro_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withAlpha(153)),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double containerWidth = constraints.maxWidth * 0.8;
                if (constraints.maxWidth > 800) {
                  containerWidth = 600;
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    width: containerWidth,
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade900.withAlpha(217),
                          Colors.pink.shade700.withAlpha(217),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withAlpha(153),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Quiz Completed!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "PressStart2P",
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        CircularPercentIndicator(
                          radius: 120.0,
                          lineWidth: 15.0,
                          percent: percentage,
                          center: Text(
                            "${(percentage * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'PressStart2P',
                            ),
                          ),
                          progressColor: Colors.greenAccent,
                          backgroundColor: Colors.black54,
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Your Score: $score',
                          style: const TextStyle(
                            fontFamily: "PressStart2P",
                            fontSize: 22,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatCard(
                          icon: Icons.check_circle,
                          label: 'Correct',
                          value: correctAnswers.toString(),
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(height: 10),
                        _buildStatCard(
                          icon: Icons.cancel,
                          label: 'Incorrect',
                          value: incorrectAnswers.toString(),
                          color: Colors.pinkAccent,
                        ),
                        const SizedBox(height: 10),
                        _buildStatCard(
                          icon: Icons.format_list_numbered,
                          label: 'Total',
                          value: totalQuestions.toString(),
                          color: Colors.lightBlueAccent,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'PressStart2P',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Play Again'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'PressStart2P',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Exit'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 20),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
               fontFamily: 'PressStart2P',
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'PressStart2P',
            ),
          ),
        ],
      ),
    );
  }
}
