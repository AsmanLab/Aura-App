import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/services/push_service.dart';
import '../models/app_user_model.dart';

/// Raw auth IO: FirebaseAuth + Google Sign-In + the user's Firestore doc.
abstract class AuthRemoteDataSource {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Stream<UserModel?> currentUserProfile();

  /// One-shot read of the signed-in user's Firestore profile (`users/{uid}`).
  Future<UserModel?> getUser();

  Future<AppUserModel?> signInWithGoogle();
  Future<void> signOut();

  /// Force-refresh the ID token. If the refresh token is expired/revoked the
  /// refresh fails → sign out so the app routes to login.
  Future<void> ensureFreshToken();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<UserModel?> currentUserProfile() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null;
    });
  }

  @override
  Future<UserModel?> getUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null;
  }

  @override
  Future<AppUserModel?> signInWithGoogle() async {
    try {
      if (_auth.currentUser != null) {
        return AppUserModel.fromFirebaseUser(_auth.currentUser!);
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      await _createUserIfNotExists(user);
      return AppUserModel.fromFirebaseUser(user);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Existing Firestore user → just sign in (leave their data untouched).
  /// New user → register by creating the doc with defaults.
  Future<void> _createUserIfNotExists(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) return; // already registered — login only

    await docRef.set({
      'id': user.uid,
      'displayName': user.displayName ?? 'Anonymous',
      'email': user.email ?? '',
      'photoURL': user.photoURL,
      'currentWeekAura': 0,
      'totalAura': 0,
      'role': 'intern', // default; an admin promotes to mentor
      'position': '',
      'lastRouletteDate': null,
      'createdAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
      'metadata': <String, dynamic>{},
    });
  }

  @override
  Future<void> signOut() async {
    // Drop this device's FCM token first (needs the uid, gone after signOut).
    final uid = _auth.currentUser?.uid;
    if (uid != null) await sl<PushService>().removeToken(uid);
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> ensureFreshToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.getIdToken(true); // forces a refresh; throws if revoked/expired
    } catch (e) {
      debugPrint('Token refresh failed, signing out: $e');
      await signOut();
    }
  }
}
