// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/route_live_progress_provider.dart';
import '../../providers/route_search_provider.dart';

/// Owns the foreground route-progress listener for the surface below it
/// (#4432).
///
/// Watching [routeLiveProgressControllerProvider] keeps the listener
/// alive exactly as long as a route surface is mounted; this widget
/// additionally pauses it when the surface is hidden (an offstage shell
/// tab turns tickers off) or the app leaves the foreground, and resumes
/// it when both are back. No listener is ever held for a route the
/// driver cannot see.
class RouteLiveProgressScope extends ConsumerStatefulWidget {
  const RouteLiveProgressScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RouteLiveProgressScope> createState() =>
      _RouteLiveProgressScopeState();
}

class _RouteLiveProgressScopeState
    extends ConsumerState<RouteLiveProgressScope> {
  late final AppLifecycleListener _lifecycle;
  bool _foreground = true;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (s) {
      _foreground = s == AppLifecycleState.resumed;
      _apply();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _visible) {
      _visible = visible;
      _apply();
    }
  }

  void _apply() {
    if (!mounted) return;
    final controller = ref.read(routeLiveProgressControllerProvider.notifier);
    if (_foreground && _visible) {
      controller.resume();
    } else {
      controller.pause();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(routeLiveProgressControllerProvider);
    return widget.child;
  }
}

/// "Update route from your position" — shown only when the foreground
/// fixes say the driver left the route or cannot be placed on it
/// (#4432). Tapping it re-runs the ACTIVE route request through the
/// current-location resolver; no fix ever does that by itself.
class RouteUpdateFromPositionBanner extends ConsumerWidget {
  const RouteUpdateFromPositionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(routeLiveProgressControllerProvider);
    if (!progress.needsRouteUpdate) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('route-update-from-position'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.wrong_location_outlined,
                color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.routeLeftRouteNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () => unawaited(
                  ref.read(routeSearchStateProvider.notifier).refresh()),
              child: Text(l10n.routeUpdateFromPosition),
            ),
          ],
        ),
      ),
    );
  }
}
