import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:social_code/models/app_user.dart';
import 'package:social_code/services/auth_service.dart';

// ============================================================
// EVENTS
// ============================================================
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  SignUpRequested(this.email, this.password, this.displayName);
  @override
  List<Object?> get props => [email, password, displayName];
}

class GoogleSignInRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class AuthUserUpdated extends AuthEvent {
  final AppUser? user;
  AuthUserUpdated(this.user);
  @override
  List<Object?> get props => [user];
}

// ============================================================
// STATES
// ============================================================
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// ============================================================
// BLOC
// ============================================================
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<LogoutRequested>(_onLogout);
    on<AuthUserUpdated>(_onAuthUserUpdated);

    // Listen to Supabase auth state changes (handles OAuth redirects AND
    // session recovery on page reload)
    _authService.authStateChanges.listen((event) {
      if (event.event == sb.AuthChangeEvent.signedIn ||
          event.event == sb.AuthChangeEvent.tokenRefreshed ||
          event.event == sb.AuthChangeEvent.userUpdated) {
        _authService.getCurrentUserData().then((user) {
          add(AuthUserUpdated(user));
        });
      } else if (event.event == sb.AuthChangeEvent.signedOut) {
        add(AuthUserUpdated(null));
      }
    });
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signIn(event.email, event.password);
      // After sign-in, the auth stream listener above will fire AuthUserUpdated.
      // But also fetch directly here in case the stream is slow.
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthFailure('Profile not found. Please try signing up first.'));
      }
    } on sb.AuthException catch (e) {
      // Surface Supabase-specific errors clearly
      if (e.message.toLowerCase().contains('email not confirmed')) {
        emit(AuthFailure('Please verify your email — check your inbox for a confirmation link.'));
      } else if (e.message.toLowerCase().contains('invalid login credentials')) {
        emit(AuthFailure('Wrong email or password. If you signed up with Google, use the Google button.'));
      } else {
        emit(AuthFailure('Sign in failed: ${e.message}'));
      }
    } catch (e) {
      emit(AuthFailure(_parseError(e)));
    }
  }

  Future<void> _onSignUpRequested(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _authService.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      // If the session is immediately available (email confirmation disabled), log them in
      if (response.session != null) {
        final user = await _authService.getCurrentUserData();
        if (user != null) {
          emit(Authenticated(user));
          return;
        }
      }

      // Email confirmation is enabled — auto sign-in attempt
      try {
        await _authService.signIn(event.email, event.password);
        final user = await _authService.getCurrentUserData();
        if (user != null) {
          emit(Authenticated(user));
          return;
        }
      } catch (_) {}

      emit(AuthFailure('Account created! Check your email to verify, then log in.'));
    } catch (e) {
      emit(AuthFailure(_parseError(e)));
    }
  }

  Future<void> _onGoogleSignIn(GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithGoogle();
      // Do not check user immediately; wait for Supabase onAuthStateChange listener
      // which will dispatch AuthUserUpdated event when redirect is successful.
    } catch (e) {
      emit(AuthFailure(_parseError(e)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _authService.signOut();
    emit(Unauthenticated());
  }

  void _onAuthUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(Unauthenticated());
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Wrong email or password. If you signed up with Google, use the Google button instead.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please verify your email first — check your inbox.';
    }
    if (msg.contains('already registered')) {
      return 'Email already in use. Try logging in.';
    }
    if (msg.contains('Provider') || msg.contains('identity') || msg.contains('oauth')) {
      return 'This account uses Google Sign-In. Please use the "Continue with Google" button.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'No internet connection.';
    }
    // Show raw error so we can diagnose unknown failures
    return 'Login failed: $msg';
  }
}
