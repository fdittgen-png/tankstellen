// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../core/logging/error_logger.dart';
import '../../core/perf/startup_timer.dart';

/// The platform-plugin and scheduler housekeeping that used to gate the
/// real app (#4317).
///
/// `AppInitializer.run` awaited these three before `_launch`, in one
/// `Future.wait` — concurrent, but the slowest of them still decided when
/// the user left the splash. None of them builds the first route:
///
/// * **notifications** — plugin init + Android channel creation. A cold
///   notification launch is read through `getNotificationAppLaunchDetails`,
///   which does not need it; a warm tap that arrives before it finishes is
///   collected by `NotificationLaunchLedger`.
/// * **background** — `BackgroundService.reconcile` (WorkManager / BGTask
///   registration, notification templates, the iOS SLC monitor) and then
///   the #3169 opportunistic cold-launch scan. Kept in that order: the iOS
///   one-off is registered through the Workmanager instance `reconcile`
///   initialises.
/// * **home widget** — the outcome of `HomeWidget.setAppGroupId`. The CALL
///   is sent before launch by `AppInitializer.run` (a [SentPlatformCall]);
///   only waiting for its answer lives here.
///
/// ## Dependency class: runtime housekeeping
///
/// Everything here runs from a post-frame callback registered after
/// `errorLogger.bind`, so a failure reports through the foreground trace
/// pipeline rather than the pre-bind isolate spool. Each service is
/// isolated: one failing never cancels another, and none escapes as an
/// uncaught async error.
///
/// The iOS opportunistic scan must use the foreground window a cold launch
/// grants, so this is scheduled on the next post-frame callback after the
/// handoff — never on a timer.
@immutable
class RuntimeServices {
  const RuntimeServices({
    required this.initNotifications,
    required this.reconcileBackground,
    required this.opportunisticWake,
    required this.homeWidgetSetup,
  });

  /// `LocalNotificationService().initialize`.
  final Future<void> Function() initNotifications;

  /// `BackgroundService.reconcile`.
  final Future<void> Function() reconcileBackground;

  /// `BackgroundService.onOpportunisticWake`.
  final Future<void> Function() opportunisticWake;

  /// Resolves the home-widget group-id call sent before launch.
  final Future<void> Function() homeWidgetSetup;
}

/// Runs [RuntimeServices] after the first real frame (#4317).
abstract final class RuntimeServicesPhase {
  /// The span this phase records on the startup timeline. A span and not a
  /// milestone: `StartupTimer.mark` is a no-op once `first_frame` stopped
  /// the stopwatch, which is before this can run.
  static const String spanName = 'runtime_services_deferred';

  static bool _scheduled = false;

  /// Schedules [run] on the next post-frame callback — once per process.
  ///
  /// `_launch` calls this right after `errorLogger.bind`, in the same
  /// synchronous block as `runApp`, so nothing here starts before the real
  /// app is handed to the framework. A post-frame callback rather than a
  /// microtask, which can drain before the first paint. The once-per-process guard is what keeps a relaunch
  /// path from initialising the plugins twice; the widget tree never
  /// schedules this, so a rebuild or a language change cannot either.
  static void scheduleAfterFirstFrame(RuntimeServices services) {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance
        .addPostFrameCallback((_) => unawaited(run(services)));
  }

  /// Test isolation only.
  @visibleForTesting
  static void resetForTest() => _scheduled = false;

  /// Runs every service, isolated from the others. Never throws.
  static Future<void> run(RuntimeServices services) async {
    final timer = StartupTimer.instance;
    final startMs = timer.elapsedMsNow();
    final durations = <String, Object?>{};

    Future<void> isolated(String service, Future<void> Function() body) async {
      final serviceStart = timer.elapsedMsNow();
      try {
        await body();
      } catch (e, st) {
        await errorLogger.log(ErrorLayer.background, e, st,
            context: {'where': 'runtimeServices', 'service': service});
      } finally {
        durations['${service}Ms'] = timer.elapsedMsNow() - serviceStart;
      }
    }

    await Future.wait<void>([
      isolated('notifications', services.initNotifications),
      () async {
        await isolated('background', services.reconcileBackground);
        await isolated('opportunistic_wake', services.opportunisticWake);
      }(),
      isolated('home_widget', services.homeWidgetSetup),
    ]);
    timer.addSpan(spanName,
        startMs: startMs, endMs: timer.elapsedMsNow(), attributes: durations);
  }
}

/// A platform call that must be SENT now but whose answer is only
/// reported later (#4317).
///
/// Method-channel messages are delivered to the platform in send order,
/// so sending `HomeWidget.setAppGroupId` before launch is what guarantees
/// that no later widget write reaches the iOS plugin ahead of it. Awaiting
/// the answer is not needed for that, and a stuck plugin must not hold the
/// splash. The outcome is captured the moment the call is made: an error
/// with no listener attached yet would otherwise surface as an uncaught
/// async error long before [rethrowFailure] is called.
class SentPlatformCall {
  /// Sends [call] immediately and captures its outcome.
  SentPlatformCall(Future<void> Function() call)
      : _outcome = Future<void>.sync(call).then<(Object, StackTrace)?>(
            (_) => null,
            onError: (Object e, StackTrace st) => (e, st));

  final Future<(Object, StackTrace)?> _outcome;

  /// Completes when the call has answered; rethrows its failure, if any,
  /// with the original stack.
  Future<void> rethrowFailure() async {
    final failure = await _outcome;
    if (failure != null) Error.throwWithStackTrace(failure.$1, failure.$2);
  }
}
