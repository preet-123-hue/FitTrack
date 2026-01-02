import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class GoogleAuthService {
  final _auth = FirebaseAuth.instance;

  /// Initialize GoogleSignIn only for Android (not web)
  late final GoogleSignIn _googleSignIn = _initializeGoogleSignIn();

  GoogleSignIn _initializeGoogleSignIn() {
    // Only initialize GoogleSignIn on Android
    // Web platform doesn't have a client ID configured
    if (kIsWeb) {
      if (kDebugMode) {
        print('Google Sign-In not available on web platform');
      }
      return GoogleSignIn(); // Return dummy instance for web
    }

    if (Platform.isAndroid) {
      return GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }

    return GoogleSignIn();
  }

  /// Sign in with Google account
  /// Returns User object if successful, null if cancelled
  /// Throws exceptions on actual errors
  /// Not supported on web platform
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        throw UnsupportedError(
            'Google Sign-In is not supported on web platform. Use Firebase email/password auth instead.');
      }

      if (!Platform.isAndroid) {
        throw UnsupportedError('Google Sign-In is only supported on Android.');
      }

      if (kDebugMode) {
        print('Starting Google sign-in...');
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) {
          print('Google sign-in cancelled by user');
        }
        return null;
      }

      if (kDebugMode) {
        print('Google user obtained: ${googleUser.email}');
      }

      final googleAuth = await googleUser.authentication;
      if (kDebugMode) {
        print('Google authentication obtained');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print('Firebase credential created');
      }

      final userCredential = await _auth.signInWithCredential(credential);
      if (kDebugMode) {
        print('Signed in as: ${userCredential.user?.email}');
      }

      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print('Google sign-in error: $e');
      }
      rethrow;
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      if (kDebugMode) {
        print('Signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      rethrow;
    }
  }

  /// Get current signed-in user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
