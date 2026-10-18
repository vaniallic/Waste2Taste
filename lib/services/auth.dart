import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Real accounts with Firebase Authentication (email + password, Google).
/// If Firebase isn't set up yet, [ready] stays false and the app falls back
/// to the simple local login, so nothing breaks.
class Auth {
  static bool ready = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      ready = true;
    } catch (e) {
      debugPrint('Firebase is off: $e');
    }
  }

  static User? get user => ready ? FirebaseAuth.instance.currentUser : null;

  /// Fires once with the current user (or null) and again on every login / logout.
  static Stream<User?> get changes => ready ? FirebaseAuth.instance.authStateChanges() : const Stream<User?>.empty();

  static Future<void> signIn(String email, String password) =>
      FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

  static Future<void> signUp(String email, String password) =>
      FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

  static Future<void> google() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      await FirebaseAuth.instance.signInWithProvider(provider);
    }
  }

  static Future<void> resetPassword(String email) => FirebaseAuth.instance.sendPasswordResetEmail(email: email);

  static Future<void> signOut() async {
    if (ready) await FirebaseAuth.instance.signOut();
  }

  /// A readable message for an error, or null when it isn't worth showing
  /// (for example the user just closed the Google window).
  static String? message(Object e) {
    if (e is! FirebaseAuthException) return 'Something went wrong. Please try again.';
    switch (e.code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'That email already has an account. Try logging in.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many tries. Wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method isn\'t turned on in Firebase yet.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
        return null;
      default:
        return 'Couldn\'t sign in (${e.code}).';
    }
  }
}
