import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final bool isResetEmailSent;
  final User? user;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.isResetEmailSent = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? isResetEmailSent,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      isResetEmailSent: isResetEmailSent ?? this.isResetEmailSent,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = const AuthState();
  }

  /// Sign In with Email and Password
  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      String errorKey = 'error_generic';
      if (e.code == 'user-not-found') {
        errorKey = 'error_user_not_found';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorKey = 'error_wrong_password';
      } else if (e.code == 'invalid-email') {
        errorKey = 'error_invalid_email';
      } else {
        errorKey = e.message ?? 'error_generic';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorKey,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign Up with Email, Password, and Full Name
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _repository.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: credential.user,
      );
    } on FirebaseAuthException catch (e) {
      String errorKey = 'error_generic';
      if (e.code == 'email-already-in-use') {
        errorKey = 'error_email_in_use';
      } else if (e.code == 'weak-password') {
        errorKey = 'error_weak_password';
      } else if (e.code == 'invalid-email') {
        errorKey = 'error_invalid_email';
      } else {
        errorKey = e.message ?? 'error_generic';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorKey,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sends a Password Reset Email
  Future<void> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isResetEmailSent: false);

    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = state.copyWith(
        isLoading: false,
        isResetEmailSent: true,
      );
    } on FirebaseAuthException catch (e) {
      String errorKey = 'error_generic';
      if (e.code == 'user-not-found') {
        errorKey = 'error_user_not_found';
      } else if (e.code == 'invalid-email') {
        errorKey = 'error_invalid_email';
      } else {
        errorKey = e.message ?? 'error_generic';
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorKey,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Authenticate using Google
  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userCredential = await _repository.signInWithGoogle();
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: userCredential.user,
      );
    } catch (e) {
      final errorMsg = e is FirebaseAuthException && e.code == 'ERROR_ABORTED_BY_USER'
          ? null
          : (e is FirebaseAuthException ? (e.message ?? 'Google Sign-In failed') : e.toString());
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
    }
  }

  /// Sign out
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

final isSplashFinishedProvider = StateProvider<bool>((ref) => false);
