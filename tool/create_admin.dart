import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  const email = 'admin@gorillagym.com';
  const password = 'admin123';
  try {
    await auth.signInWithEmailAndPassword(email: email, password: password);
    print('signed in uid=${auth.currentUser!.uid}');
  } catch (e) {
    print('signIn failed: $e');
    return;
  }
  final uid = auth.currentUser!.uid;
  final data = {
    'name': 'Admin',
    'email': email,
    'role': 'admin',
    'isActive': true,
    'createdAt': Timestamp.now(),
  };
  try {
    await db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    print('Firestore doc created at users/$uid with role admin');
    final snap = await db.collection('users').doc(uid).get();
    print('doc data: ${snap.data()}');
  } catch (e) {
    print('firestore set failed: $e');
  }
  await auth.signOut();
  print('done');
}
