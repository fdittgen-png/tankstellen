import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/feedback/github_issue_body_formatter.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter.dart'
    show ScanKind;

void main() {
  group('GithubIssueBodyFormatter.scanKindLabel', () {
    test('returns "Receipt" for ScanKind.receipt', () {
      expect(
        GithubIssueBodyFormatter.scanKindLabel(ScanKind.receipt),
        'Receipt',
      );
    });

    test('returns "Pump display" for ScanKind.pumpDisplay', () {
      expect(
        GithubIssueBodyFormatter.scanKindLabel(ScanKind.pumpDisplay),
        'Pump display',
      );
    });
  });

  group('GithubIssueBodyFormatter.fieldTable', () {
    test('empty map returns the "(none)" placeholder', () {
      final result = GithubIssueBodyFormatter.fieldTable(
        const <String, String?>{},
      );
      expect(result, '_(none)_\n');
    });

    test('single non-null entry produces a header + one data row table', () {
      final result = GithubIssueBodyFormatter.fieldTable(
        const <String, String?>{'price': '1.799'},
      );
      expect(result, contains('| Field | Value |'));
      expect(result, contains('| --- | --- |'));
      expect(result, contains('| price | 1.799 |'));
      // header + separator + one entry + trailing newline => 4 lines.
      expect(result.split('\n').where((l) => l.isNotEmpty).length, 3);
    });

    test('null value renders as "_(empty)_"', () {
      final result = GithubIssueBodyFormatter.fieldTable(
        const <String, String?>{'fuel': null},
      );
      expect(result, contains('| fuel | _(empty)_ |'));
    });

    test('empty string value also renders as "_(empty)_"', () {
      final result = GithubIssueBodyFormatter.fieldTable(
        const <String, String?>{'fuel': ''},
      );
      expect(result, contains('| fuel | _(empty)_ |'));
    });

    test('values containing pipes are escaped via sanitizeCell', () {
      final result = GithubIssueBodyFormatter.fieldTable(
        const <String, String?>{'note': 'a|b'},
      );
      expect(result, contains(r'| note | a\|b |'));
    });

    test('values containing newlines are flattened to spaces', () {
      final result = GithubIssueBodyFormatter.fieldTable(
        const <String, String?>{'note': 'line1\nline2'},
      );
      expect(result, contains('| note | line1 line2 |'));
    });
  });

  group('GithubIssueBodyFormatter.sanitize', () {
    test('preserves regular text untouched', () {
      const input = 'Hello, world! 1.799 EUR Diesel';
      expect(GithubIssueBodyFormatter.sanitize(input), input);
    });

    test('strips ANSI CSI escape sequences', () {
      const input = 'normal \x1B[31mred\x1B[0m more';
      expect(GithubIssueBodyFormatter.sanitize(input), 'normal red more');
    });

    test('strips NUL and other low control characters', () {
      const input = 'a\x00b\x01c\x07d';
      expect(GithubIssueBodyFormatter.sanitize(input), 'abcd');
    });

    test('preserves tab and newline', () {
      const input = 'a\tb\nc';
      expect(GithubIssueBodyFormatter.sanitize(input), 'a\tb\nc');
    });

    test('strips DEL (0x7F) but leaves printable text', () {
      const input = 'before\x7Fafter';
      expect(GithubIssueBodyFormatter.sanitize(input), 'beforeafter');
    });
  });

  group('GithubIssueBodyFormatter.sanitizeCell', () {
    test('escapes pipes', () {
      expect(
        GithubIssueBodyFormatter.sanitizeCell('a|b|c'),
        r'a\|b\|c',
      );
    });

    test('replaces newlines with single spaces', () {
      expect(
        GithubIssueBodyFormatter.sanitizeCell('line1\nline2\nline3'),
        'line1 line2 line3',
      );
    });

    test('preserves regular text', () {
      expect(
        GithubIssueBodyFormatter.sanitizeCell('plain value 1.799'),
        'plain value 1.799',
      );
    });

    test('combines sanitize + cell-escape (ANSI + pipe + newline)', () {
      const input = 'red\x1B[31mtext\x1B[0m | next\nline';
      expect(
        GithubIssueBodyFormatter.sanitizeCell(input),
        r'redtext \| next line',
      );
    });
  });

  group('GithubIssueBodyFormatter.buildBody', () {
    // 4-byte PNG signature; not a decodable image, so EXIF strip will fail
    // and the formatter should add a Notes section before the image block.
    final tinyImage = Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47]);

    test('starts with "## Scan kind" and includes the kind label', () {
      final body = GithubIssueBodyFormatter.buildBody(
        kind: ScanKind.receipt,
        rawOcrText: 'OCR_PAYLOAD',
        parsedFields: const <String, String?>{},
        userCorrections: const <String, String?>{},
        imageBytes: tinyImage,
      );
      expect(body.startsWith('## Scan kind'), isTrue);
      expect(body, contains('- Receipt'));
    });

    test('contains the raw OCR text inside a fenced code block', () {
      final body = GithubIssueBodyFormatter.buildBody(
        kind: ScanKind.pumpDisplay,
        rawOcrText: 'TOTAL 42.50',
        parsedFields: const <String, String?>{},
        userCorrections: const <String, String?>{},
        imageBytes: tinyImage,
      );
      expect(body, contains('## Raw OCR text'));
      expect(body, contains('```\nTOTAL 42.50'));
    });

    test('renders parsed fields and user corrections as tables', () {
      final body = GithubIssueBodyFormatter.buildBody(
        kind: ScanKind.receipt,
        rawOcrText: 'irrelevant',
        parsedFields: const <String, String?>{'price': '1.799'},
        userCorrections: const <String, String?>{'fuel': 'Diesel'},
        imageBytes: tinyImage,
      );
      expect(body, contains('## Parsed fields'));
      expect(body, contains('| price | 1.799 |'));
      expect(body, contains('## User corrections'));
      expect(body, contains('| fuel | Diesel |'));
    });

    test('omits the User note section when userNote is null', () {
      final body = GithubIssueBodyFormatter.buildBody(
        kind: ScanKind.receipt,
        rawOcrText: 'irrelevant',
        parsedFields: const <String, String?>{},
        userCorrections: const <String, String?>{},
        imageBytes: tinyImage,
      );
      expect(body.contains('## User note'), isFalse);
    });

    test('omits the User note section when userNote is whitespace only', () {
      final body = GithubIssueBodyFormatter.buildBody(
        kind: ScanKind.receipt,
        rawOcrText: 'irrelevant',
        parsedFields: const <String, String?>{},
        userCorrections: const <String, String?>{},
        imageBytes: tinyImage,
        userNote: '   \n  ',
      );
      expect(body.contains('## User note'), isFalse);
    });

    test('includes the User note section when userNote is non-empty', () {
      final body = GithubIssueBodyFormatter.buildBody(
        kind: ScanKind.receipt,
        rawOcrText: 'irrelevant',
        parsedFields: const <String, String?>{},
        userCorrections: const <String, String?>{},
        imageBytes: tinyImage,
        userNote: 'Looked wrong',
      );
      expect(body, contains('## User note'));
      expect(body, contains('Looked wrong'));
    });

    test(
      'embeds the image as a base64 data URL when bytes fit in the body',
      () {
        final body = GithubIssueBodyFormatter.buildBody(
          kind: ScanKind.receipt,
          rawOcrText: 'irrelevant',
          parsedFields: const <String, String?>{},
          userCorrections: const <String, String?>{},
          imageBytes: tinyImage,
        );
        expect(body, contains('## Scan image'));
        // Decoding fails (4-byte payload), so original bytes are embedded.
        final expectedB64 = base64Encode(tinyImage);
        expect(
          body,
          contains('![scan](data:image/jpeg;base64,$expectedB64)'),
        );
      },
    );

    test(
      'adds the EXIF-strip-failed Notes block when the image cannot be '
      'decoded',
      () {
        final body = GithubIssueBodyFormatter.buildBody(
          kind: ScanKind.receipt,
          rawOcrText: 'irrelevant',
          parsedFields: const <String, String?>{},
          userCorrections: const <String, String?>{},
          imageBytes: tinyImage,
        );
        expect(body, contains('## Notes'));
        expect(
          body,
          contains('_[note: EXIF strip failed, raw bytes uploaded]_'),
        );
      },
    );

    test(
      'replaces the image embed with the "too large" placeholder when the '
      'base64 payload would exceed maxBodyLength',
      () {
        // Build a payload large enough that base64(imageBytes) + the
        // already-written body text breaks the 65000-char ceiling.
        // 60_000 raw bytes -> ~80_000 base64 chars, well over the limit.
        final hugeImage = Uint8List(60000);
        final body = GithubIssueBodyFormatter.buildBody(
          kind: ScanKind.receipt,
          rawOcrText: 'irrelevant',
          parsedFields: const <String, String?>{},
          userCorrections: const <String, String?>{},
          imageBytes: hugeImage,
        );
        expect(body, contains('_[image too large to embed]_'));
        expect(body, isNot(contains('data:image/jpeg;base64,')));
      },
    );

    test('sanitizes raw OCR text (strips control chars)', () {
      final body = GithubIssueBodyFormatter.buildBody(
        kind: ScanKind.receipt,
        rawOcrText: 'before\x00after',
        parsedFields: const <String, String?>{},
        userCorrections: const <String, String?>{},
        imageBytes: tinyImage,
      );
      expect(body, contains('beforeafter'));
      expect(body.contains('\x00'), isFalse);
    });
  });

  group('GithubIssueBodyFormatter.maxBodyLength', () {
    test('equals 65000', () {
      expect(GithubIssueBodyFormatter.maxBodyLength, 65000);
    });
  });
}
