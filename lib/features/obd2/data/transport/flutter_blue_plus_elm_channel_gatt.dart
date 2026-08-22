// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'flutter_blue_plus_elm_channel.dart';

/// GATT discovery / notify-bind / write / teardown family for
/// [FlutterBluePlusElmChannel], extracted from the channel file as a `part`
/// so it keeps private-member access while the channel stays under the
/// #1680 file-length cap (sanctioned #3760 decomposition — move-only,
/// behaviour preserved). Free functions (NOT an `extension`) so the thin
/// delegating instance methods stay virtually dispatchable for test fakes.

/// Body of [FlutterBluePlusElmChannel.discoverAndBind] (#3014).
Future<void> _discoverAndBindImpl(FlutterBluePlusElmChannel c) async {
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
  final services = await c._device.discoverServices(
      timeout: FlutterBluePlusElmChannel._discoverTimeoutSecs);
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
    hintServiceUuid: c._uuids.service.str,
    hintWriteCharUuid: c._uuids.writeChar.str,
    hintNotifyCharUuid: c._uuids.notifyChar.str,
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
      'BLE device ${c._device.remoteId.str} exposes no ELM327 service with a '
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
  c._writeChar = service.characteristics.firstWhere(
    (ch) => ch.uuid.str.toLowerCase() == resolved.writeCharUuid.toLowerCase(),
  );
  c._notifyChar = service.characteristics.firstWhere(
    (ch) => ch.uuid.str.toLowerCase() == resolved.notifyCharUuid.toLowerCase(),
  );
  // #3014 — bound setNotifyValue on its own short budget too.
  // #3182 — via FBP's own `timeout:` (mutex released at our budget; the
  // outer Dart `.timeout()` left it held up to 15 s — see above).
  // #3181 — through [FlutterBluePlusElmChannel.enableNotify]: a
  // FIRST-connect deviceId gets the generous pairing budget (the CX pairs
  // via this very subscribe).
  await c.enableNotify();
  c._subscription = c._notifyChar!.lastValueStream.listen(
    c.handleNotifyBytes,
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
        _clearSessionOnDrop(c);
        if (!c._incoming.isClosed) {
          c._incoming.addError(
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
      if (!c._incoming.isClosed) c._incoming.addError(e, st);
      // OBD2/BLE GATT/ATT error → `other` ("not yet classified", #2379).
      // Kept logged: a real link drop worth seeing in release triage.
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'FlutterBluePlusElmChannel notify error'}));
    },
  );
}

