// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'flutter_blue_plus_elm_channel.dart';

/// Connect-path family for [FlutterBluePlusElmChannel], extracted from the
/// channel file as a `part` so it keeps private-member access while the
/// channel stays under the #1680 file-length cap (sanctioned #3760
/// decomposition — move-only, behaviour preserved).
///
/// These are kept as free functions (NOT an `extension`) so the thin
/// instance methods on [FlutterBluePlusElmChannel] that delegate to them
/// stay virtually dispatchable — test fakes must be able to `@override`
/// `connectDevice` / `rawConnect` / `bindConnectionState`, which extension
/// methods (statically dispatched) silently forbid. `part`-file privacy is
/// library-level, so these reach the channel's private fields directly.

/// Standard SPP-over-BLE UUIDs exposed by Vgate vLinker and most
/// ELM327 BLE clones (Nordic UART Service variant used by the
/// adapter firmware). If the adapter in front of you doesn't match
/// these, pass your own via [ble327ServiceUuid] / [writeCharUuid] /
/// [notifyCharUuid].
class Elm327BleUuids {
  final Guid service;
  final Guid writeChar;
  final Guid notifyChar;

  const Elm327BleUuids({
    required this.service,
    required this.writeChar,
    required this.notifyChar,
  });

  /// Defaults observed on real vLinker FS / FD / MC adapters + most
  /// BLE ELM327 clones.
  static final vgate = Elm327BleUuids(
    service: Guid('0000fff0-0000-1000-8000-00805f9b34fb'),
    writeChar: Guid('0000fff2-0000-1000-8000-00805f9b34fb'),
    notifyChar: Guid('0000fff1-0000-1000-8000-00805f9b34fb'),
  );
}

/// Body of [FlutterBluePlusElmChannel.open] (#3760).
Future<void> _openChannel(FlutterBluePlusElmChannel c) async {
  if (c._open) return;
  // #3244 — a preempt-abandoned channel is TERMINAL: never re-dial it
  // (thrown before any trace stamping — see Obd2ChannelAbandonLatch).
  c.throwIfAbandoned();
  // #3179 — make the channel safely RE-openable. The transport's open-retry
  // loop (#2906/#3014) and the reconnect path call close() + open() on the
  // SAME instance; close() closed `_incoming` and latched `_closing`, and
  // neither was ever undone — the "recovered" link was a zombie. Reset the
  // deliberate-close + drop-signal latches and, when a prior close() closed
  // the controller, recreate it + rebuild the disposed debouncer.
  c._closing = false;
  c._dropSignalled = false;
  if (c._incoming.isClosed) {
    c._incoming = StreamController<List<int>>.broadcast();
    c._dropDebouncer = ConnectionDropDebouncer(
      debounce: c._dropDebounce,
      onConfirmed: c._onDropConfirmed,
    );
  }
  // #2466 — gated comm-diagnostics connect-lifecycle tee. A no-op unless
  // `Feature.debugMode` armed the collector; each call early-returns on
  // `!enabled`, so production pays one cached-bool read per event.
  final diag = Obd2CommDiagnostics.instance;
  final connectSw = diag.enabled ? (Stopwatch()..start()) : null;
  if (diag.enabled) diag.noteConnectionEvent(attempt: true);
  try {
    await _connectAndDiscover(c);
    // ignore: catch_no_st — rethrow-only: the original stack is preserved by rethrow
  } catch (e) {
    if (diag.enabled) {
      diag.noteConnectionEvent(
        failureReason: classifyBleConnectFailure(e),
      );
    }
    // #2969 correction 3 — stamp the channel-open outcome on the active
    // connect trace where the REAL FBP/StateError is in hand
    // (Obd2Service.connect swallows it into a generic false). FIRST-wins, so
    // the wrong-transport gattTimeout outlives the scan fallback's scanEmpty.
    // #3244 — but NEVER from an abandoned zombie: by the time its hung open
    // finally throws, `active` may already be the NEW holder's root trace.
    if (!c.isAbandoned) {
      Obd2ConnectTraceLog.stampOpenFailure(
          classifyBleOpenOutcome(e), e.toString());
    }
    rethrow;
  }
  if (connectSw != null) {
    connectSw.stop();
    diag.noteConnectionEvent(
      success: true,
      timeToConnectMs: connectSw.elapsedMilliseconds,
    );
  }
}

