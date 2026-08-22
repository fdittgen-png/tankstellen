// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connection_service.dart';

/// Scan + pinned-scan connect bodies for [Obd2ConnectionService],
/// extracted as a `part` (#3760 decomposition — move-only, behaviour
/// preserved) so the service file stays under the #1680 file-length cap.
///
/// Free functions (NOT an `extension`) — the `obd2_connect_by_mac.dart`
/// precedent — so the thin delegating instance methods on
/// [Obd2ConnectionService] stay virtually dispatchable for test fakes;
/// `part`-file privacy is library-level, so these reach the service's
/// private `_lastRanked` and the sibling parts' [_traced] helper.

/// Body of [Obd2ConnectionService.scan] (#3760 — move-only). Emits the
/// accumulated ranked candidate list on every scan-results change.
Stream<List<ResolvedObd2Candidate>> _scanImpl(
  Obd2ConnectionService svc, {
  required Duration timeout,
}) async* {
  // #3184(f) — picker-UI scans get a trace too. A standalone scan ("I
  // scanned and saw nothing") previously left NO artefact. When a
  // connect entry already opened a trace, this begin returns a CHILD
  // recording into the same trace (and the end/outcome below become
  // no-ops via [Obd2ConnectTraceHandle.isRoot]), so connect-path
  // behaviour is unchanged.
  final scanTrace =
      Obd2ConnectTraceLog.beginTrace(origin: Obd2ConnectOrigin.pickerScan);
  var sawAny = false;
  try {
    final state = await svc.permissions.request();
    if (state != Obd2PermissionState.granted) {
      throw const Obd2PermissionDenied();
    }

    // #3185 — pace the radio scan start through the governor so a dense
    // connect episode can't trip Android's silent 5-scans/30s throttle
    // (fails open; a pause stamps a `scan-throttle` step).
    await svc.scanGovernor.admitScanStart(reason: 'service-scan');

    final accumulated = <String, Obd2AdapterCandidate>{};

    // #3097 — scan UNFILTERED: a withServices filter starves iOS of name-only
    // ELM327 clones; registry.rank still drops non-adapter noise post-scan.
    final bleStream =
        svc.bluetooth.scan(serviceUuids: const {}, timeout: timeout);
    final classicStream = svc.classicBluetooth?.scan(timeout: timeout) ??
        const Stream<List<Obd2AdapterCandidate>>.empty();

    // #761 — merge BLE + Classic scan streams. Both emit the
    // accumulated-so-far list each tick, so we key by deviceId and
    // re-rank on every event. Closing either stream doesn't end the
    // merged stream — the window is the OUTER [timeout], enforced
    // by the facades themselves.
    final merged = StreamGroup.merge<List<Obd2AdapterCandidate>>(
      [bleStream, classicStream],
    );

    // #2969 — record each newly-seen ranked candidate into the active
    // connect trace so a failed connect's trace carries the scan list
    // (device + RSSI + matched profile + transport). Deduped by MAC so a
    // repeating batch doesn't spam the capped list.
    final tracedScanMacs = <String>{};
    // #3184(e)/#3168 — deviceIds already stamped `pinned-id-mismatch`.
    final mismatchStamped = <String>{};
    await for (final batch in merged) {
      for (final c in batch) {
        accumulated[c.deviceId] = c;
      }
      final ranked = svc.registry.rank(accumulated.values.toList());
      if (ranked.isNotEmpty) sawAny = true;
      svc._lastRanked = ranked;
      final trace = Obd2ConnectTraceLog.active;
      if (trace != null) {
        for (final r in ranked) {
          if (tracedScanMacs.add(r.candidate.deviceId)) {
            trace.recordScan(
              mac: r.candidate.deviceId,
              name: r.candidate.deviceName,
              rssi: r.candidate.rssi,
              transport: r.profile.transport == BluetoothTransport.classic
                  ? Obd2ConnectTransport.classic
                  : Obd2ConnectTransport.ble,
              matchedProfileId: r.profile.id,
            );
          }
          _stampPinnedIdMismatch(trace, r, mismatchStamped);
        }
      }
      yield ranked;
    }
    if (!sawAny) {
      throw const Obd2ScanTimeout();
    }
    // classification-only binding; rethrow preserves the stack.
    // ignore: catch_no_st
  } catch (e) {
    if (scanTrace.isRoot) scanTrace.setOutcomeFromError(e);
    rethrow;
  } finally {
    if (scanTrace.isRoot && !scanTrace.hasOutcome) {
      scanTrace.setOutcome(sawAny
          ? Obd2ConnectOutcome.success
          : Obd2ConnectOutcome.scanEmpty);
    }
    Obd2ConnectTraceLog.endTrace(scanTrace);
  }
}

