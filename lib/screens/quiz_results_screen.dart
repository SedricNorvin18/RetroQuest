import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  // New field to receive detailed answers
  final List<Map<String, dynamic>> attemptDetails;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    // default to empty list if not provided to prevent errors
    this.attemptDetails = const [], 
  });

  @override
  Widget build(BuildContext context) {
    double percentage =
        totalQuestions > 0 ? (correctAnswers / totalQuestions) : 0;

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
                        const SizedBox(height: 30),
                        
                        // --- NEW REVIEW BUTTON ---
                        if (attemptDetails.isNotEmpty) ...[
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: const Icon(Icons.visibility),
      label: const Text('Review Answers'),
      onPressed: () => _showReviewModal(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'PressStart2P',
          fontSize: 12,
        ),
      ),
    ),
  ),
  const SizedBox(height: 20),
],
                        
                        // Existing Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'PressStart2P',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Play Again'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.popUntil(
                                  context, (route) => route.isFirst),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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

  // Helper method to show the detailed list in a modal
  void _showReviewModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2336),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Answer Review",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "PressStart2P",
                    fontSize: 18,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: attemptDetails.length,
                  itemBuilder: (context, index) {
                    final item = attemptDetails[index];
                    final bool isCorrect = item['isCorrect'];
                    final String question = item['question'];
                    final String userAnswer = item['userAnswer'] == "" ? "(No Answer)" : item['userAnswer'];
                    final String correctAnswer = item['correctAnswer'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect ? Colors.greenAccent : Colors.pinkAccent,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.greenAccent : Colors.pinkAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Question ${index + 1}",
                                  style: TextStyle(
                                    color: isCorrect ? Colors.greenAccent : Colors.pinkAccent,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "PressStart2P",
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14, fontFamily: 'Roboto'), // Use standard font for readability
                              children: [
                                const TextSpan(
                                  text: "Your Answer: ",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                TextSpan(
                                  text: userAnswer,
                                  style: TextStyle(
                                    color: isCorrect ? Colors.greenAccent : Colors.pinkAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isCorrect) ...[
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14, fontFamily: 'Roboto'),
                                children: [
                                  const TextSpan(
                                    text: "Correct Answer: ",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  TextSpan(
                                    text: correctAnswer,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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