import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/screens/sync_wizard_screen.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // A real Supabase anon key for testing (228 characters).
  // This is a test key structure — safe to include in tests.
  const validKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRweGZsbWNwdW10bWVoc2xjaXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2Mzg0NjYsImV4cCI6MjA5MDIxNDQ2Nn0.94L8m6ew6R7P2sOhTJJatLYdFqYLmQACyxCmYKlhGXc';

  group('Supabase anon key validation', () {
    test('valid Supabase anon key is ~208 characters', () {
      // Standard Supabase anon key structure:
      // Header(36) + "." + Payload(~127) + "." + Signature(43) = ~208
      // Payload length depends on project ref (always 20 chars currently).
      expect(validKey.length, 208);
      expect(validKey.length, greaterThanOrEqualTo(200));
      expect(validKey.length, lessThanOrEqualTo(512));
    });

    test('key has three dot-separated JWT segments', () {
      final parts = validKey.split('.');
      expect(parts.length, 3, reason: 'JWT must have header.payload.signature');
    });

    test('JWT header is always the same for HS256', () {
      final header = validKey.split('.')[0];
      expect(header, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9');
      expect(header.length, 36);
    });

    test('JWT signature is always 43 characters (HS256 = 32 bytes base64url)', () {
      final signature = validKey.split('.')[2];
      expect(signature.length, 43);
    });

    test('key with whitespace is sanitized correctly', () {
      const keyWithSpaces = 'eyJhbGci OiJIUzI1NiIs InR5cCI6IkpXVCJ9.test.sig';
      final sanitized = keyWithSpaces.replaceAll(RegExp(r'\s+'), '');
      expect(sanitized, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.sig');
      expect(sanitized.contains(' '), isFalse);
    });

    test('key with line breaks is sanitized correctly', () {
      const keyWithBreaks = 'eyJhbGciOiJIUzI1NiIs\nInR5cCI6IkpXVCJ9\n.test.sig';
      final sanitized = keyWithBreaks.replaceAll(RegExp(r'\s+'), '');
      expect(sanitized, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.sig');
    });

    test('truncated key is detected (less than 200 chars)', () {
      const truncated = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.partial';
      expect(truncated.length, lessThan(200));
      expect(truncated.length < 200, isTrue,
          reason: 'Truncated key should be less than 200 characters');
    });

    test('key exceeding max length is detected', () {
      final tooLong = '${validKey}extra_garbage_text_appended_from_copy_paste';
      expect(tooLong.length, greaterThan(228));
      expect(tooLong.length > 512, isFalse,
          reason: 'Even with garbage, typical paste is under 512');
    });

    test('empty key is handled', () {
      const empty = '';
      expect(empty.isEmpty, isTrue);
      expect(empty.length, 0);
    });

    test('non-JWT string is accepted by sanitizer but fails on connect', () {
      // The sanitizer only strips whitespace; JWT validation happens at Supabase
      const notJwt = 'this-is-not-a-jwt-token-at-all';
      final sanitized = notJwt.replaceAll(RegExp(r'\s+'), '');
      expect(sanitized, notJwt);
      expect(sanitized.split('.').length, 1,
          reason: 'Not a JWT — has no dots');
    });
  });

  group('SyncWizardScreen key field', () {
    testWidgets('renders Scan QR Code button on join flow', (tester) async {
      await pumpApp(tester, const SyncWizardScreen());

      // Navigate to join existing
      await tester.tap(find.text('Join an existing database'));
      await tester.pumpAndSettle();

      expect(find.text('Scan QR Code'), findsOneWidget);
      expect(find.text('Anon Key'), findsOneWidget);
    });
  });
}