/// #3184(e) — the #3168 discriminator: a scanned device whose NAME
/// matches the pinned adapter's name but whose deviceId DIFFERS. On iOS
/// the deviceId is a per-app CBPeripheral UUID (not the MAC) and can
/// rotate after an unpair / restore / adapter re-provision — the pinned
/// id then dials a ghost while the real adapter advertises under a new
/// id. This step makes that visible in the field trace: see #3168.
void _stampPinnedIdMismatch(
  Obd2ConnectTraceHandle trace,
  ResolvedObd2Candidate r,
  Set<String> stamped,
) {
  final pinnedMac = trace.rawRequestedMac;
  final pinnedName = trace.adapterName;
  if (pinnedMac == null || pinnedMac.isEmpty) return;
  if (pinnedName == null || pinnedName.isEmpty) return;
  final c = r.candidate;
  if (c.deviceName != pinnedName) return;
  if (c.deviceId.toUpperCase() == pinnedMac.toUpperCase()) return;
  if (!stamped.add(c.deviceId)) return;
  trace.addStep(
    label: 'pinned-id-mismatch',
    status: Obd2ConnectStepStatus.fail,
    detail: 'scanned "${c.deviceName}" under id '
        '${redactObd2Mac(c.deviceId)} but the pinned id is '
        '${redactObd2Mac(pinnedMac)} — iOS UUID-vs-MAC identity drift? '
        '(#3168)',
  );
}

/// Body of [Obd2ConnectionService.connectByMac] (#3760 — move-only): the
/// pinned-adapter short scan + exact-id match + #3168 UUID-rotation
/// rematch, wrapped in the shared [_traced] connect trace.
Future<Obd2Service?> _connectByMacImpl(
  Obd2ConnectionService svc,
  String mac, {
  required Duration timeout,
  String? adapterName,
}) =>
    _traced(
      origin: Obd2ConnectOrigin.firstConnect,
      mac: mac,
      adapterName: adapterName,
      // #3014 — was hard-coded `unknown`. When the caller passes the paired
      // name, infer the transport from the registry name matchers (the same
      // recovery the self-test uses) so the trace records `ble`/`classic`
      // instead of `unknown` for a scan-based pinned connect.
      requestedTransport:
          _inferTransport(svc.registry.transportForName(adapterName)),
      body: () async {
        final stream = svc.scan(timeout: timeout);
        ResolvedObd2Candidate? match;
        // #3168 — the latest accumulated ranked list, retained for the
        // UUID-rotation rematch when no exact deviceId match is found.
        var ranked = const <ResolvedObd2Candidate>[];
        try {
          await for (final batch in stream) {
            ranked = batch;
            for (final c in batch) {
              if (c.candidate.deviceId == mac) {
                match = c;
                break;
              }
            }
            if (match != null) break;
          }
        } on Obd2ScanTimeout {
          // No adapters at all in range — fall through to picker.
          return null;
        }
        if (match != null) return svc.connect(match);
        // #3168 — exact id absent from a NON-empty scan: on iOS the
        // pinned CBPeripheral UUID may have ROTATED. Try the name-based
        // rematch (+ re-persist of the fresh id on success); a no-match
        // still returns null so the picker fallback is unchanged. #3247 —
        // the fresh id inherits known-good status (skips pairing mode).
        return connectUuidRematched(
          pinnedId: mac,
          pinnedName: adapterName,
          ranked: ranked,
          connect: svc.connect,
          onIdentityRotated: svc.onAdapterIdentityRotated,
          markFreshIdKnownGood: svc.knownAdaptersStore?.markKnownGood,
        );
      },
    );

/// #3014 — map a nullable registry [BluetoothTransport] hint onto the trace's
/// [Obd2ConnectTransport] (null ⇒ `unknown`, the honest no-hint state).
Obd2ConnectTransport _inferTransport(BluetoothTransport? t) =>
    switch (t) {
      BluetoothTransport.classic => Obd2ConnectTransport.classic,
      BluetoothTransport.ble => Obd2ConnectTransport.ble,
      null => Obd2ConnectTransport.unknown,
    };
