// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/perf/startup_timer.dart';
import '../../features/widget/providers/pending_widget_uri_provider.dart';

/// What `AppInitializer.run` waits for before the real app, written as the
/// data dependencies it actually has (#4319).
///
/// The launch used to be a row of phases — dates, then storage, then
/// services, then container, then the widget probe — and each phase
/// boundary was a serial barrier whether or not a real dependency sat
/// there. The widget probe needs no Hive, no key and no container, yet it
/// started last and could add most of its 200 ms cap as a tail; the
/// default-profile seed needs only the core boxes, yet it waited for the
/// slowest telemetry initialiser.
///
/// This is deliberately NOT a scheduler: a handful of named futures whose
/// start order is the dependency graph. Every task carries one of five
/// dependency classes, stated where it is started so a new task has to
/// pick one:
///
/// * **route-critical** — must complete before the router builds.
/// * **storage-safety critical** — must complete before any user data is
///   consumed; a failure stops the real app and mounts recovery.
/// * **inbound-launch critical** — must complete before the first
///   redirect / navigation.
/// * **first-use critical** — may start early; must complete only before
///   a specific reader (here: before `errorLogger.bind` makes the trace
///   box live).
/// * **runtime housekeeping** — after the first real frame
///   (`RuntimeServicesPhase`, #4317).
///
/// Each task is recorded as a span on the startup timeline, so an export
/// shows that the overlap is real rather than inferred from a total.
abstract final class LaunchCriticalPath {
  /// Runs the launch prerequisites and returns the container the app is
  /// launched with — or `null` when the storage verdict failed, in which
  /// case a recovery screen is already mounted and nothing else may run.
  ///
  /// The container is created only after BOTH the storage verdict and the
  /// widget-launch answer (or its timeout), and the widget URI is committed
  /// to [pendingWidgetUriProvider] before it is returned — so the router's
  /// first redirect can consume it.
  static Future<ProviderContainer?> run({
    required Future<Uri?> Function() probeWidgetLaunch,
    required Future<bool> Function() storage,
    required Future<void> Function() dateFormatting,
    required ProviderContainer Function() createContainer,
  }) async {
    // Inbound-launch critical, no prerequisites: started first so its
    // 200 ms cap runs while storage works instead of after it. Never
    // throws (see WidgetLaunchProbe).
    final widgetUri = spanned('widget_launch_probe', probeWidgetLaunch);

    // Storage-safety critical. Started before date formatting on purpose:
    // its synchronous prefix hands the directory lookup to the platform,
    // and the formatting work below runs while that is in flight.
    final storageOk = spanned('storage_phase', storage);

    // Route-critical (first-frame `DateFormat` readers, see #4319 audit in
    // AppInitializer): `initializeDateFormatting` does its work
    // synchronously and returns a completed future, so starting it here —
    // not before storage — is the whole of the overlap it can have.
    // Its outcome is captured NOW: a failure while storage is still being
    // awaited would otherwise have no listener and escape uncaught.
    final dates = spanned('date_formatting', dateFormatting)
        .then<(Object, StackTrace)?>((_) => null,
            onError: (Object e, StackTrace st) => (e, st));

    if (!await storageOk) {
      // A recovery screen is up. The probe never throws and the formatting
      // outcome is captured, so nothing surfaces uncaught.
      return null;
    }
    StartupTimer.instance.mark('storage_ready');
    if (await dates case (final error, final stack)) {
      Error.throwWithStackTrace(error, stack);
    }
    final uri = await widgetUri;

    final container = createContainer();
    if (uri != null) container.read(pendingWidgetUriProvider.notifier).set(uri);
    return container;
  }

  /// The storage phase as a graph (#4319): the core boxes first, then
  /// everything that only needs them, in parallel.
  ///
  /// `Future.wait` waits for every task even when one fails and then
  /// rethrows the first error, so a failure here never leaves a sibling's
  /// error unhandled, and the storage gate still sees it.
  static Future<void> storagePhase({
    required Future<void> Function() openBoxes,
    required Future<void> Function() loadApiKeys,
    required Future<void> Function() seedDefaultProfile,
    required Map<String, Future<void> Function()> telemetry,
  }) async {
    // Storage-safety critical: key check, migration and the first-frame
    // boxes. Nothing below may observe a partially opened store.
    await spanned('open_boxes', openBoxes);
    await Future.wait<void>([
      // Route-critical: the search landing reads `hasApiKey` synchronously
      // from the in-memory key cache. Owns secure storage and the settings
      // key `supabase_anon_key`.
      spanned('api_keys', loadApiKeys),
      // Route-critical: the landing resolves the active profile. Owns the
      // `profiles` box and the settings key `active_profile_id` — disjoint
      // from every other task here, so no ordering edge is needed.
      spanned('default_profile', seedDefaultProfile),
      // First-use critical: each opens its OWN box (error_traces,
      // obd2_connect_traces, health_counters) and must be done before
      // `errorLogger.bind` routes a trace into it.
      for (final MapEntry(key: name, value: init) in telemetry.entries)
        spanned(name, init),
    ]);
  }

  /// Runs [body] as a span named [name] on the startup timeline.
  static Future<T> spanned<T>(String name, Future<T> Function() body) {
    final timer = StartupTimer.instance;
    final startMs = timer.elapsedMsNow();
    return Future<T>.sync(body).whenComplete(() => timer.addSpan(name,
        startMs: startMs, endMs: timer.elapsedMsNow()));
  }
}
