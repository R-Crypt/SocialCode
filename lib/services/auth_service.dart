import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of current user state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user details from Firestore
  Future<AppUser?> getCurrentUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!, doc.id);
  }

  // Sign In
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user record in Firestore
      final newUser = AppUser(
        id: cred.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
      );

      await _db.collection('users').doc(cred.user!.uid).set(newUser.toMap());
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