/// The connect → service-discovery → notify-subscribe body of
/// [FlutterBluePlusElmChannel.open], extracted so [_openChannel] can wrap it
/// with the gated connect-lifecycle diagnostics tee (#2466) without
/// interleaving counters through the calls.
///
/// #3014 — split into [FlutterBluePlusElmChannel.connectDevice] (the FBP
/// connect dispatch incl. the scan-before-connect seed) and
/// [FlutterBluePlusElmChannel.discoverAndBind] (discovery + property
/// match + notify), both `@protected @visibleForTesting`, so the connect
/// ordering and discovery can be driven without a BLE stack (FBP's
/// `BluetoothService`/`BluetoothCharacteristic.properties` are not
/// constructible in a test — the pure [resolveElmGatt] matcher carries the
/// property-matching coverage, and these seams carry the ordering coverage).
Future<void> _connectAndDiscover(FlutterBluePlusElmChannel c) async {
  // #3184 — stage-tag the pre-discover phases. The trace previously
  // recorded NOTHING between `scan-seed` and the AT lines, so a connect
  // dying in discover/setNotify was indistinguishable from one that
  // never got a GATT link. Each step carries its elapsed ms.
  final sw = Stopwatch()..start();
  await c.connectDevice();
  Obd2ConnectTraceLog.active?.addStep(
    label: 'gatt-connect-ok',
    status: Obd2ConnectStepStatus.ok,
    latencyMs: sw.elapsedMilliseconds,
  );
  Obd2ConnectTraceLog.active?.addStep(
    label: 'discover-start',
    status: Obd2ConnectStepStatus.ok,
    detail: 'budget ${FlutterBluePlusElmChannel._discoverTimeoutSecs}s',
  );
  await c.discoverAndBind();
  // #2261 concern 1 — subscribe to the connection-state stream so a real
  // disconnect is noticed in ~1–2 s. The first emission is the current state
  // (`connected`); the debouncer ignores `connected` edges, so this is a
  // no-op until the link actually drops.
  c._dropDebouncer.reset();
  c.bindConnectionState();
  c._open = true;
  // #2261 concern 4 — a freshly-opened ACTIVE link is a recording link: ask
  // for high throughput (priority + best-effort MTU). Skipped on the passive
  // autoConnect path (FBP forbids requestMtu; a parked-car wait wants low
  // power). Best-effort: any rejection is swallowed.
  if (!c._autoConnect) {
    await c.tuneForRecording();
  }
}

/// Body of [FlutterBluePlusElmChannel.connectDevice] (#3014). Production
/// behaviour is exactly the per-path connect below.
Future<void> _connectDeviceImpl(FlutterBluePlusElmChannel c) async {
  // #3182 — wait (bounded, best-effort) for `adapterState == on` before ANY
  // connect dispatch. FBP's darwin side creates the CBCentralManager lazily
  // in the first method call and instantly rejects a connect issued while
  // it still reports `unknown` — so a cold-launch direct connect failed
  // spuriously on iOS. On timeout the connect proceeds, so a genuinely-off
  // adapter still surfaces through the existing error classification.
  await waitForAdapterOn();
  final timeout = c._connectTimeout;
  if (c._autoConnect) {
    // #2261 concern 2 — passive autoConnect GATT wait. No bounded timeout:
    // the OS keeps a low-power background connection request that resolves
    // the moment the adapter advertises again. requestMtu forbidden with
    // autoConnect:true, so `mtu: null`.
    await c.rawConnect(autoConnect: true, mtu: null);
    return;
  }
  if (timeout == null) {
    // #2969 — bound the scan-path open (was UNBOUNDED): FBP's
    // `autoConnect:false` connect can otherwise block ~35 s on a candidate the
    // scan saw but that has since vanished, freezing the connect (and any
    // self-test / first-connect riding it). A miss now fails fast.
    await c.rawConnect(
        autoConnect: false,
        mtu: null,
        timeout: FlutterBluePlusElmChannel._scanPathConnectTimeout);
    return;
  }
  // Direct-by-MAC path (#2242). Tear down any stale GATT client FIRST —
  // Android returns GATT_ERROR 133 if a prior (dropped-but-not-closed)
  // connection is still open, silently forcing a fall back to the scan
  // path. disconnect() is idempotent (no-op when nothing is connected).
  try {
    await c._device.disconnect();
  } catch (e, _) {
    // Best-effort pre-connect teardown of a stale GATT client. The connect
    // below proceeds regardless — a failure here is RECOVERABLE and
    // routine, never an error trace (#2379). Debug-only.
    assert(() {
      debugPrint('FlutterBluePlusElmChannel: pre-connect dead-GATT teardown '
          'failed (proceeding): $e');
      return true;
    }(), 'debug-only breadcrumb — the closure always returns true');
  }
  // #3014 — SCAN-BEFORE-CONNECT (the single highest-leverage SmartOBD fix).
  // Run a brief TARGETED scan for this MAC FIRST so Android holds a fresh
  // scan-result handle before the cold `connect(autoConnect:false)`.
  // Connecting to a raw MAC with no fresh handle is the textbook GATT-133 /
  // 15 s timeout trap — discovery is never reached. The seed `stopScan`s
  // before returning (fbp serializes BLE ops behind a global mutex, so a
  // scan still winding down on the radio deadlocks the connect). A scan
  // MISS is recorded but still proceeds to the bounded connect (the adapter
  // may be reachable even if the brief scan missed it, and the connect is
  // bounded so a miss fails fast → the service's scan / passive fallback).
  await _runScanSeed(c);
  // The explicit ~4 s timeout is LOAD-BEARING: FBP's
  // autoConnect:false connect can otherwise block ~35 s.
  // #3014 — ask for a larger MTU DURING connect on the bounded direct path
  // (was the FBP default 512, which Android negotiates down anyway): a
  // single round-trip negotiation beats a separate post-discovery
  // requestMtu on a flaky clone link. `tuneForRecording` still requests it
  // post-discovery as the fallback for clones that reject the in-connect ask.
  await c.rawConnect(
      autoConnect: false,
      timeout: timeout,
      mtu: FlutterBluePlusElmChannel._preferredMtu);
}

