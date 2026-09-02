// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'dropped_session_manager.dart';

/// #3915 (Epic #3914) — the re-adoption cycle breaker.
///
/// Field trip 2026-09-01: the trip rebound the SAME `Obd2Service`
/// instance every ~8.2 s for 43 minutes — a connected-flag corpse the
/// owner never recycled — and recorded zero engine samples. The reattach
/// source now proves adoption with a round-trip; this is the belt to
/// that brace: an instance that comes back and dies again twice within
/// [window] of its rebound is REFUSED for the rest of the trip, journaled
/// and breadcrumbed, and the source waits for a DIFFERENT instance
/// (handing the refused one back to the owner if it is still held).
/// Instance identity is `identical` — never equality, never a MAC.
class ReadoptionCycleBreaker implements Obd2AdoptionGate {
  ReadoptionCycleBreaker({
    required this.now,
    this.window = const Duration(seconds: 60),
    this.quickDropsToRefuse = 2,
  });

  /// Clock seam (the manager's `_now`).
  final DateTime Function() now;

  /// A drop this soon after the rebind counts as a quick re-drop.
  final Duration window;

  /// Quick re-drops of the SAME instance, in a row, that refuse it.
  final int quickDropsToRefuse;

  final Set<Obd2Service> _refused = Set<Obd2Service>.identity();
  Obd2Service? _lastAdopted;
  DateTime? _lastAdoptedAt;
  int _quickDrops = 0;

  @override
  bool isRefused(Obd2Service service) => _refused.contains(service);

  @override
  void noteAdopted(Obd2Service service) {
    if (!identical(service, _lastAdopted)) {
      // A different instance — the streak belongs to the old one.
      _lastAdopted = service;
      _quickDrops = 0;
    }
    _lastAdoptedAt = now();
  }

  /// A drop verdict fired. Returns the instance to refuse when this drop
  /// completes the cycle (the same instance re-dropped within [window]
  /// of its rebind, [quickDropsToRefuse] times in a row); null otherwise.
  Obd2Service? noteDrop() {
    final adopted = _lastAdopted;
    final at = _lastAdoptedAt;
    if (adopted == null || at == null) return null;
    if (now().difference(at) > window) {
      // A link that lived past the window earned its adoption.
      _quickDrops = 0;
      return null;
    }
    _quickDrops++;
    if (_quickDrops < quickDropsToRefuse) return null;
    _refused.add(adopted);
    return adopted;
  }
}

/// The reattach-source orchestration of [DroppedSessionManager] plus the
/// #3915 cycle-breaker hook — a `part` so the manager file stays under
/// the #1680 length cap (same library: private access preserved).
extension DroppedSessionReattach on DroppedSessionManager {
  /// Kick off the auto-reconnect scanner (#797 phase 3) if both a
  /// pinned adapter MAC AND a scanner factory are wired. No-op
  /// otherwise — the grace timer remains the sole recovery path then.
  void _startReconnectScanner() {
    final mac = _pinnedAdapterMac;
    final factory = _reconnectScannerFactory;
    if (mac == null || factory == null) return;
    final scanner = factory(mac, onScannerReconnect);
    if (scanner == null) return;
    // #2767 — re-emit on the active→passive switch so the UI can swap to the
    // calmer "passive-waiting" copy. Wired here (not via the factory
    // signature) so the `(mac, onReconnect)` factory contract stays untouched.
    scanner.onPassiveWait = _onScannerPassiveWait;
    // #3915 — the source consults the cycle breaker before every fire
    // and reports each adoption back to it.
    scanner.adoptionGate = _adoptionGate;
    _reconnectScanner = scanner;
    // Fire-and-forget — start() is an async scheduler boot that
    // shouldn't block the drop handler. Errors inside the scanner are
    // already caught internally.
    unawaited(scanner.start());
  }

  /// #2767 — the scanner dropped to a passive autoConnect wait. Recording
  /// continues; we re-emit only so the UI can swap to the calmer copy. A pure
  /// notification: no state transition, and the scanner still re-arms.
  void _onScannerPassiveWait() {
    if (_host.stopped) return;
    _trace(AutoRecordEventKind.reconnectPassiveWaiting);
    _host.emitState();
  }

  /// Tear down the in-flight reconnect scanner. Best-effort; safe to
  /// call when none is running.
  Future<void> stopReconnectScanner() async {
    final scanner = _reconnectScanner;
    if (scanner == null) return;
    _reconnectScanner = null;
    try {
      await scanner.stop();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {
            'where': 'DroppedSessionManager stop reconnect scanner'
          }));
    }
  }

  /// #3915 — the trip's adoption policy, for the controller's test seam.
  Obd2AdoptionGate get adoptionGate => _adoptionGate;

  /// #3915 — a drop verdict fired on the instance the trip most recently
  /// rebound onto. When it completes the re-adoption cycle the instance
  /// is refused: journaled + breadcrumbed here; the source refuses to
  /// fire it again and hands it back to the owner (`readoption-cycle`)
  /// if the owner still holds it. The ordinary drop path (owner seam,
  /// GPS-degrade, reattach) then runs unchanged.
  void _refuseIfReadoptionCycle(TripDropReason reason) {
    final refused = _adoptionGate.noteDrop();
    if (refused == null) return;
    final detail = '${reason.name} — same instance dropped '
        '${_adoptionGate.quickDropsToRefuse}× within '
        '${_adoptionGate.window.inSeconds}s of its rebind; waiting for '
        'a different one';
    _note(RecordingSessionEventKind.adoptionRefused, detail);
    BreadcrumbCollector.add('OBD2 recording: adoption refused', detail: detail);
  }
}
