// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/storage_repository.dart';
import '../logging/app_log.dart';
import '../logging/error_logger.dart';
import '../telemetry/collectors/breadcrumb_collector.dart';
import 'supabase_client.dart';
import 'sync_config.dart';
import 'tanksync_init_retry.dart';
import 'tanksync_session_phase.dart';

/// One observation [TankSyncSessionGate] made: the phase [facts] describe,
/// what the gate found wrong with them, and which writer caused them.
typedef SessionObservation = ({
  String cause,
  SessionFacts facts,
  TankSyncSessionPhase phase,
  TankSyncSessionPhase? from,
  Set<SessionInvariant> broken,
});

/// A phase change [kTankSyncSessionTransitions] does not allow, or an
/// invariant a snapshot broke (#4162). Exactly one of [edge] and
/// [invariant] is set.
typedef SessionViolation = ({
  String cause,
  (TankSyncSessionPhase, TankSyncSessionPhase)? edge,
  SessionInvariant? invariant,
});

/// The one owner of TankSync's session lifecycle view (#4162).
///
/// Every writer of a session fact — the client's init and sign-out, the
/// launch init pass, the retry ladder, the settings writes the setup
/// screens make and the published `SyncConfig` — calls [observe] after
/// its write. The gate reads the facts, derives the phase with
/// [phaseOf], and compares:
///
/// * a snapshot that breaks a [SessionInvariant] is recorded as that
///   invariant, and no edge is measured from it;
/// * otherwise the change from the last lawful phase is checked against
///   [kTankSyncSessionTransitions].
///
/// Violations go to [debugViolations] (bounded) and to a breadcrumb, so
/// the next exported error log says which writer did what.
///
/// **Observe mode only.** The phase is derived, so there is nothing to
/// refuse. The `onAuthStateChange` subscription installed by [watchAuth]
/// records the session changes the SDK makes on its own — a refresh token
/// rejected mid-session was otherwise seen by nobody — and, since #4338,
/// hands a session the SDK dropped to the relink owner at once.
///
/// Never throws: it sits on the path of every client init and sign-out,
/// and a sync that cannot record its state must still sync.
class TankSyncSessionGate {
  TankSyncSessionGate();

  /// The app-wide gate.
  static final TankSyncSessionGate instance = TankSyncSessionGate();

  /// How many violations [debugViolations] keeps (newest win).
  static const int maxViolations = 16;

  final Queue<SessionViolation> _violations = Queue<SessionViolation>();
  StorageRepository? _storage;
  SyncConfig? _config;
  bool Function()? _relink;
  void Function()? _onSessionLost;
  TankSyncSessionPhase? _lastLawful;
  StreamSubscription<AuthState>? _authSub;
  int _initInFlight = 0;

  /// Test tap: every observation, in order.
  @visibleForTesting
  void Function(SessionObservation observation)? debugTap;

  /// The most recent violations, oldest first.
  List<SessionViolation> get debugViolations =>
      List<SessionViolation>.unmodifiable(_violations);

  /// The phase of the last lawful observation; null before the first.
  TankSyncSessionPhase? get phase => _lastLawful;

  /// Install the settings the facts are read from. Until this runs (the
  /// launch wiring, `LaunchSyncPhase.registerPulls`) [observe] records
  /// nothing.
  ///
  /// [relink] reads the relink owner (`TankSyncRelink`) directly, so the
  /// flag is current even before `SyncState` republishes. [onSessionLost]
  /// runs when the SDK drops the session on its own — before the
  /// observation, so the owner has flagged it by then (#4338).
  void bind(
    StorageRepository storage, {
    bool Function()? relink,
    void Function()? onSessionLost,
  }) {
    _storage = storage;
    _relink = relink;
    _onSessionLost = onSessionLost;
    observe('bind');
  }

  /// `SyncState` published [config]. Pushed by its listener rather than
  /// read on demand: reading the provider from here would rebuild it at
  /// moments the app never did.
  void observeConfig(SyncConfig config) {
    _config = config;
    observe('config');
  }

  /// A `TankSyncInit.run` pass started ([running] true) or ended.
  void initRunning(bool running, String cause) {
    _initInFlight = running
        ? _initInFlight + 1
        : (_initInFlight > 0 ? _initInFlight - 1 : 0);
    observe(cause);
  }

