// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';

/// #3422 (epic #3415) — detects a WEDGED Classic adapter and bounds the
/// reconnect storm.
///
/// Field evidence (#3415, 2026-07-02): a vLinker FS whose single SPP channel
/// stops accepting re-opens makes every RFCOMM ladder run end in
/// `exhausted` / `budget-exhausted`, yet the reconnect authorities kept
/// dialling — 1479 connect attempts in one day, one native call blocked
/// 16.8 minutes. Per #3404 there is no silent in-code un-wedge on API 31+,
/// so once the signature repeats the only useful moves are the recovery
/// rungs (`Obd2WedgeRecovery`) — every further ordinary connect cycle is
/// battery burn that keeps the adapter's channel busy.
///
/// The rule: [threshold] (=3) CONSECUTIVE Classic connect calls ending in a
/// wedge-signature terminal strategy flip [linkWedged] true. The single
/// funnel that observes every Classic ladder outcome — for BOTH the idle
/// #3019 controller and the in-trip scanner/connector — is
/// `ClassicElmChannel.open()`, which calls [noteClassicLadderOutcome].
///
/// While wedged:
///  * `Obd2LinkArbiter` stops routing drops to the idle policy and refuses
///    new `autoRecord` leases (loops stand down; user gestures still pass);
///  * `buildReconnectScannerFactory` (in-trip) returns no scanner;
///  * the `Obd2WedgeRecovery` ladder — kicked off via [onWedged] — owns the
///    link until a rung succeeds, the adapter answers a connect again, or
///    the user acts (the rung-4 hint / a manual retry).
///
/// Exits: any SUCCESSFUL Classic connect (the adapter reappeared), or
/// [noteRecovered] from a recovery rung. Both reset the streak.
///
/// Process-wide singleton for the same reason as the arbiter/cooldown it
/// sits beside: the channels are constructed deep inside the facade per
/// attempt, so the streak must outlive them. Tests inject fresh instances.
class Obd2WedgeDetector {
  Obd2WedgeDetector({this.threshold = 3})
      : assert(threshold > 0, 'threshold must be positive');

  /// The single process-wide instance production wires.
  static final Obd2WedgeDetector instance = Obd2WedgeDetector();

  /// Consecutive wedge-signature Classic ladder failures that flip
  /// [linkWedged]. 3 ≈ one minute of doomed, fully-budgeted ladder runs
  /// (#3421 bounds each at ~20 s) — late enough to skip transient RF blips,
  /// early enough to stop the #3415 all-day storm.
  final int threshold;

  /// Terminal native ladder strategies that carry the wedge signature: the
  /// whole RFCOMM ladder ran and failed (`exhausted`), the #3421 budget cut
  /// it short (`budget-exhausted`), or the Dart-side deadline fired because
  /// the platform thread itself was wedged (`connect-budget-timeout`, the
  /// #3415 t5/t8 mode). `no-adapter` / `bad-address` / `interrupted` are NOT
  /// wedge evidence and break the streak.
  static const Set<String> wedgeSignatureStrategies = {
    'exhausted',
    'budget-exhausted',
    'connect-budget-timeout',
  };

  /// Flips true when the streak reaches [threshold]; false when the wedge
  /// clears. The arbiter, the in-trip scanner factory and the recovery
  /// banner all observe this.
  final ValueNotifier<bool> linkWedged = ValueNotifier<bool>(false);

  /// Fired ONCE per wedge episode, with the MAC of the wedged adapter —
  /// production wires this to `Obd2WedgeRecovery.start`. Guarded: a throwing
  /// callback never derails the detector.
  void Function(String mac)? onWedged;

  int _streak = 0;
  String? _wedgedMac;

  /// Whether the link is currently considered wedged.
  bool get isWedged => linkWedged.value;

  /// MAC of the adapter the wedge was latched on, while wedged.
  String? get wedgedMac => _wedgedMac;

  /// Current consecutive wedge-signature failure count (tests/diagnostics).
  @visibleForTesting
  int get streak => _streak;

  /// Record one Classic connect-ladder outcome, observed at the
  /// `ClassicElmChannel.open()` funnel. [ok] resets the streak and — when
  /// wedged — clears the wedge (the adapter reappeared). A wedge-signature
  /// [strategy] (see [wedgeSignatureStrategies]) advances the streak; any
  /// other failure breaks it. The streak is deliberately mac-agnostic (one
  /// physical adapter in practice); the LAST failing mac is what latches.
  void noteClassicConnectOutcome({
    required String mac,
    required bool ok,
    String? strategy,
  }) {
    if (ok) {
      _streak = 0;
      _exitWedge('connect-succeeded');
      return;
    }
    if (strategy == null || !wedgeSignatureStrategies.contains(strategy)) {
      _streak = 0;
      return;
    }
    if (isWedged) return; // already latched — the recovery ladder owns it.
    _streak++;
    if (_streak >= threshold) _enterWedge(mac);
  }

  /// A recovery rung (or the user) brought the adapter back — clear the
  /// wedge and the streak.
  void noteRecovered(String reason) {
    _streak = 0;
    _exitWedge(reason);
  }

  void _enterWedge(String mac) {
    _wedgedMac = mac;
    linkWedged.value = true;
    debugPrint('Obd2WedgeDetector: link WEDGED after $_streak consecutive '
        'wedge-signature Classic failures (mac: $mac, #3422)');
    try {
      onWedged?.call(mac);
    } catch (e, st) {
      // The escalation ladder failing to START must not corrupt the
      // detector — the stand-down (the storm bound) is already in effect.
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'Obd2WedgeDetector: onWedged callback threw',
      }));
    }
  }

  void _exitWedge(String reason) {
    if (!isWedged) return;
    debugPrint('Obd2WedgeDetector: wedge cleared ($reason, #3422)');
    _wedgedMac = null;
    linkWedged.value = false;
  }

  /// Drop every latch + streak (tests sharing the process-wide [instance]).
  @visibleForTesting
  void resetForTest() {
    _streak = 0;
    _wedgedMac = null;
    linkWedged.value = false;
    onWedged = null;
  }
}

/// One-line funnel for `ClassicElmChannel.open()` (#3422): forward a Classic
/// connect-ladder outcome to the process-wide [Obd2WedgeDetector.instance].
void noteClassicLadderOutcome(String mac, {required bool ok, String? strategy}) =>
    Obd2WedgeDetector.instance
        .noteClassicConnectOutcome(mac: mac, ok: ok, strategy: strategy);
