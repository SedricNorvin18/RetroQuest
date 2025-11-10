import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:retroquest/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final usersCollection = firestore.collection('users');

  final usersSnapshot = await usersCollection.get();

  for (final userDoc in usersSnapshot.docs) {
    final userData = userDoc.data();
    if (userData.containsKey('displayName') && !userData.containsKey('name')) {
      final displayName = userData['displayName'];
      await userDoc.reference.update({'name': displayName});
    }
  }
}
