import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:retroquest/screens/email_verified_screen.dart';
import 'package:retroquest/screens/login_screen.dart';
import 'package:retroquest/screens/reset_password_screen.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/initial_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based routing for web
  usePathUrlStrategy();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Route<dynamic>? _handleRoute(RouteSettings settings) {
    if (settings.name == null) return null;

    final uri = Uri.parse(settings.name!);
    final mode = uri.queryParameters['mode'];
    final oobCode = uri.queryParameters['oobCode'];

    if (oobCode == null) return null;

    if (mode == 'resetPassword') {
      return MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(oobCode: oobCode),
        settings: settings,
      );
    }

    if (mode == 'verifyEmail') {
      return MaterialPageRoute(
        builder: (context) => EmailVerifiedScreen(oobCode: oobCode),
        settings: settings,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "RetroQuiz",
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            textTheme: GoogleFonts.pixelifySansTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
          onGenerateInitialRoutes: (initialRoute) {
            final route = _handleRoute(RouteSettings(name: initialRoute));
            if (route != null) {
              return [route];
            }
            return [
              MaterialPageRoute(builder: (context) => const InitialGate()),
            ];
          },
          onGenerateRoute: (settings) {
            final route = _handleRoute(settings);
            if (route != null) {
              return route;
            }
            return MaterialPageRoute(builder: (context) => const InitialGate());
          }),
    );
  }
}
