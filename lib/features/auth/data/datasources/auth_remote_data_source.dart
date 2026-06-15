import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

      // Prefer a silent sign-in (no Safari/ASWebAuthenticationSession) when a
      // Google session is already cached — avoids the simulator's web-auth bug.
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      googleUser ??= await _signInInteractive();
      if (googleUser == null) return null; // cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      await _createUserIfNotExists(user);
      // Connect this device to push immediately (also covered by the auth
      // listener in PushService, but do it here so it's tied to sign-in).
      await sl<PushService>().syncToken(user.uid);
      return AppUserModel.fromFirebaseUser(user);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Interactive (web) sign-in with one retry on the iOS Simulator's transient
  /// "network connection was lost" (NSURLErrorNetworkConnectionLost, -1005)
  /// from ASWebAuthenticationSession.
  Future<GoogleSignInAccount?> _signInInteractive() async {
    try {
      return await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      final s = '${e.code} ${e.message}'.toLowerCase();
      final transient = s.contains('network') ||
          s.contains('connection') ||
          s.contains('-1005');
      if (!transient) rethrow;
      // Clear the half-open session and retry once.
      await _googleSignIn.signOut();
      return await _googleSignIn.signIn();
    }
  }

  /// Refresh the Firebase session without any UI using the cached Google
  /// account. Returns true if re-authenticated.
  Future<bool> _silentReauth() async {
    try {
      final acct = await _googleSignIn.signInSilently();
      if (acct == null) return false;
      final auth = await acct.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await _auth.signInWithCredential(cred);
      return true;
    } catch (_) {
      return false;
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
      'hearts': 8,
      'fcmTokens': <String>[], // device tokens added on sign-in
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

    // disconnect() fully revokes the cached Google account so the next sign-in
    // shows the account chooser (clean switch). Falls back to signOut().
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();

    // Clear Firestore's offline cache so a different account can't see the
    // previous user's cached docs. Best-effort: throws if listeners are still
    // active, in which case the uid-scoped queries already isolate data.
    try {
      await _firestore.clearPersistence();
    } catch (_) {}
  }

  @override
  Future<void> ensureFreshToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.getIdToken(true); // forces a refresh
    } on FirebaseAuthException catch (e) {
      // Offline → keep the session, just retry next launch. Don't log out.
      if (e.code == 'network-request-failed') return;
      // Credential expired/revoked → recover silently (no Safari) if possible.
      if (await _silentReauth()) return;
      // Couldn't recover → light sign-out (no Google disconnect, so the next
      // login can reuse the cached session instead of the flaky web flow).
      debugPrint('Token refresh failed, signing out: ${e.code}');
      await _auth.signOut();
    } catch (e) {
      // Unknown error (often a transient network blip) — keep the session.
      debugPrint('Token refresh error (keeping session): $e');
    }
  }
}
