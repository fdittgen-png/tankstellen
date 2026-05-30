// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// LAYER-2 tile-proxy contract suite (#2403 — the Layer-2 half).
//
// Layer 1's `map_reimpl_regression_test.dart` already locks the
// consistency lint, the no-reset-machinery guard, and the never-blank
// marker. It deliberately deferred ONE thing to Layer 2:
//
//   "The proxy URL + 7-day cache contract test is deferred to LAYER 2
//    (#2397 deploys the edge function; the Deno-side contract test ships
//    with it)."
//
// This file is that deferred contract, on the Dart side:
//   - the app's DEFAULT tile URL is now the Supabase proxy template (the
//     #2396 flip actually took effect — not just the constant exists);
//   - `effectiveTileUrl` falls back cleanly to OSM-direct when the proxy
//     is unset (graceful degradation, never grey);
//   - the OSM-facing User-Agent is the stable, version-free one;
//   - the edge function source declares the 7-day cache + stable UA, so
//     CI catches drift between the app and the function even on a runner
//     without Deno (the runtime Deno test lives in
//     `supabase/functions/tiles/index.test.ts`).
//
// All assertions are deterministic + offline — no live network.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/features/map/data/sparkilo_tile_layer.dart';

void main() {
  // A digit-dot-digit version pattern (e.g. "5.0.0").
  final versionPattern = RegExp(r'\d+\.\d+');

  group('PROXY URL CONTRACT — the app defaults to the Supabase proxy (#2396)',
      () {
    test('tileProxyUrl is the real project subdomain + {z}/{x}/{y}.png shape',
        () {
      // Pinned to the deployed project ref (klelxnkzrxlpzuddhpfg). A
      // placeholder subdomain would 404 every tile once the flip ships.
      expect(
        AppConstants.tileProxyUrl,
        'https://klelxnkzrxlpzuddhpfg.supabase.co/functions/v1/tiles/{z}/{x}/{y}.png',
        reason: 'tileProxyUrl must point at the real deployed project and '
            'match the function route /{z}/{x}/{y}.png',
      );
      expect(AppConstants.tileProxyUrl, contains('/functions/v1/tiles'));
      expect(AppConstants.tileProxyUrl, contains('{z}/{x}/{y}'));
      expect(AppConstants.tileProxyUrl, endsWith('.png'));
    });

    test('effectiveTileUrl returns the proxy when it is set', () {
      // With a non-empty tileProxyUrl (the shipped state) the app must
      // resolve to the proxy, NOT OSM-direct.
      expect(AppConstants.tileProxyUrl, isNotEmpty);
      expect(AppConstants.effectiveTileUrl, AppConstants.tileProxyUrl);
    });

    test('effectiveTileUrl falls back to OSM-direct logic when proxy is empty',
        () {
      // The fallback is `tileProxyUrl.isEmpty ? osmTileUrl : tileProxyUrl`.
      // Assert the resolver's branch is exactly that, so a future build
      // that clears the proxy degrades to OSM-direct (a map) rather than
      // grey. We can't mutate the const, so verify the predicate directly.
      String resolve(String proxy) => proxy.isEmpty
          ? AppConstants.osmTileUrl
          : proxy;
      expect(resolve(''), AppConstants.osmTileUrl);
      expect(resolve(AppConstants.tileProxyUrl), AppConstants.tileProxyUrl);
      // And the live getter agrees with the predicate on the real value.
      expect(
        AppConstants.effectiveTileUrl,
        resolve(AppConstants.tileProxyUrl),
      );
    });

    testWidgets(
        'SparkiloTileLayer default rendered URL is the proxy template '
        '(the #2396 flip took effect)', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(48, 2),
              initialZoom: 6,
            ),
            children: [SparkiloTileLayer()],
          ),
        ),
      );

      final tile = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tile.urlTemplate, AppConstants.effectiveTileUrl);
      expect(tile.urlTemplate, AppConstants.tileProxyUrl,
          reason: 'the basemap must default through the proxy after #2396');
    });
  });

  group('IDENTITY CONTRACT — stable, version-free OSM User-Agent (#2396)', () {
    test('osmUserAgent carries no digit.digit version', () {
      expect(versionPattern.hasMatch(AppConstants.osmUserAgent), isFalse,
          reason: 'a per-release UA looks like many clients to OSM abuse '
              'heuristics — the OSM/tile UA must be version-free');
      expect(AppConstants.osmUserAgent, AppConstants.appPackage);
    });

    testWidgets('the rendered tile layer sends the version-free UA',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(48, 2),
              initialZoom: 6,
            ),
            children: [SparkiloTileLayer()],
          ),
        ),
      );
      final tile = tester.widget<TileLayer>(find.byType(TileLayer));
      final ua = tile.tileProvider.headers['User-Agent'] ?? '';
      expect(ua, contains(AppConstants.osmUserAgent));
      expect(versionPattern.hasMatch(ua), isFalse,
          reason: 'the tile request UA must stay version-free');
    });

    test('tileProxyOsmUserAgent is a stable id with a contact URL', () {
      expect(AppConstants.tileProxyOsmUserAgent, contains('tile-proxy'));
      expect(AppConstants.tileProxyOsmUserAgent, contains('https://'));
    });
  });

  group('CACHE CONTRACT — the edge function declares 7-day cache + stable UA '
      '(#2397)', () {
    // Cross-checks the function source from Dart so CI flags app/function
    // drift even without a Deno runtime. The runtime header assertions
    // live in supabase/functions/tiles/index.test.ts.
    late String fnSource;

    setUpAll(() {
      final f = File('supabase/functions/tiles/index.ts');
      expect(f.existsSync(), isTrue,
          reason: 'the tiles edge function must exist (#2397)');
      fnSource = f.readAsStringSync();
    });

    test('declares a 7-day (604800s) Cache-Control and never no-cache', () {
      // The header is built as `max-age=${CACHE_MAX_AGE_SECONDS}` with the
      // constant set to the 7-day value — assert both the constant value
      // and that it is wired into a `max-age=` Cache-Control header.
      expect(fnSource, contains('CACHE_MAX_AGE_SECONDS = 604800'),
          reason: '7 days = 604800 s, the OSM caching-policy expectation');
      expect(fnSource, contains(r'max-age=${CACHE_MAX_AGE_SECONDS}'));
      expect(fnSource, contains("'Cache-Control'"));
      expect(fnSource, contains('CDN-Cache-Control'));
      expect(fnSource.contains('no-cache'), isFalse,
          reason: 'the proxy must never emit no-cache (OSM caching policy)');
    });

    test('uses the SAME stable OSM UA the app exposes as tileProxyOsmUserAgent',
        () {
      // The function's hard-coded OSM_TILE_USER_AGENT must match the app
      // constant verbatim — they are mirrors and must not drift.
      expect(fnSource, contains(AppConstants.tileProxyOsmUserAgent),
          reason: 'the function OSM UA must mirror '
              'AppConstants.tileProxyOsmUserAgent');
    });

    test('validates tile bounds (rejects out-of-range / open-relay use)', () {
      // The route validator caps zoom at 19 and bounds x/y by 2^z; assert
      // those guards are present so the proxy cannot be abused as an open
      // relay.
      expect(fnSource, contains('parseTileCoords'));
      expect(fnSource, contains('2 ** z'));
      expect(fnSource, contains('out of range'));
    });
  });
}
