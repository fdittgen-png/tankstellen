import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/station_id_validator.dart';

void main() {
  group('isValidStationId', () {
    test('accepts real-world station id formats', () {
      expect(isValidStationId('51D4B5A8-9F8F-4F10-BAF4-6E859F0BB03B'), isTrue);
      expect(isValidStationId('12345'), isTrue);
      expect(isValidStationId('a1b2c3'), isTrue);
      expect(isValidStationId('station.1_2-3'), isTrue);
    });

    test('rejects null, empty, or whitespace', () {
      expect(isValidStationId(null), isFalse);
      expect(isValidStationId(''), isFalse);
      expect(isValidStationId('   '), isFalse);
      expect(isValidStationId('abc def'), isFalse);
    });

    test('rejects path traversal and shell metacharacters', () {
      expect(isValidStationId('../../../etc/passwd'), isFalse);
      expect(isValidStationId('id;rm -rf /'), isFalse);
      expect(isValidStationId('id&whoami'), isFalse);
      expect(isValidStationId('id|ls'), isFalse);
      expect(isValidStationId('id\$(whoami)'), isFalse);
    });

    test('rejects html / injection payloads', () {
      expect(isValidStationId('<script>alert(1)</script>'), isFalse);
      expect(isValidStationId('id"onload="'), isFalse);
      expect(isValidStationId("id' OR 1=1--"), isFalse);
    });

    test('rejects overly long ids', () {
      final long = 'a' * 129;
      expect(isValidStationId(long), isFalse);
      final ok = 'a' * 128;
      expect(isValidStationId(ok), isTrue);
    });

    test('rejects unicode / non-ascii characters', () {
      expect(isValidStationId('stātion-ü'), isFalse);
      expect(isValidStationId('станция-1'), isFalse);
    });
  });
}
