import 'package:aura_app/core/models/user_model.dart';
import '../entities/app_user.dart';

/// Auth session contract. Implemented over FirebaseAuth + Google Sign-In.
///
/// NOTE: [currentUserProfile] returns the shared [UserModel] (which carries
/// `Timestamp`) so the legacy Firebase screens keep working. That profile read
/// really belongs to a future `profile` feature — kept here for now.
abstract class AuthRepository {
  /// Emits true when a user is signed in.
  Stream<bool> authStateChanges();

  /// The signed-in user's full Firestore profile (null when signed out).
  Stream<UserModel?> currentUserProfile();

  AppUser? get currentUser;

  Future<AppUser?> signInWithGoogle();

  Future<void> signOut();
}
