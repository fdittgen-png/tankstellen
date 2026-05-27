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
/// notVisibleRespectMargin` + the upstream-default
/// `abortObsoleteRequests: true` + a wider `keepBuffer` (4)
/// together cover the four documented grey-tile pathologies:
///
/// 1. OSM transient HTTP 429 / 5xx — provider retries 3× with
///    jittered backoff.
/// 2. flutter_map's pan-fetch race — `abortObsoleteRequests: true`
///    (upstream default, restored in #2122) cancels in-flight tile
///    requests for off-screen coordinates so visible tiles aren't
///    starved by a backlog. The retry provider's
///    `_isCancellation` guard makes the cancellations a no-op for
///    the retry loop.
/// 3. The error-tile cache trap — `notVisibleRespectMargin` evicts
///    failed tiles once off-screen so the next pan retries cleanly.
/// 4. The grey-while-loading symptom — `keepBuffer: 4` keeps the
///    previous level's painted tiles on screen until the new
///    fetches resolve, so a slow connection doesn't show grey
///    squares during the swap.
/// 5. The cold-start camera-settled race — the optional [reset]
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
    // #2122 — restored to the upstream default (`true`). The earlier
    // override to `false` (added in #2097) turned out to amplify the
    // grey-tile symptom rather than fix it: requests for tiles that
    // had already panned out of view stayed in the queue, competing
    // with the visible tiles for bandwidth and producing the user-
    // reported "loading process gets cut" effect. The retry
    // provider's `_isCancellation` guard already makes mid-fetch
    // aborts a no-op for the retry loop, so reverting to `true`
    // gives bandwidth back to the tiles the user is actually
    // looking at without compromising transient-failure recovery.
    // Explicit `true` satisfies the #930 lint
    // (`test/lint/retry_tile_provider_call_site_test.dart`) that
    // forbids implicit defaults — every call site must be intentional
    // about this parameter.
    _tileProvider = RetryNetworkTileProvider(abortObsoleteRequests: true);
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
      // #2122 — keep the previous level's already-loaded tiles
      // painted while the new ones fetch. flutter_map's default is
      // 2; bumping to 4 covers a wider corona around the visible
      // viewport so a slow connection or a quick pan doesn't expose
      // a grey ring. `panBuffer` deliberately stays at its default
      // (1) — the flutter_map docs explicitly warn that raising it
      // slows the visible tile fetches and adds load to OSM.
      keepBuffer: 4,
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
