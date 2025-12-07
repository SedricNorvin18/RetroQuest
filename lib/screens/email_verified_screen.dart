import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retroquest/screens/login_screen.dart';
import 'package:retroquest/services/web_helpers.dart' if (dart.library.html) 'package:retroquest/services/web_helpers_web.dart';

class EmailVerifiedScreen extends StatefulWidget {
  final String oobCode;

  const EmailVerifiedScreen({super.key, required this.oobCode});

  @override
  State<EmailVerifiedScreen> createState() => _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends State<EmailVerifiedScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _applyActionCode();
  }

  Future<void> _applyActionCode() async {
    try {
      await FirebaseAuth.instance.applyActionCode(widget.oobCode);
      setState(() {
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'An unknown error occurred.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/retro_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withValues(alpha: 0.7)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(178),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withAlpha(128),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? _buildLoading()
                      : _errorMessage.isNotEmpty
                          ? _buildError()
                          : _buildSuccess(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: Colors.pinkAccent),
        SizedBox(height: 20),
        Text(
          'Verifying your email...',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontFamily: "PressStart2P",
              letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
        const SizedBox(height: 20),
        const Text(
          'Error',
          style: TextStyle(
            fontFamily: "PressStart2P",
            fontSize: 22,
            color: Colors.redAccent,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: const Text('GO TO LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
        const SizedBox(height: 20),
        const Text(
          'Email Verified!',
          style: TextStyle(
            fontFamily: "PressStart2P",
            fontSize: 24,
            color: Colors.greenAccent,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Image.asset('assets/images/kirby-on-a-warp-star.gif', height: 100),
        const SizedBox(height: 20),
        const Text(
          'You can now sign in with your new account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
           style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (kIsWeb) {
              closeWindow();
            }
          },
          child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
