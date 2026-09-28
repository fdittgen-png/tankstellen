// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/foreground_fix_tracker.dart';
import '../../../../core/location/geolocator_wrapper.dart';
import '../../../../core/location/position_fix_policy.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../l10n/app_localizations.dart';

/// The route map's "you are here" dot — drawn ONLY from a fresh,
/// accepted GPS fix (#4432).
///
/// The route map used to paint its position-looking circle at the
/// camera centre, which is the bounding-box centre of the found
/// stations. This layer is the honest replacement: it owns one
/// non-recording subscription to the shared position stream for as long
/// as it is on screen, validates every sample (a replayed or cached fix
/// is judged by its own timestamp), and draws nothing when no current
/// fix exists. It is a layer of its own so the map has three separate
/// inputs — camera target, route endpoints, device fix — that can no
/// longer be confused.
///
/// Lifecycle-owned: subscribed while mounted and the app is visible,
/// released on hidden / paused and on dispose. The map tab's structural
/// gate (#1605) unmounts the whole route map when the tab is hidden, so
/// leaving the surface releases GPS too. It never starts a search.
class RouteDeviceFixLayer extends ConsumerStatefulWidget {
  const RouteDeviceFixLayer({super.key});

  @override
  ConsumerState<RouteDeviceFixLayer> createState() =>
      _RouteDeviceFixLayerState();
}

class _RouteDeviceFixLayerState extends ConsumerState<RouteDeviceFixLayer>
    with WidgetsBindingObserver {
  late final ForegroundFixTracker _tracker;

  @override
  void initState() {
    super.initState();
    final geolocator = ref.read(geolocatorWrapperProvider);
    _tracker = ForegroundFixTracker(
      open: () => geolocator.sharedPositionStream(
        locationSettings: kForegroundFixSettings,
      ),
      clock: ref.read(appClockProvider),
    )..start();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_tracker.stop());
      case AppLifecycleState.resumed:
        _tracker
          ..revalidate()
          ..start();
      case AppLifecycleState.inactive:
        // A notification-shade swipe: still visible, keep listening.
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tracker.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AcceptedDeviceFix?>(
      valueListenable: _tracker.fix,
      builder: (context, fix, _) {
        if (fix == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final accuracy = fix.accuracyMeters;
        // Passthrough: both layers lay out exactly as direct FlutterMap
        // children would.
        return Stack(
          fit: StackFit.passthrough,
          children: [
            if (accuracy != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: fix.position,
                    radius: accuracy,
                    useRadiusInMeter: true,
                    color: scheme.tertiary.withValues(alpha: 0.12),
                    borderColor: scheme.tertiary.withValues(alpha: 0.4),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  key: const ValueKey('device-fix-marker'),
                  point: fix.position,
                  width: 18,
                  height: 18,
                  child: Semantics(
                    label:
                        AppLocalizations.of(context).routeMapDeviceFixMarker,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
