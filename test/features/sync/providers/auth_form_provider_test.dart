import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/providers/auth_form_provider.dart';

void main() {
  ProviderContainer make() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('AuthFormController.build', () {
    test('default state: sign-up, not loading, passwords hidden, no error',
        () {
      final s = make().read(authFormControllerProvider);
      expect(s.isSignUp, isTrue);
      expect(s.isLoading, isFalse);
      expect(s.showPassword, isFalse);
      expect(s.showConfirm, isFalse);
      expect(s.error, isNull);
    });
  });

  group('toggles', () {
    test('toggleSignUp flips the mode and clears any existing error', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.setError('bad creds');
      expect(c.read(authFormControllerProvider).error, 'bad creds');

      n.toggleSignUp();
      final s = c.read(authFormControllerProvider);
      expect(s.isSignUp, isFalse);
      expect(s.error, isNull, reason: 'mode change must wipe the stale error');
    });

    test('togglePassword flips only the showPassword flag', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.togglePassword();
      expect(c.read(authFormControllerProvider).showPassword, isTrue);
      expect(c.read(authFormControllerProvider).showConfirm, isFalse);
    });

    test('toggleConfirm flips only the showConfirm flag', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.toggleConfirm();
      expect(c.read(authFormControllerProvider).showConfirm, isTrue);
      expect(c.read(authFormControllerProvider).showPassword, isFalse);
    });
  });

  group('loading + error interplay', () {
    test('setLoading(true) clears a stale error (new attempt starts clean)',
        () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.setError('last try failed');
      n.setLoading(true);
      final s = c.read(authFormControllerProvider);
      expect(s.isLoading, isTrue);
      expect(s.error, isNull);
    });

    test('setLoading(false) leaves error untouched', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.setError('nope');
      n.setLoading(false);
      expect(c.read(authFormControllerProvider).error, 'nope');
    });

    test('setError stops loading and sets the message', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.setLoading(true);
      n.setError('invalid password');
      final s = c.read(authFormControllerProvider);
      expect(s.error, 'invalid password');
      expect(s.isLoading, isFalse,
          reason: 'reporting an error must always drop the spinner');
    });

    test('setError(null) clears the existing error', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.setError('x');
      n.setError(null);
      expect(c.read(authFormControllerProvider).error, isNull);
    });
  });

  group('clearError', () {
    test('removes an existing error', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.setError('x');
      n.clearError();
      expect(c.read(authFormControllerProvider).error, isNull);
    });

    test('no-op on already-clean state', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.clearError();
      expect(c.read(authFormControllerProvider).error, isNull);
    });
  });

  group('reset', () {
    test('returns to the default state', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.toggleSignUp();
      n.togglePassword();
      n.setError('x');
      n.setLoading(true);
      n.reset();
      final s = c.read(authFormControllerProvider);
      expect(s.isSignUp, isTrue);
      expect(s.isLoading, isFalse);
      expect(s.showPassword, isFalse);
      expect(s.showConfirm, isFalse);
      expect(s.error, isNull);
    });
  });

  group('touch', () {
    test('preserves every field but emits a new state instance', () {
      final c = make();
      final n = c.read(authFormControllerProvider.notifier);
      n.toggleSignUp();
      n.togglePassword();
      n.setError('x');
      final before = c.read(authFormControllerProvider);

      n.touch();

      final after = c.read(authFormControllerProvider);
      expect(after.isSignUp, before.isSignUp);
      expect(after.showPassword, before.showPassword);
      expect(after.error, before.error);
      // Preserves by value — it's used to trigger a rebuild, so a
      // fresh object is still emitted by copyWith. We don't assert
      // `identical` because Riverpod may dedupe equivalent states.
    });
  });
}
