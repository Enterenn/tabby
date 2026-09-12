part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  AuthAuthenticated(this.user);
  final User user;
}

class AuthUnauthenticated extends AuthState {}

/// JWT présent, en attente du prompt empreinte / Face ID.
class AuthBiometricRequired extends AuthState {}

class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}
