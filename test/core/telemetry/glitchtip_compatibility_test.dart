import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #1127 — Glitchtip is Sentry-API-compatible. The promise of the
/// `core/telemetry/` abstraction is "config-only swap": pointing the
/// Sentry SDK at a Glitchtip endpoint must work without any code change.
///
/// These tests are the static guarantee behind that promise. They verify:
///
/// 1. A Glitchtip-shaped DSN (the URI format Glitchtip exposes in its
///    project settings) is structurally identical to a Sentry DSN — same
///    `https://<publicKey>@<host>/<projectId>` shape, parses to the same
///    `Uri` components.
/// 2. The cold-start DSN resolver (`AppInitializer.resolveSentryDsn`) is
///    backend-agnostic at the source level — no `sentry.io` host check,
///    no `getsentry.com` host check, no allowlist that would reject a
///    self-hosted endpoint.
/// 3. The dart-define key is `SENTRY_DSN` regardless of which backend
///    the user runs (this is the env var documented in
///    `docs/security/SELF_HOSTED_TELEMETRY.md`).
///
/// If any of these break, the swap-procedure doc is no longer truthful
/// and the issue's acceptance criterion ("No code change required to
/// swap — just config") regresses.
void main() {
  group('Glitchtip DSN URI shape matches Sentry DSN', () {
    // Sample Glitchtip DSN. Format mirrors what the Glitchtip UI prints
    // on a project's "Settings → SDK Setup" page. The publicKey, host,
    // and projectId are all examples.
    const glitchtipDsn =
        'https://abcdef0123456789abcdef0123456789@glitchtip.example.org/42';
    const sentryDsn =
        'https://abcdef0123456789abcdef0123456789@o1234567.ingest.sentry.io/42';

    test('Glitchtip DSN parses as a valid HTTPS URI with userInfo + path',
        () {
      final uri = Uri.parse(glitchtipDsn);
      expect(uri.scheme, 'https');
      expect(uri.userInfo, isNotEmpty,
          reason: 'publicKey lives in the userInfo segment');
      expect(uri.host, 'glitchtip.example.org');
      expect(uri.pathSegments, isNotEmpty,
          reason: 'projectId is the last path segment');
      expect(uri.pathSegments.last, '42');
    });

    test('Glitchtip and Sentry DSNs produce structurally identical Uris',
        () {
      final glitchtip = Uri.parse(glitchtipDsn);
      final sentry = Uri.parse(sentryDsn);

      // Both must expose the same set of fields the Sentry SDK pulls out
      // of `Dsn.parse` — scheme, userInfo (publicKey:secretKey), host,
      // and pathSegments (with projectId at the end).
      expect(glitchtip.scheme, sentry.scheme);
      expect(glitchtip.userInfo.split(':').first.length,
          sentry.userInfo.split(':').first.length,
          reason: 'public key portion is the same length on both backends');
      expect(glitchtip.pathSegments.last, sentry.pathSegments.last,
          reason: 'projectId in our fixture is the same so the test asserts '
              'shape — host and key differ but layout is identical');
      expect(glitchtip.hasEmptyPath, sentry.hasEmptyPath);
    });

    test('Glitchtip DSN with self-hosted port (e.g. 8000) still parses', () {
      // VPS deploys often expose Glitchtip on a non-default port behind a
      // reverse proxy; the SDK must still accept the DSN.
      const dsn =
          'https://abcdef0123456789abcdef0123456789@telemetry.example.org:8000/1';
      final uri = Uri.parse(dsn);
      expect(uri.port, 8000);
      expect(uri.host, 'telemetry.example.org');
      expect(uri.pathSegments.last, '1');
    });
  });

  group('AppInitializer.resolveSentryDsn is backend-agnostic', () {
    late String initSource;

    setUpAll(() {
      initSource = File('lib/app/app_initializer.dart').readAsStringSync();
    });

    test('source has no host allowlist that would reject Glitchtip', () {
      // If a future patch adds a host check (e.g. `dsn.contains('sentry.io')`)
      // it would silently break self-hosted deployments. Forbid the
      // common offenders at the source level.
      const forbidden = [
        'sentry.io',
        'getsentry.com',
        'ingest.sentry',
      ];
      for (final needle in forbidden) {
        expect(initSource, isNot(contains(needle)),
            reason: 'AppInitializer must treat the DSN as an opaque string. '
                "A host allowlist '$needle' would block Glitchtip.");
      }
    });

    test('dart-define key is exactly SENTRY_DSN (matches doc + build flag)',
        () {
      // `docs/security/SELF_HOSTED_TELEMETRY.md` tells users to set
      // `--dart-define=SENTRY_DSN=<glitchtip-url>` to swap backends.
      // If the env-var key drifts, the doc lies and the swap silently
      // fails to a no-op startup (DSN empty, telemetry disabled).
      expect(initSource, contains("String.fromEnvironment('SENTRY_DSN')"),
          reason: 'env var key must be exactly SENTRY_DSN — see '
              'docs/security/SELF_HOSTED_TELEMETRY.md');
    });

    test('resolver returns the configured DSN unchanged (no rewriting)', () {
      // Source-level invariant: the resolver returns either the stored
      // setting or the dart-define, not a transformed value. Anything
      // else (e.g. `if (dsn.contains('sentry.io')) dsn += ...`) would
      // break self-hosted deployments.
      final body = _extractMethodBody(initSource, 'static String resolveSentryDsn');
      expect(body, isNotNull);
      // No string concatenation or replacement on the DSN value.
      expect(body, isNot(contains('.replaceAll(')));
      expect(body, isNot(contains('.replaceFirst(')));
      // The function returns either `stored` or `buildDsn` — both are the
      // original opaque value.
      expect(body, contains('return stored'));
      expect(body, contains('return buildDsn'));
    });
  });

  group('docs/security/SELF_HOSTED_TELEMETRY.md is present and truthful', () {
    late String docSource;

    setUpAll(() {
      docSource =
          File('docs/security/SELF_HOSTED_TELEMETRY.md').readAsStringSync();
    });

    test('doc references the SENTRY_DSN env var (the actual swap point)', () {
      // If a contributor renames the env var without updating the doc,
      // the swap procedure becomes wrong. Pin them together.
      expect(docSource, contains('SENTRY_DSN'),
          reason: 'doc must name the exact env var users set to swap '
              'backends — that is SENTRY_DSN');
    });

    test('doc covers the required sections from the issue acceptance', () {
      // The four sections #1127 expects readers to find quickly. Match on
      // case-insensitive section anchors so a wording tweak doesn't break
      // the test.
      final lowered = docSource.toLowerCase();
      expect(lowered, contains('glitchtip'));
      expect(lowered, contains('self-host'));
      expect(lowered, contains('verif'),
          reason: 'doc must explain how to verify events land');
      expect(lowered, contains('trade-off'),
          reason: 'doc must list features Glitchtip lacks vs Sentry');
    });
  });
}

/// Extracts the body of the first method that starts with [signature].
/// Mirrors the helper in `test/app/app_initializer_test.dart` so the
/// two test files stay independent.
String? _extractMethodBody(String source, String signature) {
  final start = source.indexOf(signature);
  if (start < 0) return null;
  var i = source.indexOf('(', start);
  if (i < 0) return null;
  var parenDepth = 0;
  for (; i < source.length; i++) {
    final ch = source[i];
    if (ch == '(') parenDepth++;
    if (ch == ')') {
      parenDepth--;
      if (parenDepth == 0) {
        i++;
        break;
      }
    }
  }
  final braceStart = source.indexOf('{', i);
  if (braceStart < 0) return null;
  var depth = 0;
  for (var j = braceStart; j < source.length; j++) {
    final ch = source[j];
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) return source.substring(braceStart + 1, j);
    }
  }
  return null;
}
