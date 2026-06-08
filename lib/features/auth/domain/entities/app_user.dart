import 'package:equatable/equatable.dart';

/// The signed-in identity (auth's concern). The richer profile with aura lives
/// in [UserModel] and is surfaced via the repository for legacy screens.
class AppUser extends Equatable {
  final String id;
  final String displayName;
  final String email;
  final String? photoURL;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoURL,
  });

  @override
  List<Object?> get props => [id, displayName, email, photoURL];
}