/// #3014 — run the injected scan-before-connect seed (best-effort) and stamp
/// the outcome as a trace step. Exposed for the connect-ordering test to
/// observe via [FlutterBluePlusElmChannel.debugScanSeedRan].
Future<void> _runScanSeed(FlutterBluePlusElmChannel c) async {
  final seed = c._scanSeed;
  if (seed == null) return;
  bool sawMac = false;
  try {
    sawMac = await seed();
    // best-effort pre-warm; the message is enough, the stack adds nothing.
    // ignore: catch_no_st
  } catch (e) {
    // A failing seed must never block the connect — it is a best-effort
    // pre-warm. Proceed to the bounded connect regardless.
    assert(() {
      debugPrint('FlutterBluePlusElmChannel: scan-seed failed '
          '(proceeding to connect): $e');
      return true;
    }(), 'debug-only breadcrumb — the closure always returns true');
  }
  c._debugScanSeedRan = true;
  c._debugScanSeedSawMac = sawMac;
  Obd2ConnectTraceLog.active?.addStep(
    label: 'scan-seed',
    status: sawMac ? Obd2ConnectStepStatus.ok : Obd2ConnectStepStatus.timeout,
    detail: sawMac
        ? 'targeted scan saw the MAC — fresh handle'
        : 'targeted scan missed the MAC — connecting cold',
  );
}

/// Body of [FlutterBluePlusElmChannel._onDropConfirmed] (#3760).
void _onDropConfirmedImpl(FlutterBluePlusElmChannel c) {
  // #2466 — a debounce-CONFIRMED drop is a real mid-session link loss; count
  // it (gated). Raw `disconnected` edges that self-heal inside the debounce
  // are binned separately below as `raw-edge-drop`.
  final diag = Obd2CommDiagnostics.instance;
  if (diag.enabled) diag.noteConnectionEvent(drop: true);
  // #3019 / Epic #3013 phase 3 — PROACTIVE drop signal. A debounce-confirmed
  // BLE drop is a real link loss; emit the transport-agnostic link-drop
  // signal so reconnect starts immediately (even idle / no command in
  // flight). Suppressed during a deliberate [FlutterBluePlusElmChannel.close]
  // (`_closing`).
  if (!c._closing && !c._dropSignalled) {
    c._dropSignalled = true;
    Obd2LinkDropSignal.instance.notifyDrop(
      transportKind: 'ble',
      mac: c._device.remoteId.str,
      reason: 'ble-disconnect-edge', // #3346
    );
  }
  if (c._incoming.isClosed) return;
  c._incoming.addError(const Obd2DisconnectedException());
}

/// Body of [FlutterBluePlusElmChannel.bindConnectionState] (#2261 concern 1).
void _bindConnectionStateImpl(FlutterBluePlusElmChannel c) {
  c._connStateSubscription = c._device.connectionState.listen(
    (state) {
      final disconnected = state == BluetoothConnectionState.disconnected;
      // #2466 — a raw `disconnected` EDGE (before the debouncer confirms it)
      // is binned as a recoverable transient: most edges self-heal inside the
      // supervision window. Counted only while the debouncer is idle so one
      // drop episode is one tally. Gated; no-op unless Feature.debugMode.
      if (disconnected) {
        final diag = Obd2CommDiagnostics.instance;
        if (diag.enabled && !c._dropDebouncer.isPending) {
          diag.noteConnectionEvent(failureReason: 'raw-edge-drop');
        }
      }
      c._dropDebouncer.noteConnectionState(disconnected: disconnected);
    },
    onError: (Object e, StackTrace st) {
      debugPrint('FlutterBluePlusElmChannel connectionState error: $e');
    },
  );
}
