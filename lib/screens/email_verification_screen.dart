import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:retroquest/services/email_verification_service.dart';
import 'package:retroquest/screens/initial_gate.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final EmailVerificationService _emailVerificationService =
      EmailVerificationService();
  Timer? _timer;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      _emailVerificationService.sendVerificationEmail();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _checkEmailVerification();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkEmailVerification() async {
    bool isVerified = await _emailVerificationService.isEmailVerified();

    if (mounted && isVerified) {
      _timer?.cancel();
      setState(() {
        _isSuccess = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const InitialGate()),
        );
      }
    }
  }

  Widget _buildVerificationBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.email_outlined, size: 80, color: Colors.greenAccent),
        const SizedBox(height: 20),
        const Text(
          'Verify Your Email',
          style: TextStyle(
            fontFamily: "PressStart2P",
            fontSize: 22,
            color: Colors.greenAccent,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'A verification email has been sent to ${FirebaseAuth.instance.currentUser?.email}. Please check your inbox.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 30),
        const CircularProgressIndicator(color: Colors.pinkAccent),
        const SizedBox(height: 20),
        const Text(
          'Waiting for verification...',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
              fontFamily: "PressStart2P",
              letterSpacing: 1.5),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.send),
            label: const Text('RESEND EMAIL',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            onPressed: () {
              _emailVerificationService.sendVerificationEmail();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A new verification email has been sent.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.black87,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBody() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
        SizedBox(height: 20),
        Text(
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
        SizedBox(height: 20),
        Text(
          'Redirecting to your dashboard...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
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
                  child: _isSuccess
                      ? _buildSuccessBody()
                      : _buildVerificationBody(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
