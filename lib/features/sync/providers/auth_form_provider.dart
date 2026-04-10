import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_form_provider.g.dart';

/// UI-only state for the authentication screen form.
///
/// Text inputs themselves live in [TextEditingController]s owned by the
/// screen (Flutter lifecycle requirement); everything else (toggles,
/// progress, errors) lives here so the screen can be a [ConsumerWidget]
/// and rebuild selectively.
class AuthFormState {
  final bool isSignUp;
  final bool isLoading;
  final bool showPassword;
  final bool showConfirm;
  final String? error;

  const AuthFormState({
    this.isSignUp = true,
    this.isLoading = false,
    this.showPassword = false,
    this.showConfirm = false,
    this.error,
  });

  AuthFormState copyWith({
    bool? isSignUp,
    bool? isLoading,
    bool? showPassword,
    bool? showConfirm,
    String? error,
    bool clearError = false,
  }) {
    return AuthFormState(
      isSignUp: isSignUp ?? this.isSignUp,
      isLoading: isLoading ?? this.isLoading,
      showPassword: showPassword ?? this.showPassword,
      showConfirm: showConfirm ?? this.showConfirm,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class AuthFormController extends _$AuthFormController {
  @override
  AuthFormState build() => const AuthFormState();

  void toggleSignUp() {
    state = state.copyWith(isSignUp: !state.isSignUp, clearError: true);
  }

  void togglePassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void toggleConfirm() {
    state = state.copyWith(showConfirm: !state.showConfirm);
  }

  void setLoading(bool value) {
    state = state.copyWith(
      isLoading: value,
      clearError: value, // clear error when starting a new attempt
    );
  }

  void setError(String? error) {
    state = state.copyWith(
      error: error,
      clearError: error == null,
      isLoading: false,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const AuthFormState();
  }

  /// Used to force a rebuild when the password text changes (so the strength
  /// indicator can update). Preserves all current state.
  void touch() {
    state = state.copyWith();
  }
}
