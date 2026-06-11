// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_adapter_state_gate.dart';
import 'ble_disconnect_classifier.dart';
import 'ble_link_tuner.dart';
import 'connection_drop_debouncer.dart';
import 'elm_byte_channel.dart';
import 'elm_gatt_profiles.dart';
import 'obd2_comm_diagnostics.dart';
import 'obd2_connect_classifier.dart';
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import 'obd2_connection_errors.dart';
import 'obd2_link_drop_signal.dart';
import 'obd2_pairing_mode.dart';
import '../../../../core/logging/error_logger.dart';

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

/// [ElmByteChannel] backed by flutter_blue_plus. Connects to a single
/// [BluetoothDevice], discovers the ELM327 service, enables notifies
/// on the incoming characteristic, and exposes write + notify as the
/// abstract channel contract.
///
/// This class is Android-oriented (vLinker FS is BLE on Android).
/// It is untested on iOS — flutter_blue_plus is cross-platform but
/// iOS BLE ELM adapters are rare; add iOS-specific handling when the
/// app starts supporting them.
class FlutterBluePlusElmChannel
    implements ElmByteChannel, Obd2LinkTuner, Obd2GattRecoverable {
  /// #2969 — bound the scan-path `connect()` (the `connectTimeout == null`
  /// branch) so FBP can't block ~35 s on a vanished candidate.
  static const Duration _scanPathConnectTimeout = Duration(seconds: 10);

  /// #3014 — bound `discoverServices` on its OWN short budget. FBP's default is
  /// 15 s; a hung discovery (a clone whose GATT table never resolves) used to
  /// freeze the whole open for 15 s and read as a hang. A miss now fails in
  /// ~5 s with a distinct `gattTimeout` outcome.
  /// #3118 — iOS-aware. iOS CoreBluetooth's `discoverServices` is slower than
  /// Android's, so the OBDLink CX's GATT-table resolution can blow Android's
  /// tight 5 s on a cold iPhone connect. Android keeps 5 s (byte-identical).
  /// #3182 — int SECONDS now, passed to FBP's own `timeout:` parameter (see
  /// [discoverAndBind]) instead of an outer Dart `.timeout()`.
  static int get _discoverTimeoutSecs =>
      defaultTargetPlatform == TargetPlatform.iOS ? 8 : 5;

  /// #3014 — bound `setNotifyValue`, for the same reason: a clone that accepts
  /// the descriptor write but never ACKs would otherwise block 15 s.
  ///
  /// #3118 — iOS-aware. THIS is the OBDLink CX failure on iPhone
  /// (`TimeoutException after 0:00:04 — Future not completed`): the post-connect
  /// CCCD descriptor write (enabling notifications) is slower over iOS
  /// CoreBluetooth than Android's 4 s. #3113 only widened the `connect()` budget
  /// (iOS 7 s); this very next step still clipped at 4 s. iOS gets 7 s; Android
  /// keeps 4 s (byte-identical — the #2242/#3014 tight bound stays load-bearing).
  /// #3182 — int SECONDS now, passed to FBP's own `timeout:` parameter.
  static int get _setNotifyTimeoutSecs =>
      defaultTargetPlatform == TargetPlatform.iOS ? 7 : 4;

  /// #3118 — test seams to lock the iOS-aware post-connect budgets. Kept as
  /// [Duration]s (built from the int-seconds FBP budgets) so the existing
  /// budget-pinning tests stay byte-identical.
  @visibleForTesting
  static Duration get debugDiscoverTimeout =>
      Duration(seconds: _discoverTimeoutSecs);
  @visibleForTesting
  static Duration get debugSetNotifyTimeout =>
      Duration(seconds: _setNotifyTimeoutSecs);

  /// #3014 — best-effort MTU asked for during the bounded-connect path. Clones
  /// often reject it; the post-discovery `requestMtu` in [tuneForRecording]
  /// stays the fallback. Skipped on the `autoConnect:true` passive path (FBP
  /// forbids `mtu` with autoConnect).
  static const int _preferredMtu = 247;

  final BluetoothDevice _device;
  final Elm327BleUuids _uuids;

  /// Optional bounded timeout passed to `device.connect` (#2242). When null,
  /// `connect` uses the legacy `mtu: null` form with no timeout (the scan-first
  /// path). When set — the direct-by-MAC path — `connect(autoConnect:false,
  /// timeout: …)` bounds the attempt and `open()` first tears down any stale
  /// GATT client to dodge Android GATT_ERROR 133.
  final Duration? _connectTimeout;

  /// #2261 concern 2 — passive autoConnect GATT wait. When true, `open()`
  /// connects with `autoConnect:true` and NO bounded timeout: the OS holds a
  /// low-power background connection request that resolves the instant the
  /// adapter (re)advertises. Used by the reconnect scanner past its active-scan
  /// miss ceiling so a parked car doesn't burn the radio. autoConnect:true
  /// forbids requestMtu, so the concern-4 MTU bump is skipped on this path.
  final bool _autoConnect;

  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<BluetoothConnectionState>? _connStateSubscription;

  /// #3179 — NOT final: [close] closes the broadcast controller, and the
  /// transport's open-retry loop (plus any reconnect) calls `close()` +
  /// `open()` on the SAME channel instance, so [open] must be able to
  /// recreate it. With a `final` controller the "recovered" link was a
  /// zombie: every notify byte hit a closed controller and the reply timed
  /// out forever.
  StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  /// #3019 — set while a DELIBERATE [close] tears the channel down, so the
  /// resulting disconnect edge is NOT misread as an unexpected drop (which
  /// would spuriously kick the reconnect loop after a normal disconnect).
  bool _closing = false;

  /// #3019 — fires the proactive link-drop signal at most once per UNEXPECTED
  /// drop (the debounce-confirmed edge), suppressed during a deliberate close.
  bool _dropSignalled = false;

  /// #2261 concern 1 — debounces a raw `connectionState == disconnected` edge
  /// into a confirmed drop so a self-healing RF blip within the supervision
  /// timeout doesn't tear down a recoverable session, while a genuine
  /// disconnect still surfaces in ~1–2 s (not the ~15 s read timeout). On
  /// confirmation it pushes a typed [Obd2DisconnectedException] onto the byte
  /// stream, which the transport re-throws so [TripDropDetector] sees a drop.
  /// #3179 — NOT `late final`: [close] disposes it, so a reopen rebuilds it
  /// (same debounce, same callback) instead of reviving a disposed one.
  late ConnectionDropDebouncer _dropDebouncer;

  /// #3179 — the configured debounce, kept so [open] can rebuild
  /// [_dropDebouncer] after a close() → open() cycle.
  final Duration _dropDebounce;

  /// #3014 — scan-before-connect seed (THE highest-leverage SmartOBD fix).
  /// Runs a brief TARGETED scan for this device's MAC before the cold
  /// `connect(autoConnect:false)` on the direct-by-MAC path, then `stopScan`s,
  /// so Android holds a FRESH scan-result handle for the peripheral. Connecting
  /// to a raw MAC the OS has no fresh handle for is the textbook GATT-133 / 15 s
  /// timeout trap (Punch Through / van Welie) — discovery is never reached.
  ///
  /// Returns `true` when the targeted scan SAW the MAC (a fresh handle exists,
  /// proceed to connect), `false` on a scan miss (the caller's bounded-passive
  /// fallback owns the recovery). Null on the scan-path / passive paths (no
  /// seed needed: the scan path already has a fresh handle from the picker
  /// scan, and the passive path is itself the OS-held background request).
  ///
  /// Injected by [PluginBluetoothFacade.channelForDirect] in production (a real
  /// FBP `withRemoteIds` scan); a fake in tests so scan-then-connect is driven
  /// with no BLE stack. fbp serializes BLE ops behind a global mutex, so the
  /// production seed MUST `stopScan` before returning or the subsequent connect
  /// deadlocks.
  final Future<bool> Function()? _scanSeed;

  FlutterBluePlusElmChannel(
    this._device, {
    Elm327BleUuids? uuids,
    Duration? connectTimeout,
    bool autoConnect = false,
    Future<bool> Function()? scanSeed,
    Duration dropDebounce = const Duration(milliseconds: 1500),
  })  : _uuids = uuids ?? Elm327BleUuids.vgate,
        _connectTimeout = connectTimeout,
        _autoConnect = autoConnect,
        _scanSeed = scanSeed,
        _dropDebounce = dropDebounce {
    _dropDebouncer = ConnectionDropDebouncer(
      debounce: dropDebounce,
      onConfirmed: _onDropConfirmed,
    );
  }

  /// Push the typed disconnect onto the byte stream so the transport's
  /// in-flight `sendCommand` completer fails fast with a classified error
  /// instead of waiting out the read timeout (#2261 concern 1).
  void _onDropConfirmed() {
    // #2466 — a debounce-CONFIRMED drop is a real mid-session link loss; count
    // it (gated). Raw `disconnected` edges that self-heal inside the debounce
    // are binned separately below as `raw-edge-drop`.
    final diag = Obd2CommDiagnostics.instance;
    if (diag.enabled) diag.noteConnectionEvent(drop: true);
    // #3019 / Epic #3013 phase 3 — PROACTIVE drop signal. A debounce-confirmed
    // BLE drop is a real link loss; emit the transport-agnostic link-drop
    // signal so the trip-INDEPENDENT reconnect controller starts its bounded
    // backoff loop immediately (even when idle / no command in flight).
    // Suppressed during a deliberate [close] (`_closing`) so a normal
    // disconnect is never misread as a drop.
    if (!_closing && !_dropSignalled) {
      _dropSignalled = true;
      Obd2LinkDropSignal.instance
          .notifyDrop(transportKind: 'ble', mac: _device.remoteId.str);
    }
    if (_incoming.isClosed) return;
    _incoming.addError(const Obd2DisconnectedException());
  }

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> open() async {
    if (_open) return;
    // #3179 — make the channel safely RE-openable. The transport's open-retry
    // loop (#2906/#3014) and the reconnect path call close() + open() on the
    // SAME instance; close() closed `_incoming` and latched `_closing`, and
    // neither was ever undone — so the "recovered" link was a zombie (notify
    // bytes silently dropped, the drop debouncer + drop-signal permanently
    // dead). Reset the deliberate-close + drop-signal latches and, when a
    // prior close() closed the controller, recreate it and rebuild the
    // disposed debouncer before the GATT dance runs.
    _closing = false;
    _dropSignalled = false;
    if (_incoming.isClosed) {
      _incoming = StreamController<List<int>>.broadcast();
      _dropDebouncer = ConnectionDropDebouncer(
        debounce: _dropDebounce,
        onConfirmed: _onDropConfirmed,
      );
    }
    // #2466 — gated comm-diagnostics connect-lifecycle tee. A no-op unless
    // `Feature.debugMode` armed the collector; each call early-returns on
    // `!enabled`, so production pays one cached-bool read per event.
    final diag = Obd2CommDiagnostics.instance;
    final connectSw = diag.enabled ? (Stopwatch()..start()) : null;
    if (diag.enabled) diag.noteConnectionEvent(attempt: true);
    try {
      await _connectAndDiscover();
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
      Obd2ConnectTraceLog.stampOpenFailure(
          classifyBleOpenOutcome(e), e.toString());
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

  /// The connect → service-discovery → notify-subscribe body of [open],
  /// extracted so [open] can wrap it with the gated connect-lifecycle
  /// diagnostics tee (#2466) without interleaving counters through the calls.
  ///
  /// #3014 — split into [connectDevice] (the FBP connect dispatch incl. the
  /// scan-before-connect seed) and [discoverAndBind] (discovery + property
  /// match + notify), both `@protected @visibleForTesting`, so the connect
  /// ordering and discovery can be driven without a BLE stack (FBP's
  /// `BluetoothService`/`BluetoothCharacteristic.properties` are not
  /// constructible in a test — the pure [resolveElmGatt] matcher carries the
  /// property-matching coverage, and these seams carry the ordering coverage).
  Future<void> _connectAndDiscover() async {
    // #3184 — stage-tag the pre-discover phases. The trace previously
    // recorded NOTHING between `scan-seed` and the AT lines, so a connect
    // dying in discover/setNotify was indistinguishable from one that
    // never got a GATT link. Each step carries its elapsed ms.
    final sw = Stopwatch()..start();
    await connectDevice();
    Obd2ConnectTraceLog.active?.addStep(
      label: 'gatt-connect-ok',
      status: Obd2ConnectStepStatus.ok,
      latencyMs: sw.elapsedMilliseconds,
    );
    Obd2ConnectTraceLog.active?.addStep(
      label: 'discover-start',
      status: Obd2ConnectStepStatus.ok,
      detail: 'budget ${_discoverTimeoutSecs}s',
    );
    await discoverAndBind();
    // #2261 concern 1 — subscribe to the connection-state stream so a real
    // disconnect is noticed in ~1–2 s. The first emission is the current state
    // (`connected`); the debouncer ignores `connected` edges, so this is a
    // no-op until the link actually drops.
    _dropDebouncer.reset();
    bindConnectionState();
    _open = true;
    // #2261 concern 4 — a freshly-opened ACTIVE link is a recording link: ask
    // for high throughput (priority + best-effort MTU). Skipped on the passive
    // autoConnect path (FBP forbids requestMtu; a parked-car wait wants low
    // power). Best-effort: any rejection is swallowed.
    if (!_autoConnect) {
      await tuneForRecording();
    }
  }

  /// #3014 — the FBP connect dispatch, including the scan-before-connect seed
  /// on the cold direct path. `@protected @visibleForTesting` so a test can
  /// drive the scan-then-connect ordering (FBP `device.connect` is not fakeable
  /// otherwise). Production behaviour is exactly the per-path connect below.
  @protected
  @visibleForTesting
  Future<void> connectDevice() async {
    // #3182 — wait (bounded, best-effort) for `adapterState == on` before ANY
    // connect dispatch. FBP's darwin side creates the CBCentralManager lazily
    // in the first method call and instantly rejects a connect issued while
    // it still reports `unknown` — so a cold-launch direct connect failed
    // spuriously on iOS. On timeout the connect proceeds, so a genuinely-off
    // adapter still surfaces through the existing error classification.
    await waitForAdapterOn();
    final timeout = _connectTimeout;
    if (_autoConnect) {
      // #2261 concern 2 — passive autoConnect GATT wait. No bounded timeout:
      // the OS keeps a low-power background connection request that resolves
      // the moment the adapter advertises again. requestMtu forbidden with
      // autoConnect:true, so `mtu: null`.
      await rawConnect(autoConnect: true, mtu: null);
      return;
    }
    if (timeout == null) {
      // #2969 — bound the scan-path open (was UNBOUNDED): FBP's
      // `autoConnect:false` connect can otherwise block ~35 s on a candidate the
      // scan saw but that has since vanished, freezing the connect (and any
      // self-test / first-connect riding it). A miss now fails fast.
      await rawConnect(
          autoConnect: false, mtu: null, timeout: _scanPathConnectTimeout);
      return;
    }
    // Direct-by-MAC path (#2242). Tear down any stale GATT client FIRST —
    // Android returns GATT_ERROR 133 if a prior (dropped-but-not-closed)
    // connection is still open, silently forcing a fall back to the scan
    // path. disconnect() is idempotent (no-op when nothing is connected).
    try {
      await _device.disconnect();
    } catch (e, _) {
      // Best-effort pre-connect teardown of a stale GATT client. The connect
      // below proceeds regardless — a failure here is RECOVERABLE and
      // routine, never an error trace (#2379). Debug-only.
      assert(() {
        debugPrint('FlutterBluePlusElmChannel: pre-connect dead-GATT teardown '
            'failed (proceeding): $e');
        return true;
      }());
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
    await _runScanSeed();
    // The explicit ~4 s timeout is LOAD-BEARING: FBP's
    // autoConnect:false connect can otherwise block ~35 s.
    // #3014 — ask for a larger MTU DURING connect on the bounded direct path
    // (was the FBP default 512, which Android negotiates down anyway): a
    // single round-trip negotiation beats a separate post-discovery
    // requestMtu on a flaky clone link. `tuneForRecording` still requests it
    // post-discovery as the fallback for clones that reject the in-connect ask.
    await rawConnect(autoConnect: false, timeout: timeout, mtu: _preferredMtu);
  }

  /// #3014 — the single raw FBP `device.connect` call, behind a `@protected`
  /// `@visibleForTesting` seam (the [writeRaw] precedent). A test overrides this
  /// to drive the scan-before-connect ORDERING and the GATT-133-on-cold-MAC
  /// contract without a real BLE stack (FBP `device.connect` is unfakeable
  /// otherwise). Production calls FBP exactly as before.
  @protected
  @visibleForTesting
  Future<void> rawConnect({
    required bool autoConnect,
    int? mtu,
    Duration? timeout,
  }) =>
      timeout == null
          ? _device.connect(autoConnect: autoConnect, mtu: mtu)
          : _device.connect(
              autoConnect: autoConnect, mtu: mtu, timeout: timeout);

  /// #3014 — run the injected scan-before-connect seed (best-effort) and stamp
  /// the outcome as a trace step. Exposed for the connect-ordering test to
  /// observe via [debugScanSeedRan].
  Future<void> _runScanSeed() async {
    final seed = _scanSeed;
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
      }());
    }
    _debugScanSeedRan = true;
    _debugScanSeedSawMac = sawMac;
    Obd2ConnectTraceLog.active?.addStep(
      label: 'scan-seed',
      status: sawMac ? Obd2ConnectStepStatus.ok : Obd2ConnectStepStatus.timeout,
      detail: sawMac
          ? 'targeted scan saw the MAC — fresh handle'
          : 'targeted scan missed the MAC — connecting cold',
    );
  }

  bool _debugScanSeedRan = false;
  bool _debugScanSeedSawMac = false;

  /// #3014 test seam — true once the scan-before-connect seed has run on the
  /// cold direct path.
  @visibleForTesting
  bool get debugScanSeedRan => _debugScanSeedRan;

  /// #3014 test seam — true when the seed saw the MAC (a fresh handle exists).
  @visibleForTesting
  bool get debugScanSeedSawMac => _debugScanSeedSawMac;

  /// #3014 — discover services, resolve the ELM write+notify pair by PROPERTY
  /// (registry UUIDs as a first-priority hint), bind the chars + enable notify.
  /// `@protected @visibleForTesting` so a test can stub it out when driving
  /// [connectDevice] in isolation (the real FBP discovery is not fakeable).
  @protected
  @visibleForTesting
  Future<void> discoverAndBind() async {
    // #3014 — bound discoverServices on its own short budget (FBP default 15 s)
    // so a clone whose GATT table never resolves fails in ~5 s as `gattTimeout`,
    // not a 15 s hang.
    // #3182 — the budget is now FBP's OWN `timeout:` parameter, not an outer
    // Dart `.timeout()`: the outer form fired OUR TimeoutException at the
    // budget but left FBP's GLOBAL per-device mutex held for the full 15 s
    // default, serializing (deadlocking) every retry that followed. FBP's
    // native timeout releases the mutex at our budget; its
    // FlutterBluePlusException ("Timed out after Ns") still classifies as
    // `gattTimeout` (see classifyBleOpenOutcome).
    final services =
        await _device.discoverServices(timeout: _discoverTimeoutSecs);
    // #3014 — property-based discovery: adapt FBP services into the pure
    // descriptor shape, then resolve the write+notify pair by characteristic
    // PROPERTY across the known ELM families, with the registry UUIDs as a
    // first-priority exact hint. This is what makes an HM-10-class clone
    // (SmartOBD, FFE0 service / single dual-mode FFE1 char) connect — the old
    // exact-UUID `firstWhere`-or-throw on FFF0/FFF2/FFF1 threw a StateError on
    // any non-FFF0 layout.
    final descriptors = _toDescriptors(services);
    final resolved = resolveElmGatt(
      descriptors,
      hintServiceUuid: _uuids.service.str,
      hintWriteCharUuid: _uuids.writeChar.str,
      hintNotifyCharUuid: _uuids.notifyChar.str,
    );
    if (resolved == null) {
      // No usable writable+notifiable pair on ANY discovered service. Log the
      // device's ACTUAL layout into the trace so the maintainer can confirm a
      // clone's real service/char/property table from the next capture (#3014).
      final layout = describeGattLayout(descriptors);
      Obd2ConnectTraceLog.active?.addStep(
        label: 'gatt-discover',
        status: Obd2ConnectStepStatus.fail,
        detail: layout,
      );
      throw StateError(
        'BLE device ${_device.remoteId.str} exposes no ELM327 service with a '
        'writable + notifiable characteristic pair — discovered: $layout',
      );
    }
    // #3014 — one-time success layout step (the maintainer asked to see the real
    // SmartOBD layout). Records WHICH service/chars were picked and HOW.
    Obd2ConnectTraceLog.active?.addStep(
      label: 'gatt-discover',
      status: Obd2ConnectStepStatus.ok,
      detail: 'matched ${resolved.matchReason}: '
          'svc=${resolved.serviceUuid} w=${resolved.writeCharUuid} '
          'n=${resolved.notifyCharUuid}',
    );
    final service = services.firstWhere(
      (s) => s.uuid.str.toLowerCase() == resolved.serviceUuid.toLowerCase(),
    );
    _writeChar = service.characteristics.firstWhere(
      (c) => c.uuid.str.toLowerCase() == resolved.writeCharUuid.toLowerCase(),
    );
    _notifyChar = service.characteristics.firstWhere(
      (c) => c.uuid.str.toLowerCase() == resolved.notifyCharUuid.toLowerCase(),
    );
    // #3014 — bound setNotifyValue on its own short budget too.
    // #3182 — via FBP's own `timeout:` (mutex released at our budget; the
    // outer Dart `.timeout()` left it held up to 15 s — see above).
    // #3181 — through [enableNotify]: a FIRST-connect deviceId gets the
    // generous pairing budget (the CX pairs via this very subscribe).
    await enableNotify();
    _subscription = _notifyChar!.lastValueStream.listen(
      handleNotifyBytes,
      onError: (Object e, StackTrace st) {
        // #2900 — a mid-session disconnect can surface here too (the GATT/ATT
        // stack errors the notify stream when the adapter drops). Clear the
        // session and forward the RECLASSIFIED recoverable disconnect (not the
        // raw FBP/GATT error) so the transport's completer fails fast AND the
        // drop detector sees a typed disconnect — never an ERROR trace. A
        // genuine non-disconnect error keeps its #2295 behaviour (below).
        if (isBleAdapterDisconnect(e)) {
          // #2907 — FULL session teardown on a confirmed drop (was clearing
          // only `_open`/`_writeChar`, leaving stale notify state behind).
          _clearSessionOnDrop();
          if (!_incoming.isClosed) {
            _incoming.addError(
              const Obd2DisconnectedException(
                'FlutterBluePlusElmChannel: notify stream dropped — '
                'adapter not connected',
              ),
              st,
            );
          }
          return;
        }
        // #2295 — forward the error so the transport's pending `sendCommand`
        // completer fails IMMEDIATELY instead of waiting out the read timeout.
        if (!_incoming.isClosed) _incoming.addError(e, st);
        // OBD2/BLE GATT/ATT error → `other` ("not yet classified", #2379).
        // Kept logged: a real link drop worth seeing in release triage.
        unawaited(errorLogger.log(ErrorLayer.other, e, st,
            context: const {'where': 'FlutterBluePlusElmChannel notify error'}));
      },
    );
  }

  /// #3181 — enable notifications on the resolved CCCD, with the
  /// FIRST-CONNECT pairing budget. The OBDLink CX initiates BLE pairing
  /// via this very subscribe: on a never-bonded phone `setNotifyValue`
  /// blocks on the OS pairing dialog, and the steady-state budget (iOS
  /// 7 s / Android 4 s) clipped the human tap. A deviceId in
  /// [Obd2PairingMode] first-connect mode gets
  /// [Obd2PairingMode.firstConnectSetNotifySecs] instead, the
  /// `pairing-wait` trace step is stamped (#3184), and the
  /// [Obd2PairingMode.pairingWaitPending] flag drives the "confirm the
  /// pairing request" UI hint while the subscribe is in flight.
  ///
  /// A failure that classifies as pairing ([classifySetNotifyFailure] —
  /// explicit auth/encryption/bond errors on any connect, or a timeout on
  /// a first connect) is rethrown as the TYPED [Obd2PairingRequired] so
  /// the transport's open-retry loop does NOT tear the link down and
  /// re-dial mid-pairing, and the UI can show the power-cycle guidance.
  ///
  /// `@protected @visibleForTesting` so the budget selection + pairing
  /// classification are drivable without a BLE stack (via [rawSetNotify]).
  @protected
  @visibleForTesting
  Future<void> enableNotify() async {
    final deviceId = _device.remoteId.str;
    final firstConnect = Obd2PairingMode.isFirstConnect(deviceId);
    final notifySecs = Obd2PairingMode.setNotifyBudgetSecsFor(
      deviceId,
      platformDefaultSecs: _setNotifyTimeoutSecs,
    );
    // #3184 — stage-tag the subscribe so a persisted trace shows WHERE a
    // failed connect died (set-notify was previously invisible).
    Obd2ConnectTraceLog.active?.addStep(
      label: 'set-notify-start',
      status: Obd2ConnectStepStatus.ok,
      detail: 'budget ${notifySecs}s',
    );
    if (firstConnect) {
      Obd2ConnectTraceLog.active?.addStep(
        label: 'pairing-wait',
        status: Obd2ConnectStepStatus.ok,
        detail: 'first connect — OS pairing dialog may be pending; '
            'budget ${notifySecs}s (#3181)',
      );
      Obd2PairingMode.notePairingWaitStarted();
    }
    try {
      await rawSetNotify(notifySecs);
      // classification-only binding; the original stack is preserved by
      // rethrow and the typed wrap carries the raw toString.
      // ignore: catch_no_st
    } catch (e) {
      final outcome = classifySetNotifyFailure(e, firstConnect: firstConnect);
      if (outcome == Obd2ConnectOutcome.pairingRequired) {
        throw Obd2PairingRequired(
            'BLE pairing did not complete during setNotify '
            '(firstConnect: $firstConnect) — power-cycle the adapter and '
            'retry within 5 minutes: $e');
      }
      rethrow;
    } finally {
      if (firstConnect) Obd2PairingMode.notePairingWaitEnded();
    }
  }

  /// The raw CCCD subscribe behind a `@protected @visibleForTesting` seam
  /// (the [writeRaw] precedent) so [enableNotify]'s budget selection and
  /// pairing classification are testable — FBP's
  /// `BluetoothCharacteristic.setNotifyValue` hits the platform channel.
  @protected
  @visibleForTesting
  Future<void> rawSetNotify(int timeoutSecs) =>
      _notifyChar!.setNotifyValue(true, timeout: timeoutSecs);

  /// #3179 — the notify-stream DATA handler, extracted so a reopen test can
  /// drive the EXACT production byte path without a real BLE stack (FBP's
  /// `lastValueStream` is unfakeable). Tees the chunk into the gated
  /// comm-diagnostics framing counters (#2467) and feeds the live incoming
  /// controller. The `isClosed` guard mirrors [ClassicElmChannel]'s #2953
  /// late-byte guard: a chunk already queued on the event loop can land
  /// AFTER close() closed `_incoming` — drop it silently, never throw.
  @protected
  @visibleForTesting
  void handleNotifyBytes(List<int> bytes) {
    noteObd2Framing(bytes);
    if (!_incoming.isClosed) _incoming.add(bytes);
  }

  /// #3179 test seam — feed a raw connection-state edge into the drop
  /// debouncer exactly as the FBP `connectionState` listener does, so a test
  /// can prove drop detection still works after a close() → open() cycle
  /// (the real stream is unfakeable).
  @visibleForTesting
  void debugNoteConnectionState({required bool disconnected}) =>
      _dropDebouncer.noteConnectionState(disconnected: disconnected);

  /// #2261 concern 1 — subscribe to the connection-state stream so a real
  /// disconnect is noticed in ~1–2 s. The first emission is the current state
  /// (`connected`); the debouncer ignores `connected` edges, so this is a
  /// no-op until the link actually drops. (#3014 — extracted from the inlined
  /// discover/notify body + made a `@protected @visibleForTesting` seam so a
  /// test driving [open] doesn't hit the unfakeable FBP `connectionState`
  /// stream.)
  @protected
  @visibleForTesting
  void bindConnectionState() => _bindConnectionState();

  void _bindConnectionState() {
    _connStateSubscription = _device.connectionState.listen(
      (state) {
        final disconnected = state == BluetoothConnectionState.disconnected;
        // #2466 — a raw `disconnected` EDGE (before the debouncer confirms it)
        // is binned as a recoverable transient: most edges self-heal inside the
        // supervision window. Counted only while the debouncer is idle so one
        // drop episode is one tally. Gated; no-op unless Feature.debugMode.
        if (disconnected) {
          final diag = Obd2CommDiagnostics.instance;
          if (diag.enabled && !_dropDebouncer.isPending) {
            diag.noteConnectionEvent(failureReason: 'raw-edge-drop');
          }
        }
        _dropDebouncer.noteConnectionState(disconnected: disconnected);
      },
      onError: (Object e, StackTrace st) {
        debugPrint('FlutterBluePlusElmChannel connectionState error: $e');
      },
    );
  }

  /// #3014 — adapt the discovered FBP [BluetoothService]s into the pure
  /// [GattServiceDescriptor] shape the platform-free [resolveElmGatt] matcher
  /// consumes. Reads each characteristic's GATT properties so the matcher can
  /// pick write/notify by capability rather than exact UUID.
  static List<GattServiceDescriptor> _toDescriptors(
          List<BluetoothService> services) =>
      [
        for (final s in services)
          GattServiceDescriptor(
            uuid: s.uuid.str,
            characteristics: [
              for (final c in s.characteristics)
                GattCharDescriptor(
                  uuid: c.uuid.str,
                  write: c.properties.write,
                  writeWithoutResponse: c.properties.writeWithoutResponse,
                  notify: c.properties.notify,
                  indicate: c.properties.indicate,
                ),
            ],
          ),
      ];

  @override
  Future<void> tuneForRecording() =>
      const BleLinkTuner().tuneForRecording(_device, autoConnect: _autoConnect);

  @override
  Future<void> tuneForBackground() =>
      const BleLinkTuner().tuneForBackground(_device);

  /// #3014 — best-effort drop of the native Android GATT service cache between
  /// connect retries on a GATT_ERROR 133 (a cache-poisoned device). FBP's
  /// `clearGattCache` is the Android-only hidden-API `BluetoothGatt.refresh()`
  /// shim; it throws `androidOnly` off Android and can throw on an OEM that
  /// blocks the reflection — both are swallowed (the retry proceeds regardless).
  /// Never throws (#1103): the transport calls this on the failure path where
  /// any escape would mask the real connect error.
  @override
  Future<void> refreshGattCache() async {
    try {
      await _device.clearGattCache();
      // best-effort OEM-variable reflection; swallowed so a refresh failure
      // can't mask the real connect error on the retry.
      // ignore: catch_no_st
    } catch (e) {
      // OEM-variable / non-Android — best-effort only. Debug-only breadcrumb.
      assert(() {
        debugPrint('FlutterBluePlusElmChannel: clearGattCache best-effort '
            'failed (proceeding with retry): $e');
        return true;
      }());
    }
  }

  @override
  Future<void> write(List<int> bytes) async {
    final char = _writeChar;
    if (char == null) {
      // #2900 — the session was cleared by a confirmed drop (the catch below,
      // or a notify-stream error). Surface the recoverable typed disconnect —
      // NOT a raw StateError — so `_isTypedDisconnect` routes a post-drop write
      // through pause/reconnect and `recordObd2ReadFailure` de-noises it to a
      // breadcrumb, mirroring [ClassicElmChannel.write]'s `!_open` guard.
      throw const Obd2DisconnectedException(
        'FlutterBluePlusElmChannel: not open',
      );
    }
    // withoutResponse lets the adapter write as fast as BLE allows.
    try {
      await writeRaw(char, bytes);
    } catch (e, st) {
      // #2261 concern 1 — a write failure WHILE a disconnect edge is pending
      // confirms the drop immediately; a lone failure on a live link is a
      // debouncer no-op. #2466 — bin it as a recoverable transient (gated).
      final diag = Obd2CommDiagnostics.instance;
      if (diag.enabled) diag.noteConnectionEvent(failureReason: 'write-fail');
      _dropDebouncer.noteCommandFailure();
      // #2900 — a drop landing DURING the BLE write makes FBP throw a raw
      // disconnect exception ([isBleAdapterDisconnect]) that, left unwrapped,
      // [TripDropDetector] didn't recognise — so the ~1 Hz speed poller re-wrote
      // every cycle and each failure spooled an ERROR trace (error-log #23, 25×).
      // Reclassify into the recoverable [Obd2DisconnectedException] (the #2671
      // [ClassicElmChannel] + #2524 [BluetoothObd2Transport] precedents) and
      // clear the session so the next write short-circuits on the open-guard.
      if (isBleAdapterDisconnect(e)) {
        // #2907 — full session teardown on a write-time drop (was clearing
        // only `_open`/`_writeChar`), so a reconnect's open() starts clean.
        _clearSessionOnDrop();
        debugPrint('FlutterBluePlusElmChannel: write failed — reclassifying '
            'as a recoverable disconnect (#2900): $e\n$st');
        throw const Obd2DisconnectedException(
          'FlutterBluePlusElmChannel: write failed — adapter not connected',
        );
      }
      // A genuine non-disconnect BLE error still surfaces unchanged.
      // ignore: use_rethrow_when_possible
      throw e;
    }
  }

  /// The raw characteristic write, behind a [protected] [visibleForTesting]
  /// seam so a fault-injection test can drive [write]'s #2900 reclassification
  /// without a real BLE stack (a real [BluetoothCharacteristic] is not
  /// mockable).
  ///
  /// #3182 — write mode follows the RESOLVED characteristic's properties
  /// instead of a hardcoded `withoutResponse: true`: FBP fails loudly when
  /// asked for a write mode the characteristic doesn't advertise, so a clone
  /// whose write char only supports acknowledged writes could never receive a
  /// single command. `writeWithoutResponse` is still preferred whenever the
  /// adapter advertises it (fastest BLE write path).
  @protected
  @visibleForTesting
  Future<void> writeRaw(BluetoothCharacteristic char, List<int> bytes) =>
      char.write(bytes,
          withoutResponse: char.properties.writeWithoutResponse);

  /// #2900 test seam — prime an established session so a fault-injection test
  /// can drive [write] without the real connect path. #2907 — also wires
  /// `_notifyChar` + inert subscriptions so a test can prove a confirmed drop
  /// fully tears the session down (see [debugResidualSessionState]).
  @visibleForTesting
  void debugPrimeOpenSession(BluetoothCharacteristic writeChar) {
    _writeChar = writeChar;
    _notifyChar = writeChar;
    _open = true;
    _subscription ??= const Stream<List<int>>.empty().listen((_) {});
    _connStateSubscription ??=
        const Stream<BluetoothConnectionState>.empty().listen((_) {});
  }

  /// #2907 test seam — true while ANY per-session state survives a drop (the
  /// write/notify chars or either subscription); [_clearSessionOnDrop] clears
  /// them all.
  @visibleForTesting
  bool get debugResidualSessionState =>
      _notifyChar != null ||
      _writeChar != null ||
      _subscription != null ||
      _connStateSubscription != null;

  /// #2907 — fully clear per-session BLE state the instant a drop is confirmed
  /// (notify-stream error / write failure) so a subsequent [open] starts
  /// clean. Used to clear only `_open`/`_writeChar`, leaving `_notifyChar` +
  /// both subscriptions dangling for the next open to double-wire. Cancels
  /// fire-and-forget: it can run INSIDE the notify subscription's own
  /// `onError`, where awaiting its own cancellation would deadlock. `_incoming`
  /// is NOT closed here — [close] owns that.
  void _clearSessionOnDrop() {
    _open = false;
    _writeChar = null;
    _notifyChar = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_connStateSubscription?.cancel());
    _connStateSubscription = null;
  }

  @override
  Future<void> close() async {
    _closing = true;
    _open = false;
    _dropDebouncer.dispose();
    await _connStateSubscription?.cancel();
    _connStateSubscription = null;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _device.disconnect();
    } catch (e, st) {
      // OBD2/BLE layer, not local storage (#2379).
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'FlutterBluePlusElmChannel: disconnect failed'}));
    }
    // #2295 — close the broadcast controller (symmetry with
    // ClassicElmChannel.close()) so it doesn't leak across a reconnect.
    if (!_incoming.isClosed) await _incoming.close();
    _writeChar = null;
    _notifyChar = null;
  }
}
