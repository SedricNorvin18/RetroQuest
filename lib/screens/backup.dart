// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import '../services/auth_service.dart';

// // class SignupScreen extends StatefulWidget {
// //   const SignupScreen({super.key});

// //   @override
// //   State<SignupScreen> createState() => _SignupScreenState();
// // }

// // class _SignupScreenState extends State<SignupScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _firstNameController = TextEditingController();
// //   final _lastNameController = TextEditingController();
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();
// //   final _confirmPasswordController = TextEditingController();
// //   String _role = "student";
// //   bool _isLoading = false;

// //   @override
// //   void dispose() {
// //     _firstNameController.dispose();
// //     _lastNameController.dispose();
// //     _emailController.dispose();
// //     _passwordController.dispose();
// //     _confirmPasswordController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _signup() async {
// //     if (!mounted || !_formKey.currentState!.validate()) return;

// //     if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Passwords do not match!")),
// //         );
// //       }
// //       return;
// //     }

// //     setState(() => _isLoading = true);

// //     try {
// //       final authService = Provider.of<AuthService>(context, listen: false);
// //       final fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
// //       await authService.signUp(
// //         _emailController.text.trim(),
// //         _passwordController.text.trim(),
// //         fullName,
// //         _role,
// //       );

// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Signup successful!")),
// //         );
// //         Navigator.pop(context);
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Signup failed: $e")),
// //         );
// //       }
// //     } finally {
// //       if (mounted) {
// //         setState(() => _isLoading = false);
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Stack(
// //         fit: StackFit.expand,
// //         children: [
// //           Image.asset(
// //             'assets/images/retro_bg.jpg',
// //             fit: BoxFit.cover,
// //           ),
// //           Container(color: Colors.black.withAlpha(153)),
// //           Center(
// //             child: LayoutBuilder(
// //               builder: (context, constraints) {
// //                 return ConstrainedBox(
// //                   constraints: const BoxConstraints(
// //                     maxWidth: 500,
// //                   ),
// //                   child: SingleChildScrollView(
// //                     padding: const EdgeInsets.all(24.0),
// //                     child: Container(
// //                       decoration: BoxDecoration(
// //                         color: Colors.black.withAlpha(178),
// //                         borderRadius: BorderRadius.circular(20),
// //                         border: Border.all(color: Colors.greenAccent, width: 1.5),
// //                         boxShadow: [
// //                           BoxShadow(
// //                             color: Colors.greenAccent.withAlpha(128),
// //                             blurRadius: 10,
// //                             spreadRadius: 3,
// //                           ),
// //                         ],
// //                       ),
// //                       child: Padding(
// //                         padding: const EdgeInsets.all(28.0),
// //                         child: Form(
// //                           key: _formKey,
// //                           child: Column(
// //                             mainAxisSize: MainAxisSize.min,
// //                             children: [
// //                               const Text(
// //                                 "Join RetroQuest",
// //                                 textAlign: TextAlign.center,
// //                                 style: TextStyle(
// //                                   fontSize: 26,
// //                                   fontWeight: FontWeight.bold,
// //                                   color: Colors.greenAccent,
// //                                   fontFamily: "PressStart2P",
// //                                   shadows: [
// //                                     Shadow(
// //                                       color: Colors.black,
// //                                       blurRadius: 4,
// //                                       offset: Offset(2, 2),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 30),
// //                               TextFormField(
// //                                 controller: _firstNameController,
// //                                 style: const TextStyle(color: Colors.white),
// //                                 decoration: InputDecoration(
// //                                   filled: true,
// //                                   fillColor: Colors.black54,
// //                                   labelText: "First Name",
// //                                   labelStyle: const TextStyle(color: Colors.white70),
// //                                   prefixIcon:
// //                                       const Icon(Icons.person, color: Colors.greenAccent),
// //                                   border: OutlineInputBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                 ),
// //                                 validator: (value) {
// //                                   if (value == null || value.isEmpty) {
// //                                     return 'Please enter your first name';
// //                                   }
// //                                   return null;
// //                                 },
// //                               ),
// //                               const SizedBox(height: 16),
// //                               TextFormField(
// //                                 controller: _lastNameController,
// //                                 style: const TextStyle(color: Colors.white),
// //                                 decoration: InputDecoration(
// //                                   filled: true,
// //                                   fillColor: Colors.black54,
// //                                   labelText: "Last Name",
// //                                   labelStyle: const TextStyle(color: Colors.white70),
// //                                   prefixIcon: const Icon(Icons.person_outline,
// //                                       color: Colors.pinkAccent),
// //                                   border: OutlineInputBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                 ),
// //                                 validator: (value) {
// //                                   if (value == null || value.isEmpty) {
// //                                     return 'Please enter your last name';
// //                                   }
// //                                   return null;
// //                                 },
// //                               ),
// //                               const SizedBox(height: 16),
// //                               TextFormField(
// //                                 controller: _emailController,
// //                                 style: const TextStyle(color: Colors.white),
// //                                 decoration: InputDecoration(
// //                                   filled: true,
// //                                   fillColor: Colors.black54,
// //                                   labelText: "Email",
// //                                   labelStyle: const TextStyle(color: Colors.white70),
// //                                   prefixIcon: const Icon(Icons.email,
// //                                       color: Colors.greenAccent),
// //                                   border: OutlineInputBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                 ),
// //                                 validator: (value) {
// //                                   if (value == null || value.isEmpty) {
// //                                     return 'Please enter your email';
// //                                   }
// //                                   if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
// //                                     return 'Please enter a valid email';
// //                                   }
// //                                   return null;
// //                                 },
// //                               ),
// //                               const SizedBox(height: 16),
// //                               TextFormField(
// //                                 controller: _passwordController,
// //                                 style: const TextStyle(color: Colors.white),
// //                                 obscureText: true,
// //                                 decoration: InputDecoration(
// //                                   filled: true,
// //                                   fillColor: Colors.black54,
// //                                   labelText: "Password",
// //                                   labelStyle: const TextStyle(color: Colors.white70),
// //                                   prefixIcon:
// //                                       const Icon(Icons.lock, color: Colors.pinkAccent),
// //                                   border: OutlineInputBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                 ),
// //                                 validator: (value) {
// //                                   if (value == null || value.isEmpty) {
// //                                     return 'Please enter your password';
// //                                   }
// //                                   return null;
// //                                 },
// //                               ),
// //                               const SizedBox(height: 16),
// //                               TextFormField(
// //                                 controller: _confirmPasswordController,
// //                                 style: const TextStyle(color: Colors.white),
// //                                 obscureText: true,
// //                                 decoration: InputDecoration(
// //                                   filled: true,
// //                                   fillColor: Colors.black54,
// //                                   labelText: "Confirm Password",
// //                                   labelStyle: const TextStyle(color: Colors.white70),
// //                                   prefixIcon:
// //                                       const Icon(Icons.lock, color: Colors.pinkAccent),
// //                                   border: OutlineInputBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                 ),
// //                                 validator: (value) {
// //                                   if (value == null || value.isEmpty) {
// //                                     return 'Please confirm your password';
// //                                   }
// //                                   return null;
// //                                 },
// //                               ),
// //                               const SizedBox(height: 16),
// //                               DropdownButtonFormField<String>(
// //                                 initialValue: _role,
// //                                 dropdownColor: Colors.black87,
// //                                 style: const TextStyle(color: Colors.white),
// //                                 decoration: InputDecoration(
// //                                   filled: true,
// //                                   fillColor: Colors.black54,
// //                                   labelText: "Select Role",
// //                                   labelStyle: const TextStyle(color: Colors.white70),
// //                                   border: OutlineInputBorder(
// //                                     borderRadius: BorderRadius.circular(12),
// //                                   ),
// //                                 ),
// //                                 items: const [
// //                                   DropdownMenuItem(
// //                                     value: "student",
// //                                     child: Text("Student"),
// //                                   ),
// //                                   DropdownMenuItem(
// //                                     value: "teacher",
// //                                     child: Text("Teacher"),
// //                                   ),
// //                                 ],
// //                                 onChanged: (value) {
// //                                   if (value != null) {
// //                                     setState(() => _role = value);
// //                                   }
// //                                 },
// //                               ),
// //                               const SizedBox(height: 24),
// //                               SizedBox(
// //                                 width: double.infinity,
// //                                 child: ElevatedButton(
// //                                   style: ElevatedButton.styleFrom(
// //                                     padding: const EdgeInsets.symmetric(vertical: 16),
// //                                     backgroundColor: Colors.greenAccent,
// //                                     foregroundColor: Colors.black,
// //                                     shape: RoundedRectangleBorder(
// //                                       borderRadius: BorderRadius.circular(12),
// //                                     ),
// //                                   ),
// //                                   onPressed: _isLoading ? null : _signup,
// //                                   child: _isLoading
// //                                       ? const CircularProgressIndicator(color: Colors.black)
// //                                       : const Text(
// //                                           "SIGN UP",
// //                                           style: TextStyle(
// //                                             fontSize: 16,
// //                                             fontWeight: FontWeight.bold,
// //                                             letterSpacing: 2,
// //                                           ),
// //                                         ),
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 16),
// //                               SizedBox(
// //                                 width: double.infinity,
// //                                 child: OutlinedButton.icon(
// //                                   style: OutlinedButton.styleFrom(
// //                                     padding: const EdgeInsets.symmetric(vertical: 14),
// //                                     side: const BorderSide(
// //                                         color: Colors.greenAccent, width: 2),
// //                                     shape: RoundedRectangleBorder(
// //                                       borderRadius: BorderRadius.circular(12),
// //                                     ),
// //                                   ),
// //                                   onPressed: () => Navigator.pop(context),
// //                                   icon: const Icon(Icons.arrow_back,
// //                                       color: Colors.greenAccent),
// //                                   label: const Text(
// //                                     "BACK",
// //                                     style: TextStyle(
// //                                       color: Colors.greenAccent,
// //                                       fontSize: 14,
// //                                       fontFamily: "PressStart2P",
// //                                       letterSpacing: 2,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }



// // auth gate
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:retroquest/screens/login_screen.dart';
// import 'package:retroquest/screens/student_dashboard_screen.dart';
// import 'package:retroquest/screens/teacher_dashboard_screen.dart';

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, authSnapshot) {
//         if (!authSnapshot.hasData) {
//           return const LoginScreen();
//         }
//         return _RoleGate(user: authSnapshot.data!);
//       },
//     );
//   }
// }

// class _RoleGate extends StatelessWidget {
//   const _RoleGate({required this.user});
//   final User user;

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<DocumentSnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .snapshots(),
//       builder: (context, userDocSnapshot) {
//         if (userDocSnapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//               body: Center(child: CircularProgressIndicator()));
//         }

//         if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
//           final userData =
//               userDocSnapshot.data!.data() as Map<String, dynamic>?;
//           final userRole = userData?['role'];
//           if (userRole != null) {
//             return userRole == 'teacher'
//                 ? const TeacherDashboardScreen()
//                 : const StudentDashboardScreen();
//           }
//         }

//         // If doc doesn't exist or has no role, show the dedicated role selection screen
//         return RoleSelectionScreen(user: user);
//       },
//     );
//   }
// }

// class RoleSelectionScreen extends StatefulWidget {
//   const RoleSelectionScreen({required this.user, super.key});
//   final User user;

//   @override
//   State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
// }

// class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
//   bool _isSaving = false;

//   Future<void> _selectRole(String role) async {
//     if (_isSaving) return;
//     setState(() {
//       _isSaving = true;
//     });

//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.user.uid)
//           .set({'role': role}, SetOptions(merge: true));
//       // No navigation needed. AuthGate's stream will handle it.
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error saving role: ${e.toString()}")),
//         );
//         setState(() {
//           _isSaving = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Image.asset(
//             'assets/images/retro_bg.jpg',
//             fit: BoxFit.cover,
//           ),
//           Container(
//             color: const Color(0xFF000000).withValues(alpha: 0.6),
//           ),
//           Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 400),
//               child: Container(
//                 padding: const EdgeInsets.all(32.0),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.deepPurple.shade900.withAlpha(220),
//                       Colors.pink.shade700.withAlpha(220),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.purpleAccent.withAlpha(150),
//                       blurRadius: 15,
//                       spreadRadius: 5,
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       'Select Your Role',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         fontFamily: "PressStart2P",
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 24),
//                     if (_isSaving)
//                       const CircularProgressIndicator(color: Colors.white)
//                     else
//                       Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               backgroundColor: Colors.greenAccent,
//                               foregroundColor: Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             onPressed: () => _selectRole('student'),
//                             child: const Text(
//                               'Student',
//                               style: TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               backgroundColor: Colors.blueAccent,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             onPressed: () => _selectRole('teacher'),
//                             child: const Text(
//                               'Teacher',
//                               style: TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