/// Body of [FlutterBluePlusElmChannel.enableNotify] (#3181) — enable
/// notifications on the resolved CCCD, with the FIRST-CONNECT pairing
/// budget. The OBDLink CX initiates BLE pairing via this very subscribe:
/// on a never-bonded phone `setNotifyValue` blocks on the OS pairing
/// dialog, and the steady-state budget (iOS 7 s / Android 4 s) clipped the
/// human tap. A deviceId in [Obd2PairingMode] first-connect mode gets
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
Future<void> _enableNotifyImpl(FlutterBluePlusElmChannel c) async {
  final deviceId = c._device.remoteId.str;
  final firstConnect = Obd2PairingMode.isFirstConnect(deviceId);
  final notifySecs = Obd2PairingMode.setNotifyBudgetSecsFor(
    deviceId,
    platformDefaultSecs: FlutterBluePlusElmChannel._setNotifyTimeoutSecs,
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
    await c.rawSetNotify(notifySecs);
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

/// #3014 — adapt the discovered FBP [BluetoothService]s into the pure
/// [GattServiceDescriptor] shape the platform-free [resolveElmGatt] matcher
/// consumes. Reads each characteristic's GATT properties so the matcher can
/// pick write/notify by capability rather than exact UUID.
List<GattServiceDescriptor> _toDescriptors(List<BluetoothService> services) =>
    [
      for (final s in services)
        GattServiceDescriptor(
          uuid: s.uuid.str,
          characteristics: [
            for (final ch in s.characteristics)
              GattCharDescriptor(
                uuid: ch.uuid.str,
                write: ch.properties.write,
                writeWithoutResponse: ch.properties.writeWithoutResponse,
                notify: ch.properties.notify,
                indicate: ch.properties.indicate,
              ),
          ],
        ),
    ];

/// Body of [FlutterBluePlusElmChannel.refreshGattCache] (#3014) — best-effort
/// drop of the native Android GATT service cache between connect retries on a
/// GATT_ERROR 133 (a cache-poisoned device). FBP's `clearGattCache` is the
/// Android-only hidden-API `BluetoothGatt.refresh()` shim; it throws
/// `androidOnly` off Android and can throw on an OEM that blocks the
/// reflection — both are swallowed (the retry proceeds regardless). Never
/// throws (#1103): the transport calls this on the failure path where any
/// escape would mask the real connect error.
Future<void> _refreshGattCacheImpl(FlutterBluePlusElmChannel c) async {
  try {
    await c._device.clearGattCache();
    // best-effort OEM-variable reflection; swallowed so a refresh failure
    // can't mask the real connect error on the retry.
    // ignore: catch_no_st
  } catch (e) {
    // OEM-variable / non-Android — best-effort only. Debug-only breadcrumb.
    assert(() {
      debugPrint('FlutterBluePlusElmChannel: clearGattCache best-effort '
          'failed (proceeding with retry): $e');
      return true;
    }(), 'debug-only breadcrumb — the closure always returns true');
  }
}

/// Body of [FlutterBluePlusElmChannel.write] (#3760).
Future<void> _writeChannel(
    FlutterBluePlusElmChannel c, List<int> bytes) async {
  final char = c._writeChar;
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
    await c.writeRaw(char, bytes);
  } catch (e, st) {
    // #2261 concern 1 — a write failure WHILE a disconnect edge is pending
    // confirms the drop immediately; a lone failure on a live link is a
    // debouncer no-op. #2466 — bin it as a recoverable transient (gated).
    final diag = Obd2CommDiagnostics.instance;
    if (diag.enabled) diag.noteConnectionEvent(failureReason: 'write-fail');
    c._dropDebouncer.noteCommandFailure();
    // #2900 — a drop landing DURING the BLE write makes FBP throw a raw
    // disconnect exception ([isBleAdapterDisconnect]) that, left unwrapped,
    // [TripDropDetector] didn't recognise (error-log #23, 25×). Reclassify
    // into the recoverable [Obd2DisconnectedException] (the #2671 / #2524
    // precedents) and clear the session so the next write short-circuits.
    if (isBleAdapterDisconnect(e)) {
      // #2907 — full session teardown on a write-time drop (was clearing
      // only `_open`/`_writeChar`), so a reconnect's open() starts clean.
      _clearSessionOnDrop(c);
      debugPrint('FlutterBluePlusElmChannel: write failed — reclassifying '
          'as a recoverable disconnect (#2900): $e\n$st');
      throw const Obd2DisconnectedException(
        'FlutterBluePlusElmChannel: write failed — adapter not connected',
      );
    }
    // A genuine non-disconnect BLE error still surfaces unchanged.
    rethrow;
  }
}

/// #2907 — fully clear per-session BLE state the instant a drop is confirmed
/// (notify-stream error / write failure) so a subsequent
/// [FlutterBluePlusElmChannel.open] starts clean. Used to clear only
/// `_open`/`_writeChar`, leaving `_notifyChar` + both subscriptions dangling
/// for the next open to double-wire. Cancels fire-and-forget: it can run
/// INSIDE the notify subscription's own `onError`, where awaiting its own
/// cancellation would deadlock. `_incoming` is NOT closed here —
/// [FlutterBluePlusElmChannel.close] owns that.
void _clearSessionOnDrop(FlutterBluePlusElmChannel c) {
  c._open = false;
  c._writeChar = null;
  c._notifyChar = null;
  unawaited(c._subscription?.cancel());
  c._subscription = null;
  unawaited(c._connStateSubscription?.cancel());
  c._connStateSubscription = null;
}

/// Body of [FlutterBluePlusElmChannel.close] (#3760).
Future<void> _closeChannel(FlutterBluePlusElmChannel c) async {
  c._closing = true;
  c._open = false;
  c._dropDebouncer.dispose();
  await c._connStateSubscription?.cancel();
  c._connStateSubscription = null;
  await c._subscription?.cancel();
  c._subscription = null;
  try {
    await c._device.disconnect();
  } catch (e, st) {
    // OBD2/BLE layer, not local storage (#2379).
    unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'FlutterBluePlusElmChannel: disconnect failed'}));
  }
  // #2295 — close the broadcast controller (symmetry with
  // ClassicElmChannel.close()) so it doesn't leak across a reconnect.
  if (!c._incoming.isClosed) await c._incoming.close();
  c._writeChar = null;
  c._notifyChar = null;
}
