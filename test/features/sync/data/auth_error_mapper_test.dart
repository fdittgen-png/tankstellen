import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/data/auth_error_mapper.dart';

void main() {
  group('friendlyAuthError', () {
    test('maps SocketException to no-network message', () {
      const e = SocketException(
          "Failed host lookup: 'klelxnkzrxlpzuddhpfg.supabase.co' (errno = 7)");
      expect(friendlyAuthError(e, null),
          'No network connection. Try again later.');
    });

    test('maps AuthRetryableFetchException string to no-network message', () {
      final e = Exception(
          'AuthRetryableFetchException(message: ClientException with SocketException: Failed host lookup, statusCode: null)');
      expect(friendlyAuthError(e, null),
          'No network connection. Try again later.');
    });

    test('maps invalid_credentials to credentials message', () {
      final e = Exception('AuthException: invalid_credentials');
      expect(friendlyAuthError(e, null),
          'Invalid email or password. Check your credentials.');
    });

    test('maps user_already_exists to already-registered message', () {
      final e = Exception('AuthException: user_already_exists');
      expect(friendlyAuthError(e, null),
          'This email is already registered. Try signing in instead.');
    });

    test('maps already registered (alternate phrasing) to same message', () {
      final e = Exception('user already registered');
      expect(friendlyAuthError(e, null),
          'This email is already registered. Try signing in instead.');
    });

    test('maps email_not_confirmed to confirmation message', () {
      final e = Exception('AuthException: email_not_confirmed');
      expect(friendlyAuthError(e, null),
          'Please check your email and confirm your account first.');
    });

    test('falls back to generic message for unknown exceptions', () {
      final e = Exception('something unexpected went wrong');
      expect(friendlyAuthError(e, null),
          'Sign-in failed. Please try again.');
    });

    test('never leaks the supabase URL', () {
      const e = SocketException(
          "Failed host lookup: 'klelxnkzrxlpzuddhpfg.supabase.co' (errno = 7)");
      final msg = friendlyAuthError(e, null);
      expect(msg.contains('supabase'), isFalse);
      expect(msg.contains('klelxnkzrxlpzuddhpfg'), isFalse);
    });

    test('never leaks the exception type name', () {
      final e = Exception('AuthRetryableFetchException(...)');
      final msg = friendlyAuthError(e, null);
      expect(msg.contains('Exception'), isFalse);
      expect(msg.contains('AuthRetryableFetchException'), isFalse);
    });
  });
}
