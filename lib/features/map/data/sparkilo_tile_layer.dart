// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/constants/app_constants.dart';
import 'retry_network_tile_provider.dart';

/// Drop-in `TileLayer` wrapper that wires every OSM tile fetch
/// through [RetryNetworkTileProvider] with the hardened config —
/// the only legitimate way to instantiate a TileLayer in this
/// codebase (#2096).
///
/// ## Why this widget exists
///
/// `RetryNetworkTileProvider` + `evictErrorTileStrategy:
/// notVisibleRespectMargin` + `abortObsoleteRequests: false`
/// together cover the four documented grey-tile pathologies:
///
/// 1. OSM transient HTTP 429 / 5xx — provider retries 3× with
///    jittered backoff.
/// 2. flutter_map's rebuild-abort race — provider declines to
///    re-fire on cancellations, and `abortObsoleteRequests: false`
///    keeps in-flight fetches alive across rebuilds.
/// 3. The error-tile cache trap — `notVisibleRespectMargin` evicts
///    failed tiles once off-screen so the next pan retries cleanly.
/// 4. The cold-start camera-settled race — the optional [reset]
///    stream lets a parent fire a tile reset when its layout
///    settles (used by `station_map_layers.dart`).
///
/// Prior to this widget, 6 of 7 TileLayer call sites in `lib/`
/// instantiated `TileLayer` directly with the **default**
/// `NetworkTileProvider`. The trip-detail, trajets, driving, and
/// alert-radius maps all rendered grey when the user hit a
/// transient OSM glitch. Every "fix" since #757 patched the main
/// map in isolation. The recurring-bug protocol called for an
/// architectural solution — every map surface goes through the
/// same hardened path.
///
/// ## Lifecycle (#1234 invariant — DO NOT regress)
///
/// The retry provider OWNS an [http.Client] that must live for the
/// entire visible lifetime of the TileLayer. Recreating it on
/// every build churns clients and produces a different cold-start
/// race. This widget holds the provider in [State] (created in
/// `initState`, disposed in `dispose`) so the http.Client identity
/// is stable across parent rebuilds.
///
/// ## Usage
///
/// Drop-in replacement for the raw `TileLayer` constructor — a
/// single line in place of the prior 4-line setup with
/// `urlTemplate`, `userAgentPackageName`, and
/// `evictErrorTileStrategy`. See `station_map_layers.dart` for the
/// reference inline setup the wrapper consolidates.
///
/// Custom OSM endpoints (e.g. self-hosted) override [urlTemplate].
/// Routes that need to force a tile reset on layout-settle pass a
/// broadcast stream via [reset]; most callers leave it null.
class SparkiloTileLayer extends StatefulWidget {
  /// OSM tile-URL template. Defaults to [AppConstants.osmTileUrl].
  final String? urlTemplate;

  /// User-Agent header per OSM tile-usage policy. Defaults to
  /// [AppConstants.osmUserAgent].
  final String? userAgentPackageName;

  /// Highest zoom level with real tiles (OSM caps at 19). Cameras
  /// that overzoom past this still render — flutter_map upsamples
  /// from the deepest available level — but going past 19 starts
  /// to look pixelated.
  final int maxNativeZoom;

  /// Hard cap on the camera zoom. Aligned with [maxNativeZoom] so
  /// a programmatic over-zoom doesn't park the user on a grey
  /// viewport with no tiles to draw.
  final double maxZoom;

  /// Broadcast stream that, when emitted, makes the underlying
  /// [TileLayer] drop all current tile images and re-fetch the
  /// visible range. Used by `station_map_layers.dart` to defeat
  /// the cold-start race when the camera settles after the first
  /// frame. Most callers can leave this null.
  final Stream<void>? reset;

  const SparkiloTileLayer({
    super.key,
    this.urlTemplate,
    this.userAgentPackageName,
    this.maxNativeZoom = 19,
    this.maxZoom = 19,
    this.reset,
  });

  @override
  State<SparkiloTileLayer> createState() => _SparkiloTileLayerState();
}

class _SparkiloTileLayerState extends State<SparkiloTileLayer> {
  late final RetryNetworkTileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    // `abortObsoleteRequests: false` is critical — flutter_map's
    // default (true) aborts in-flight tile HTTP requests when the
    // widget rebuilds. Combined with the provider's
    // cancellation-aware retry logic, false keeps fetches alive
    // through the rebuild churn.
    _tileProvider = RetryNetworkTileProvider(abortObsoleteRequests: false);
  }

  @override
  void dispose() {
    _tileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: widget.urlTemplate ?? AppConstants.osmTileUrl,
      userAgentPackageName:
          widget.userAgentPackageName ?? AppConstants.osmUserAgent,
      maxNativeZoom: widget.maxNativeZoom,
      maxZoom: widget.maxZoom,
      tileProvider: _tileProvider,
      reset: widget.reset,
      evictErrorTileStrategy:
          EvictErrorTileStrategy.notVisibleRespectMargin,
      errorTileCallback: (tile, error, stackTrace) {
        // Same as `station_map_layers.dart` — visible in device
        // logs but not in production user UI. Mode B (silent
        // exhaustion + tap-to-retry) is a follow-up per #2096.
        if (kDebugMode) {
          debugPrint(
              'SparkiloTileLayer: tile error at (z:${tile.coordinates.z} '
              'x:${tile.coordinates.x} y:${tile.coordinates.y}): $error');
        }
      },
    );
  }
}
