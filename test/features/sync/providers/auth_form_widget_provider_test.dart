import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/providers/auth_form_widget_provider.dart';

void main() {
  group('AuthFormWidgetController', () {
    test('initial state defaults to anonymous sign-up with hidden passwords',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(authFormWidgetControllerProvider);
      expect(state.useEmail, isFalse);
      expect(state.isSignUp, isTrue);
      expect(state.showPassword, isFalse);
      expect(state.showConfirm, isFalse);
    });

    test('setUseEmail flips useEmail and preserves other fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);

      notifier.togglePassword();
      notifier.setUseEmail(true);
      final state = container.read(authFormWidgetControllerProvider);
      expect(state.useEmail, isTrue);
      expect(state.showPassword, isTrue);
    });

    test('toggleSignUp flips signup flag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);
      notifier.toggleSignUp();
      expect(
        container.read(authFormWidgetControllerProvider).isSignUp,
        isFalse,
      );
      notifier.toggleSignUp();
      expect(
        container.read(authFormWidgetControllerProvider).isSignUp,
        isTrue,
      );
    });

    test('togglePassword and toggleConfirm flip independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);

      notifier.togglePassword();
      expect(
        container.read(authFormWidgetControllerProvider).showPassword,
        isTrue,
      );
      expect(
        container.read(authFormWidgetControllerProvider).showConfirm,
        isFalse,
      );

      notifier.toggleConfirm();
      expect(
        container.read(authFormWidgetControllerProvider).showConfirm,
        isTrue,
      );
    });
  });

  group('AuthFormWidgetState', () {
    test('default constructor has expected flag values', () {
      const state = AuthFormWidgetState();
      expect(state.useEmail, isFalse);
      expect(state.isSignUp, isTrue);
      expect(state.showPassword, isFalse);
      expect(state.showConfirm, isFalse);
    });

    test('copyWith updates only useEmail when provided', () {
      const state = AuthFormWidgetState();
      final next = state.copyWith(useEmail: true);
      expect(next.useEmail, isTrue);
      expect(next.isSignUp, state.isSignUp);
      expect(next.showPassword, state.showPassword);
      expect(next.showConfirm, state.showConfirm);
    });

    test('copyWith updates only isSignUp when provided', () {
      const state = AuthFormWidgetState();
      final next = state.copyWith(isSignUp: false);
      expect(next.isSignUp, isFalse);
      expect(next.useEmail, state.useEmail);
      expect(next.showPassword, state.showPassword);
      expect(next.showConfirm, state.showConfirm);
    });

    test('copyWith updates only showPassword when provided', () {
      const state = AuthFormWidgetState();
      final next = state.copyWith(showPassword: true);
      expect(next.showPassword, isTrue);
      expect(next.useEmail, state.useEmail);
      expect(next.isSignUp, state.isSignUp);
      expect(next.showConfirm, state.showConfirm);
    });

    test('copyWith updates only showConfirm when provided', () {
      const state = AuthFormWidgetState();
      final next = state.copyWith(showConfirm: true);
      expect(next.showConfirm, isTrue);
      expect(next.useEmail, state.useEmail);
      expect(next.isSignUp, state.isSignUp);
      expect(next.showPassword, state.showPassword);
    });

    test('copyWith with no arguments returns an equivalent state', () {
      const state = AuthFormWidgetState(
        useEmail: true,
        isSignUp: false,
        showPassword: true,
        showConfirm: true,
      );
      final next = state.copyWith();
      expect(next.useEmail, state.useEmail);
      expect(next.isSignUp, state.isSignUp);
      expect(next.showPassword, state.showPassword);
      expect(next.showConfirm, state.showConfirm);
    });
  });

  group('AuthFormWidgetController — additional behaviour', () {
    test('setUseEmail(false) after true returns useEmail to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);

      notifier.setUseEmail(true);
      expect(
        container.read(authFormWidgetControllerProvider).useEmail,
        isTrue,
      );

      notifier.setUseEmail(false);
      expect(
        container.read(authFormWidgetControllerProvider).useEmail,
        isFalse,
      );
    });

    test('toggleSignUp round-trips from default true → false → true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);

      expect(
        container.read(authFormWidgetControllerProvider).isSignUp,
        isTrue,
      );
      notifier.toggleSignUp();
      expect(
        container.read(authFormWidgetControllerProvider).isSignUp,
        isFalse,
      );
      notifier.toggleSignUp();
      expect(
        container.read(authFormWidgetControllerProvider).isSignUp,
        isTrue,
      );
    });

    test('togglePassword round-trips from false → true → false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);

      expect(
        container.read(authFormWidgetControllerProvider).showPassword,
        isFalse,
      );
      notifier.togglePassword();
      expect(
        container.read(authFormWidgetControllerProvider).showPassword,
        isTrue,
      );
      notifier.togglePassword();
      expect(
        container.read(authFormWidgetControllerProvider).showPassword,
        isFalse,
      );
    });

    test('toggleConfirm round-trips from false → true → false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);

      expect(
        container.read(authFormWidgetControllerProvider).showConfirm,
        isFalse,
      );
      notifier.toggleConfirm();
      expect(
        container.read(authFormWidgetControllerProvider).showConfirm,
        isTrue,
      );
      notifier.toggleConfirm();
      expect(
        container.read(authFormWidgetControllerProvider).showConfirm,
        isFalse,
      );
    });

    test(
        'showPassword and showConfirm toggle independently '
        'without affecting useEmail or isSignUp', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);

      notifier.togglePassword();
      notifier.toggleConfirm();

      final state = container.read(authFormWidgetControllerProvider);
      expect(state.showPassword, isTrue);
      expect(state.showConfirm, isTrue);
      expect(state.useEmail, isFalse);
      expect(state.isSignUp, isTrue);
    });

    test(
        'sequence setUseEmail(true) → toggleSignUp → togglePassword → '
        'toggleConfirm produces the expected combined state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(authFormWidgetControllerProvider.notifier);

      notifier.setUseEmail(true);
      notifier.toggleSignUp();
      notifier.togglePassword();
      notifier.toggleConfirm();

      final state = container.read(authFormWidgetControllerProvider);
      expect(state.useEmail, isTrue);
      expect(state.isSignUp, isFalse);
      expect(state.showPassword, isTrue);
      expect(state.showConfirm, isTrue);
    });
  });
}
