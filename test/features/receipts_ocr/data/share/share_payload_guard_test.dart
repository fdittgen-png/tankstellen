// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/receipts_ocr/data/share/share_payload_guard.dart';

import '../../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  group('isAcceptableSharePayload (#3612 ingestion caps)', () {
    test('accepts every extension the native receivers produce', () {
      for (final path in [
        '/cache/shared_receipt_1.jpg',
        '/cache/shared_receipt_1.jpeg',
        '/cache/shared_receipt_1.png',
        '/cache/shared_receipt_1.webp',
        '/cache/shared_receipt_1.pdf',
        '/cache/UPPERCASE.JPG',
        '/cache/mixed.Pdf',
      ]) {
        expect(
          isAcceptableSharePayload(sizeBytes: 1024, path: path),
          isTrue,
          reason: '$path must be accepted',
        );
      }
    });

    test('rejects non-receipt extensions and extensionless paths', () {
      for (final path in [
        '/cache/statement.docx',
        '/cache/clip.mp4',
        '/cache/payload.svg',
        '/cache/shared_receipt.bin',
        '/cache/archive.zip',
        '/cache/no_extension',
        '/cache/trailing.',
        '/cache/receipt.pdf.exe',
      ]) {
        expect(
          isAcceptableSharePayload(sizeBytes: 1024, path: path),
          isFalse,
          reason: '$path must be rejected',
        );
      }
    });

    test('accepts a file exactly at the 16 MB cap', () {
      expect(
        isAcceptableSharePayload(
          sizeBytes: kMaxSharePayloadBytes,
          path: '/cache/big.jpg',
        ),
        isTrue,
      );
    });

    test('rejects a file one byte over the 16 MB cap', () {
      expect(
        isAcceptableSharePayload(
          sizeBytes: kMaxSharePayloadBytes + 1,
          path: '/cache/bomb.jpg',
        ),
        isFalse,
      );
    });

    test('rejects zero-byte and negative sizes', () {
      expect(
        isAcceptableSharePayload(sizeBytes: 0, path: '/cache/empty.jpg'),
        isFalse,
      );
      expect(
        isAcceptableSharePayload(sizeBytes: -1, path: '/cache/weird.jpg'),
        isFalse,
      );
    });

    test('unknown size (null) passes the size check but not the '
        'extension check', () {
      // A file that cannot be stat-ed cannot be opened downstream either,
      // so an unknown size is not a decompression risk — the extension
      // rule still applies.
      expect(
        isAcceptableSharePayload(sizeBytes: null, path: '/gone/receipt.jpg'),
        isTrue,
      );
      expect(
        isAcceptableSharePayload(sizeBytes: null, path: '/gone/evil.apk'),
        isFalse,
      );
    });
  });

  group('sharePayloadSizeBytes — never throws (#2349 fault injection)', () {
    test('a missing / unreadable file yields null, not a throw', () {
      const missing = '/definitely/not/here/receipt.jpg';
      expect(() => sharePayloadSizeBytes(missing), returnsNormally,
          reason: 'the stat failure IS the injected fault — the probe '
              'must absorb it and report "unknown"');
      expect(sharePayloadSizeBytes(missing), isNull);
    });
  });
}
