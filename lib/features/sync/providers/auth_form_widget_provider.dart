import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_form_widget_provider.g.dart';

/// UI-only state for the reusable [AuthFormWidget].
///
/// Text inputs themselves live in [TextEditingController]s owned by the
/// widget (Flutter lifecycle requirement); everything else (toggles) lives
/// here so the widget can be a [ConsumerWidget] and rebuild selectively.
///
/// This provider is distinct from `authFormControllerProvider` which is
/// scoped to the full auth screen; the widget can be embedded elsewhere
/// (e.g. in the sync-setup flow).
class AuthFormWidgetState {
  final bool useEmail;
  final bool isSignUp;
  final bool showPassword;
  final bool showConfirm;

  const AuthFormWidgetState({
    this.useEmail = false,
    this.isSignUp = true,
    this.showPassword = false,
    this.showConfirm = false,
  });

  AuthFormWidgetState copyWith({
    bool? useEmail,
    bool? isSignUp,
    bool? showPassword,
    bool? showConfirm,
  }) {
    return AuthFormWidgetState(
      useEmail: useEmail ?? this.useEmail,
      isSignUp: isSignUp ?? this.isSignUp,
      showPassword: showPassword ?? this.showPassword,
      showConfirm: showConfirm ?? this.showConfirm,
    );
  }
}

@riverpod
class AuthFormWidgetController extends _$AuthFormWidgetController {
  @override
  AuthFormWidgetState build() => const AuthFormWidgetState();

  void setUseEmail(bool value) {
    state = state.copyWith(useEmail: value);
  }

  void toggleSignUp() {
    state = state.copyWith(isSignUp: !state.isSignUp);
  }

  void togglePassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void toggleConfirm() {
    state = state.copyWith(showConfirm: !state.showConfirm);
  }
}
