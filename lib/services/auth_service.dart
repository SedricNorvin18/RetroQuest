import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _saveGoogleUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.email != null) {
      await prefs.setString('last_google_user_email', user.email!);
    }
    if (user.displayName != null) {
      await prefs.setString('last_google_user_name', user.displayName!);
    }
    if (user.photoURL != null) {
      await prefs.setString('last_google_user_photo_url', user.photoURL!);
    }
  }

  Future<Map<String, String>?> getGoogleUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('last_google_user_email');
    final name = prefs.getString('last_google_user_name');
    final photoUrl = prefs.getString('last_google_user_photo_url');

    if (email != null && name != null) {
      return {
        'email': email,
        'name': name,
        'photoUrl': photoUrl ?? '',
      };
    }
    return null;
  }

  Future<void> clearGoogleUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_google_user_email');
    await prefs.remove('last_google_user_name');
    await prefs.remove('last_google_user_photo_url');
  }

  Future<UserCredential> signUp(
      String email, String password, String name, String role) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload(); // Reload user to get the updated details

      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': name,
        'first': firstName,
        'last': lastName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<User?> signInWithGoogle({bool forceSelectAccount = false}) async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      if (forceSelectAccount) {
        googleProvider.setCustomParameters({'prompt': 'select_account'});
      }

      final UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);
      final user = userCredential.user;

      if (user != null) {
        await _saveGoogleUser(user);

        final userDocRef = _firestore.collection('users').doc(user.uid);
        final doc = await userDocRef.get();

        final name = user.displayName ?? '';
        final nameParts = name.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        if (!doc.exists) {
          await userDocRef.set({
            'uid': user.uid,
            'email': user.email,
            'displayName': name,
            'first': firstName,
            'last': lastName,
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          await userDocRef.update({
            'displayName': name,
            'first': firstName,
            'last': lastName,
            'photoURL': user.photoURL,
          });
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
            'An account already exists with this email. Please sign in with your original method.');
      } else if (e.code == 'popup-closed-by-user') {
        return null; 
      }
      throw Exception(
          'A Firebase authentication error occurred. Please try again.');
    } catch (e) {
      throw Exception(
          'An unexpected error occurred during Google Sign-In. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
}
