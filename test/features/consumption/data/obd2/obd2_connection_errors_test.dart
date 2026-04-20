import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';

void main() {
  group('Obd2ConnectionError typed hierarchy (#741/#742)', () {
    test('every concrete error carries a non-empty default message', () {
      // #742 fallback path: when the UI can't match a specific type,
      // it renders e.message directly. Ensure no error class ever
      // bubbles up an empty string.
      final errors = <Obd2ConnectionError>[
        const Obd2PermissionDenied(),
        const Obd2ScanTimeout(),
        const Obd2AdapterUnresponsive(),
        const Obd2ProtocolInitFailed('???'),
      ];
      for (final e in errors) {
        expect(e.message, isNotEmpty,
            reason: '$e must carry a user-visible message');
      }
    });

    test('Obd2ProtocolInitFailed includes the raw response for debugging',
        () {
      const e = Obd2ProtocolInitFailed('GARBAGE>');
      expect(e.message, contains('GARBAGE>'));
    });

    test('toString prepends the runtime type — useful in logs', () {
      expect(const Obd2ScanTimeout().toString(), startsWith('Obd2ScanTimeout'));
    });

    test('sealed hierarchy — every type implements Exception', () {
      expect(const Obd2PermissionDenied(), isA<Exception>());
      expect(const Obd2ScanTimeout(), isA<Exception>());
      expect(const Obd2AdapterUnresponsive(), isA<Exception>());
      expect(const Obd2ProtocolInitFailed('x'), isA<Exception>());
    });
  });
}
