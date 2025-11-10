import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retroquest/screens/auth_gate.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Future<void> _markFirstLaunchAsComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
  }

  void _navigateToAuthGate() {
    // Capture the navigator before the async gap.
    final navigator = Navigator.of(context);

    // Perform the async operation.
    _markFirstLaunchAsComplete().then((_) {
      // Check if the widget is still in the tree before navigating.
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/retro_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          ScreenTypeLayout.builder(
            mobile: (BuildContext context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Image.asset(
                      'assets/images/kirby-on-a-warp-star.gif',
                      height: 100,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to RetroQuest!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 24,
                        color: Colors.greenAccent,
                        shadows: [
                          const Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Start your learning adventure with a touch of nostalgia.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _navigateToAuthGate,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        backgroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: Colors.greenAccent, width: 2),
                        ),
                      ),
                      child: Text(
                        'Start Quest!',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            tablet: (BuildContext context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Image.asset(
                      'assets/images/kirby-on-a-warp-star.gif',
                      height: 150,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Welcome to RetroQuest!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 32,
                        color: Colors.greenAccent,
                        shadows: [
                          const Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Start your learning adventure with a touch of nostalgia.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    ElevatedButton(
                      onPressed: _navigateToAuthGate,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        backgroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: Colors.greenAccent, width: 2),
                        ),
                      ),
                      child: Text(
                        'Start your Quest!',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
