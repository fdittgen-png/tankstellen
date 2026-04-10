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
}
