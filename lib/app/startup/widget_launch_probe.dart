// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:home_widget/home_widget.dart';

import '../../core/logging/error_logger.dart';
import '../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../features/widget/data/home_widget_service.dart';
import 'runtime_services_phase.dart';

/// The home-widget cold-launch probe, startable before anything else
/// (#4319).
///
/// It asks the `home_widget` plugin which URI launched the app, so the
/// router's first redirect can open the station directly instead of
/// flashing the landing screen. It needs no Hive, no key and no provider
/// container, and it used to run LAST — after storage, services and the
/// container — so a slow-but-valid answer could add most of its 200 ms
/// cap to every launch as a serial tail.
///
/// ## Group id before probe? No — but it is still sent first
///
/// `initiallyLaunchedFromHomeWidget` does not read the group id on either
/// platform (`home_widget` 0.9.4: Android answers from the activity intent,
/// iOS from the URL it was opened with; the Dart side sends no group id
/// argument). `setAppGroupId` IS needed before any widget WRITE on iOS, and
/// method-channel messages reach the platform in send order — so it is
/// sent first, and neither waits for the other. `widget_launch_probe_test`
/// executes both halves against the real plugin API.
///
/// ## Why nothing here reports before the bind
///
/// This starts before storage. An `errorLogger.log` now would take the
/// pre-bind path and lazily create the isolate spool's box FILE — before
/// `HiveCipherLoader` has inspected the box files. Under #4118 that stray
/// file read as "box files exist but the key is new" and stopped a fresh
/// install with a false key-loss screen; #4341 reads frame checksums, so a
/// plaintext spool is no longer evidence, but storage is still not up. So
/// failures are HELD and reported by [reportAfterBind].
class WidgetLaunchProbe {
  WidgetLaunchProbe({
    Future<void> Function()? setGroupId,
    Future<Uri?> Function()? readLaunchUri,
    this.cap = defaultCap,
  })  : _setGroupId = setGroupId ?? HomeWidgetService.init,
        _readLaunchUri =
            readLaunchUri ?? HomeWidget.initiallyLaunchedFromHomeWidget;

  /// The safety cap on the probe — unchanged from before #4319. A stuck
  /// plugin still costs at most this, and on a normal launch storage hides
  /// most or all of it.
  static const Duration defaultCap = Duration(milliseconds: 200);

  final Duration cap;
  final Future<void> Function() _setGroupId;
  final Future<Uri?> Function() _readLaunchUri;

  SentPlatformCall? _groupId;
  bool _timedOut = false;
  (Object, StackTrace)? _failure;

  /// The group-id call. Null before [start].
  SentPlatformCall? get groupId => _groupId;

  /// Completes once the group-id call has answered, rethrowing its
  /// failure — the runtime phase's home-widget slot (#4317).
  Future<void> groupIdAnswered() async => _groupId?.rethrowFailure();

  /// Sends the group id, then asks for the launch URI. Never throws: a
  /// timeout or plugin error answers `null`, and the warm-click stream
  /// still delivers the URI a few frames later.
  Future<Uri?> start() async {
    _groupId = SentPlatformCall(_setGroupId);
    try {
      return await Future<Uri?>.sync(_readLaunchUri).timeout(cap);
    } on TimeoutException {
      _timedOut = true;
      return null;
    } catch (e, st) {
      _failure = (e, st);
      return null;
    }
  }

  /// Reports what [start] held back. Call once `errorLogger` is bound.
  Future<void> reportAfterBind() async {
    if (_timedOut) {
      // Expected benign race — a breadcrumb, not an ERROR trace.
      BreadcrumbCollector.add('widget-launch-probe-timeout',
          detail: '${cap.inMilliseconds}ms — falling back to the '
              'warm-click stream');
    }
    final failure = _failure;
    if (failure != null) {
      await errorLogger.log(ErrorLayer.other, failure.$1, failure.$2,
          context: const {'where': 'stashWidgetLaunchUri'});
    }
  }
}
