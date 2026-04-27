import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/features/sync/data/auth_error_mapper.dart';
import 'package:tankstellen/l10n/app_localizations_de.dart';
import 'package:tankstellen/l10n/app_localizations_en.dart';
import 'package:tankstellen/l10n/app_localizations_fr.dart';

/// Pure unit tests for [mapAuthErrorToLocalized] (#1186).
///
/// These tests deliberately do NOT spin up a Riverpod container or a
/// widget tree — they instantiate the localization classes directly so
/// we can exercise the mapper across en / de / fr without a heavy
/// pumpApp harness.
void main() {
  final en = AppLocalizationsEn();
  final de = AppLocalizationsDe();
  final fr = AppLocalizationsFr();

  setUp(() {
    // The mapper logs the original error via [errorLogger]. Without a
    // bound foreground container, the logger falls through to the
    // Hive-backed spool which would fail (Hive isn't initialised in
    // these pure tests). Override the enqueue to a no-op so the
    // logging side-effect is exercised but doesn't drag Hive in.
    errorLogger.spoolEnqueueOverride = ({
      required String isolateTaskName,
      required Object error,
      StackTrace? stack,
      Map<String, dynamic>? contextMap,
      DateTime? timestamp,
    }) async {};
  });

  tearDown(() {
    errorLogger.resetForTest();
  });

  group('mapAuthErrorToLocalized', () {
    test('Supabase invalid_credentials -> friendly localized string', () {
      const err = AuthException('invalid_credentials');
      expect(mapAuthErrorToLocalized(err, en), en.authErrorInvalidCredentials);
      expect(mapAuthErrorToLocalized(err, de), de.authErrorInvalidCredentials);
      expect(mapAuthErrorToLocalized(err, fr), fr.authErrorInvalidCredentials);
    });

    test('Supabase user_already_exists -> friendly localized string', () {
      const err = AuthException('user_already_exists');
      expect(mapAuthErrorToLocalized(err, en), en.authErrorUserAlreadyExists);
      expect(mapAuthErrorToLocalized(err, de), de.authErrorUserAlreadyExists);
      expect(mapAuthErrorToLocalized(err, fr), fr.authErrorUserAlreadyExists);
    });

    test('Supabase email_not_confirmed -> friendly localized string', () {
      const err = AuthException('email_not_confirmed');
      expect(mapAuthErrorToLocalized(err, en), en.authErrorEmailNotConfirmed);
      expect(mapAuthErrorToLocalized(err, de), de.authErrorEmailNotConfirmed);
      expect(mapAuthErrorToLocalized(err, fr), fr.authErrorEmailNotConfirmed);
    });

    test('SocketException -> "no network" localized string', () {
      const err = SocketException('Failed host lookup: example.com');
      expect(mapAuthErrorToLocalized(err, en), en.authErrorNoNetwork);
      expect(mapAuthErrorToLocalized(err, de), de.authErrorNoNetwork);
      expect(mapAuthErrorToLocalized(err, fr), fr.authErrorNoNetwork);
    });

    test('AuthRetryableFetchException -> "no network" localized string', () {
      // This is the literal exception type users currently see leak into
      // the error pill (#1186) — guard against regression.
      final err = AuthRetryableFetchException();
      expect(mapAuthErrorToLocalized(err, en), en.authErrorNoNetwork);
      expect(mapAuthErrorToLocalized(err, de), de.authErrorNoNetwork);
      expect(mapAuthErrorToLocalized(err, fr), fr.authErrorNoNetwork);
    });

    test('http.ClientException -> "no network" localized string', () {
      final err = http.ClientException('Connection refused');
      expect(mapAuthErrorToLocalized(err, en), en.authErrorNoNetwork);
    });

    test('default fallback for an unrecognized error', () {
      final err = StateError('something completely unrelated');
      expect(mapAuthErrorToLocalized(err, en), en.authErrorGeneric);
      expect(mapAuthErrorToLocalized(err, de), de.authErrorGeneric);
      expect(mapAuthErrorToLocalized(err, fr), fr.authErrorGeneric);
    });

    test('never returns the raw toString() (no exception type names)', () {
      // Defensive: the friendly result must not contain any of the
      // type-name fragments that trigger #1186 in the first place.
      final cases = <Object>[
        AuthRetryableFetchException(),
        const SocketException('Failed host lookup: foo.supabase.co'),
        const AuthException(
            'invalid_credentials at https://klelxnkzrxlpzuddhpfg.supabase.co'),
        StateError('whatever'),
      ];
      for (final err in cases) {
        final out = mapAuthErrorToLocalized(err, en);
        expect(out, isNot(contains('Exception')),
            reason: 'mapped output must not leak the exception name: $err');
        expect(out, isNot(contains('klelxnkzrxlpzuddhpfg')),
            reason: 'mapped output must not leak the project URL: $err');
      }
    });

    test('Failed host lookup substring routes to no-network', () {
      // gotrue sometimes wraps DNS failures in AuthUnknownException whose
      // toString() contains "Failed host lookup". Verify the substring
      // path rather than the runtime-type path.
      final err = StateError('Failed host lookup: example.supabase.co');
      expect(mapAuthErrorToLocalized(err, en), en.authErrorNoNetwork);
    });
  });
}
