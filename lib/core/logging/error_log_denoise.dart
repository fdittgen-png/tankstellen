// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';

/// Pure classifiers that decide whether an error reaching the global
/// `FlutterError.onError` / `PlatformDispatcher.onError` handlers is benign
/// noise that must NOT be recorded as a crash.
///
/// Extracted from `app_initializer.dart` (#3311) so the handler-installation
/// site stays small and each predicate is independently unit-testable. They
/// are deliberately conservative: each only swallows a narrow, well-understood
/// class of transient failure, so a genuine bug still surfaces in the log.

/// Whether [error] is a transient network failure from the OSM tile pipeline.
/// flutter_map's `RetryNetworkTileProvider` already retries and shows an error
/// tile; the global error log shouldn't also record these as crashes — they
/// pollute the report with offline / flaky-network noise (17 entries in a
/// single session on a mobile device, observed 2026-05-27). Cancellation
/// aborts (#930) are classed as noise too.
bool isTileFetchNoise(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('tile.openstreetmap.org')) return true;
  // SocketException with a host-lookup failure on any host is offline noise.
  // The wrapping FlutterError shows it as "Failed host lookup".
  if (msg.contains('failed host lookup')) return true;
  return false;
}

/// #3311 — a network failure loading a network image (brand logos via
/// `cached_network_image`) is reported to `FlutterError.onError` with
/// `library == 'image resource service'`, even though the widget's
/// `errorWidget`/`errorBuilder` already handled it for display (the station
/// card shows the fallback pump glyph). These are transient connectivity
/// failures, never app bugs — on a flaky mobile network a single session
/// logged 23 `HandshakeException`s from brand-logo loads. Filter them out of
/// the error log like the tile-fetch + failed-host-lookup noise, but ONLY for
/// the image library + a network-class exception, so a genuine image-decode
/// bug still surfaces.
bool isHandledImageNetworkNoise(String? library, Object error) {
  if (library != 'image resource service') return false;
  final msg = error.toString().toLowerCase();
  return msg.contains('handshakeexception') ||
      msg.contains('socketexception') ||
      msg.contains('connection terminated') ||
      msg.contains('connection closed') ||
      msg.contains('connection reset') ||
      msg.contains('connection refused') ||
      msg.contains('connection abort') ||
      msg.contains('failed host lookup') ||
      msg.contains('httpexception') ||
      msg.contains('clientexception') ||
      msg.contains('timeoutexception');
}

/// Benign EventChannel teardown ("No active stream to cancel"), a lifecycle
/// race that safeCancel covers at app sites but can escape via plugins —
/// never a real crash, must not pollute the error log (#2772).
bool isBenignStreamCancel(Object error) =>
    error is PlatformException &&
    (error.message?.toLowerCase().contains('no active stream to cancel') ??
        false);