  /// Record the session changes the SDK makes on its own — read-only.
  /// Replaces any previous subscription (a re-initialised client has a
  /// new stream).
  void watchAuth(Stream<AuthState> events) {
    try {
      unawaited(_authSub?.cancel());
      _authSub = events.listen(
        (state) {
          // A user-initiated sign-out is observed by its writer
          // (`TankSyncClient.signOut`) once the client flag follows; the
          // event itself fires between the two and would read as a
          // session the SDK lost.
          if (state.event == AuthChangeEvent.signedOut &&
              state.signOutReason == SignOutReason.userInitiated) {
            return;
          }
          final reason = state.signOutReason;
          if (state.event == AuthChangeEvent.signedOut) _sessionLost();
          observe(reason == null
              ? 'auth:${state.event.name}'
              : 'auth:${state.event.name}(${reason.name})');
        },
        onError: (Object e, StackTrace st) {
          // The SDK reports retryable refresh failures (offline) as stream
          // errors. They change no session fact, so there is nothing to
          // observe — and an unhandled stream error would crash the zone.
          log.debug('TankSyncSessionGate: auth stream error: $e');
        },
      );
    } catch (e, st) {
      log.warn('TankSyncSessionGate: auth watch failed',
          error: e, stack: st, layer: ErrorLayer.sync);
    }
  }

  void _sessionLost() {
    try {
      _onSessionLost?.call();
    } catch (e, st) {
      log.warn('TankSyncSessionGate: session-lost hook failed',
          error: e, stack: st, layer: ErrorLayer.sync);
    }
  }

  /// Read the facts now and record what they say, on behalf of [cause].
  void observe(String cause) {
    try {
      final storage = _storage;
      if (storage == null) return;
      final facts = _read(storage);
      final phase = phaseOf(facts);
      final broken = {
        for (final i in SessionInvariant.values)
          if (!i.holdsFor(facts)) i,
      };
      final from = _lastLawful;
      for (final invariant in broken) {
        _record((cause: cause, edge: null, invariant: invariant));
      }
      if (broken.isEmpty) {
        if (from != null && !isTankSyncSessionTransition(from, phase)) {
          _record((cause: cause, edge: (from, phase), invariant: null));
        }
        _lastLawful = phase;
      }
      debugTap?.call((
        cause: cause,
        facts: facts,
        phase: phase,
        from: from,
        broken: broken,
      ));
    } catch (e, st) {
      log.warn('TankSyncSessionGate: observe failed',
          error: e, stack: st, layer: ErrorLayer.sync, context: {
        'cause': cause,
      });
    }
  }

  SessionFacts _read(StorageRepository storage) {
    final url = storage.getSetting('supabase_url') as String?;
    final config = _config;
    final sdkInitialized = TankSyncClient.sdkInitialized;
    return SessionFacts(
      syncEnabled: storage.getSetting('sync_enabled') as bool? ?? false,
      consent: storage.getSetting('consent_cloud_sync') as bool? ?? false,
      hasCredentials: url != null && storage.getSupabaseAnonKey() != null,
      configuredHost: url == null ? null : Uri.tryParse(url)?.host.toLowerCase(),
      clientInitialized: TankSyncClient.isInitialized,
      sdkInitialized: sdkInitialized,
      sdkHost: TankSyncClient.sdkHost,
      backendHost: TankSyncClient.backendHost,
      sessionUserId: TankSyncClient.sessionUserId,
      storedUserId: storage.getSetting('sync_user_id') as String?,
      relinkFlag: _relink?.call() ?? config?.relinkRequired ?? false,
      configEnabled: config?.enabled ?? false,
      initInFlight: _initInFlight > 0,
      retryPending: TankSyncInitRetry.instance.pending,
    );
  }

  void _record(SessionViolation violation) {
    _violations.addLast(violation);
    while (_violations.length > maxViolations) {
      _violations.removeFirst();
    }
    try {
      final edge = violation.edge;
      BreadcrumbCollector.add(
        edge != null
            ? 'sync session: illegal ${edge.$1.name}→${edge.$2.name}'
            : 'sync session: broke ${violation.invariant!.name}',
        detail: violation.cause,
      );
    } catch (e, st) {
      // The breadcrumb is a courtesy to the next export; the violation is
      // already in the ring above.
      log.warn('TankSyncSessionGate: breadcrumb failed',
          error: e, stack: st, layer: ErrorLayer.sync);
    }
  }

  /// Back to unbound — test isolation only.
  @visibleForTesting
  void resetForTest() {
    unawaited(_authSub?.cancel());
    _authSub = null;
    _storage = null;
    _config = null;
    _relink = null;
    _onSessionLost = null;
    _lastLawful = null;
    _initInFlight = 0;
    _violations.clear();
    debugTap = null;
  }
}
