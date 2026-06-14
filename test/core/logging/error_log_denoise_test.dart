// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_log_denoise.dart';

/// Unit tests for the global-error-handler de-noise predicates, extracted
/// from `app_initializer.dart` into `error_log_denoise.dart` (#3311) so they
/// stay small and independently testable.
void main() {
  group('isBenignStreamCancel (#2772)', () {
    test('the benign EventChannel cancel PlatformException → true', () {
      expect(
        isBenignStreamCancel(
          PlatformException(code: 'error', message: 'No active stream to cancel'),
        ),
        isTrue,
      );
    });

    test('case-insensitive on the message', () {
      expect(
        isBenignStreamCancel(
          PlatformException(code: 'error', message: 'NO ACTIVE STREAM TO CANCEL'),
        ),
        isTrue,
      );
    });

    test('a different PlatformException is NOT benign (still logged)', () {
      expect(
        isBenignStreamCancel(
          PlatformException(code: 'error', message: 'Bluetooth adapter is off'),
        ),
        isFalse,
      );
    });

    test('non-PlatformException errors are NOT benign', () {
      expect(isBenignStreamCancel(Exception('boom')), isFalse);
      expect(
        isBenignStreamCancel(
          const FormatException('No active stream to cancel'),
        ),
        isFalse,
      );
    });
  });

  group('isTileFetchNoise (#930 / 2026-05-27)', () {
    test('an OSM tile URL failure → noise (true)', () {
      expect(
        isTileFetchNoise(
          Exception('SocketException loading https://tile.openstreetmap.org/8/1/1.png'),
        ),
        isTrue,
      );
    });

    test('a failed host lookup → noise (offline)', () {
      expect(
        isTileFetchNoise(Exception('Failed host lookup: tile.example.com')),
        isTrue,
      );
    });

    test('an unrelated error is NOT tile noise', () {
      expect(isTileFetchNoise(Exception('RangeError: index out of bounds')),
          isFalse);
    });
  });

  /// #3311 — a brand-logo network image whose TLS handshake fails reaches
  /// FlutterError.onError with `library == 'image resource service'`, even
  /// though `CachedNetworkImage.errorWidget` already showed the fallback glyph.
  /// One flaky-network session logged 23 such HandshakeExceptions. The de-noise
  /// predicate must drop them — but ONLY for the image library + a network-class
  /// error, so a genuine image-decode bug still surfaces.
  group('isHandledImageNetworkNoise (#3311)', () {
    test('image-library HandshakeException → noise (true)', () {
      expect(
        isHandledImageNetworkNoise(
          'image resource service',
          Exception('HandshakeException: Connection terminated during handshake'),
        ),
        isTrue,
      );
    });

    test('image-library SocketException / connection-reset → noise', () {
      expect(
        isHandledImageNetworkNoise(
          'image resource service',
          Exception('SocketException: Connection reset by peer'),
        ),
        isTrue,
      );
      expect(
        isHandledImageNetworkNoise(
          'image resource service',
          Exception('Failed host lookup: cdn.example.com'),
        ),
        isTrue,
      );
    });

    test('the SAME network error from a NON-image library is NOT noise', () {
      expect(
        isHandledImageNetworkNoise(
          'widgets library',
          Exception('HandshakeException: Connection terminated during handshake'),
        ),
        isFalse,
      );
      expect(
        isHandledImageNetworkNoise(
          null,
          Exception('HandshakeException: Connection terminated during handshake'),
        ),
        isFalse,
      );
    });

    test('a non-network image error (e.g. decode failure) still surfaces', () {
      expect(
        isHandledImageNetworkNoise(
          'image resource service',
          Exception('Invalid image data — failed to decode'),
        ),
        isFalse,
      );
    });
  });
}
