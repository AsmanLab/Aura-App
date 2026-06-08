import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;
  final bool submitting;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.submitting = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? submitting,
    String? error,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    submitting: submitting ?? this.submitting,
    error: error,
  );

  @override
  List<Object?> get props => [status, user, submitting, error];
}
