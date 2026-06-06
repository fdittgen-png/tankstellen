// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'elm327_commands.dart';

/// Per-adapter standby/wake behaviour (#2268 concern 1).
///
/// ELM327 clones differ in how they behave on the very first command
/// after a fresh BLE/Classic open. Most generic clones answer the first
/// `ATZ` immediately (the channel open already woke them). A minority of
/// STN-/OBDLink-class adapters drop into an `ATLP` low-power sleep when
/// the engine is off and need a longer settle — and possibly a single
/// re-send — before the first command lands.
///
/// This value object is the per-adapter knob the connect path consults.
/// The default is a strict NO-OP: [maySleep] `false`, [wakeSettle]
/// [Duration.zero], [maxNudges] `0`. Every adapter paired today resolves
/// to the no-op default (see [Elm327Adapter.wakePolicy]), so connect
/// behaviour is byte-for-byte unchanged until a distinctive subclass
/// opts in behind evidence.
///
/// Deliberately NOT an AT "wake byte" — a BLE client usually cannot wake
/// an already-asleep ELM327 by writing a magic byte; the realistic lever
/// is a longer settle window plus a bounded re-send of the FIRST command.
class WakePolicy {
  /// Whether this adapter is known to drop into a standby/sleep state
  /// that the connect path should compensate for with an extra-settle
  /// window on the first command. `false` ⇒ no extra settle at all.
  final bool maySleep;

  /// Extra settle window given to the FIRST init command on a fresh
  /// connect when [maySleep] is `true`. Longer than the steady-state
  /// [Elm327Adapter.interCommandDelay] because a sleeping adapter needs
  /// time to spin its UART back up before it can answer. Capped by the
  /// connect path so a mis-seeded value can't stall start indefinitely.
  final Duration wakeSettle;

  /// Maximum number of EXTRA re-sends of the first command inside the
  /// wake window (a "nudge"), on top of the original attempt. `0` ⇒ no
  /// nudge. The connect path treats this as a hard cap (one nudge is the
  /// realistic value) so the wake batch can never become an unbounded
  /// retry loop.
  final int maxNudges;

  const WakePolicy({
    this.maySleep = false,
    this.wakeSettle = Duration.zero,
    this.maxNudges = 0,
  });

  /// The strict no-op default — no standby compensation whatsoever. This
  /// is what every generic / today-paired adapter resolves to, keeping
  /// connect behaviour unchanged.
  const WakePolicy.noop()
      : maySleep = false,
        wakeSettle = Duration.zero,
        maxNudges = 0;

  /// `true` when this policy actually asks the connect path to do
  /// something — i.e. it [maySleep] AND grants either a settle window or
  /// at least one nudge. A `maySleep` policy with a zero window and zero
  /// nudges is still inert, so the connect path can short-circuit on this.
  bool get isActive =>
      maySleep && (wakeSettle > Duration.zero || maxNudges > 0);
}

/// Per-adapter ELM327 protocol quirks (#1330).
///
/// Phase 1: scaffolding only. The single implementation
/// [GenericElm327Adapter] reproduces today's hardcoded init sequence +
/// timing exactly. Phases 2 and 3 add vLinker and SmartOBD profiles
/// with empirically-tuned values.
///
/// The connect path (currently in [Obd2Service.connect] and
/// [Obd2ConnectionService.connect]) consults this object instead of
/// hardcoded constants:
///
///   * [initSequence] — the AT setup commands sent in order after the
///     byte channel is open.
///   * [postResetDelay] — delay applied after the very first init
///     command (typically `ATZ`). Some clones need extra time to
///     re-enumerate after a soft reset.
///   * [interCommandDelay] — delay between subsequent init commands.
///   * [extraInitCommands] — adapter-specific commands appended to the
///     [initSequence] (e.g. `ATSP6\r` to pin a protocol).
///   * [preParse] — hook to massage a raw response BEFORE it reaches
///     the [Elm327Parsers.cleanResponse] pipeline. Default is identity;
///     adapter-specific subclasses can strip stray prompts / echoes.
abstract class Elm327Adapter {
  /// Stable identifier (`generic`, `vlinker-fs`, `smartobd`) used in
  /// debug logs and trip-history adapter attribution.
  String get id;

  /// Init commands sent after the byte channel is open, in order.
  List<String> get initSequence;

  /// Delay applied after the very first init command (typically `ATZ`).
  Duration get postResetDelay;

  /// Delay between subsequent init commands.
  Duration get interCommandDelay;

  /// Optional adapter-specific commands appended to [initSequence].
  List<String> get extraInitCommands;

  /// Hook to massage a raw response before [Elm327Parsers.cleanResponse].
  /// Default: identity. Adapter-specific subclasses can strip stray
  /// echoes etc.
  String preParse(String raw) => raw;

  /// Standby/wake behaviour for this adapter (#2268 concern 1). Default
  /// is the strict no-op [WakePolicy.noop] — no extra-settle window on
  /// the first command, so connect behaviour is unchanged for every
  /// adapter that doesn't override this. Only distinctive STN-/OBDLink-
  /// class subclasses (none paired today) should seed `maySleep: true`.
  WakePolicy get wakePolicy => const WakePolicy.noop();
}

/// Default adapter — values mirror today's hardcoded behaviour
/// byte-for-byte (#1330 phase 1). Used for every paired adapter until
/// phases 2/3 introduce vLinker / SmartOBD specialisations.
class GenericElm327Adapter implements Elm327Adapter {
  const GenericElm327Adapter();

  @override
  String get id => 'generic';

  @override
  List<String> get initSequence => Elm327Commands.initCommands;

  // #2969 — bumped 100 ms → 1 s. The generic profile is the catch-all for
  // UNFAMILIAR cold clones (incl. the generic-classic SPP fallback). A cheap
  // clone routinely needs ≥1 s to re-enumerate after ATZ before it answers the
  // next command; the old 100 ms raced the reset and made the connect fail with
  // a silent/garbage first reply. A once-per-connect cold-start cost only —
  // the inter-command delay below is unchanged.
  @override
  Duration get postResetDelay => const Duration(seconds: 1);

  @override
  Duration get interCommandDelay => const Duration(milliseconds: 100);

  @override
  List<String> get extraInitCommands => const [];

  @override
  String preParse(String raw) => raw;

  // #2268 concern 1 — generic clones answer the first command after the
  // channel open immediately; no standby compensation, strict no-op.
  @override
  WakePolicy get wakePolicy => const WakePolicy.noop();
}
