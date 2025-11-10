
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retroquest/screens/auth_gate.dart';
import 'package:retroquest/screens/welcome_screen.dart';

class InitialGate extends StatefulWidget {
  const InitialGate({super.key});

  @override
  State<InitialGate> createState() => _InitialGateState();
}

class _InitialGateState extends State<InitialGate> {
  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // Returns true if it's the first launch, otherwise false.
    return prefs.getBool('isFirstLaunch') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFirstLaunch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while checking the preference.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data == true) {
          // If it is the first launch, show the WelcomeScreen.
          return const WelcomeScreen();
        } else {
          // Otherwise, proceed to the normal AuthGate.
          return const AuthGate();
        }
      },
    );
  }
}
