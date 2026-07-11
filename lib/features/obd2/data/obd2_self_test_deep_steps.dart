// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_self_test_driver.dart';

/// The #3555 deep-diagnostic layer steps (phone-Bluetooth / negotiated
/// protocol / sustained-polling soak), in their own `part` so the original
/// step file stays under the 400-line cap. Everything here is `_`-private
/// to the self-test library, mirroring `obd2_self_test_steps.dart`.

/// #3555 layer 0 — the PHONE's Bluetooth radio, via the same
/// [Obd2ConnectTraceLog.adapterStateProbe] seam every connect trace uses
/// (FBP's cached last-known state, no platform call). Also states the
/// dial plan (pinned adapter + transport route) so the report opens with
/// the full picture of what the test is about to attempt.
Obd2SelfTestStepResult _bluetoothStep({
  required String? pinnedMac,
  required Obd2ConnectTransport? transportHint,
  required String? adapterName,
}) {
  final radio = Obd2ConnectTraceLog.adapterStateProbe?.call();
  final plan = pinnedMac == null
      ? 'no pinned adapter (scan)'
      : [
          adapterName ?? 'pinned adapter',
          transportHint?.name ?? 'transport auto',
        ].join(' \u00b7 ');
  final detail = 'radio ${radio ?? 'unknown'} \u00b7 $plan';
  final status = switch (radio) {
    // A cached unknown (probe unwired / FBP not yet queried) is
    // indeterminate, NOT a fault — the connect step settles it either way,
    // so it must not cost an otherwise-perfect run its `passed` verdict.
    'on' || null || 'unknown' => Obd2SelfTestStepStatus.ok,
    // off / turningOff / unavailable / unauthorized — the radio layer is
    // the failure, and every later step inherits it.
    _ => Obd2SelfTestStepStatus.fail,
  };
  return _step(Obd2SelfTestStepId.bluetooth, status, null, detail: detail);
}

/// ELM327 protocol digit → human bus name (#3555). Digits per the ELM327
/// datasheet (`ATDPN`; a leading `A` marks auto-negotiated).
// i18n-ignore: OBD protocol standard names — technical identifiers.
const Map<String, String> _kElmProtocolNames = {
  '1': 'SAE J1850 PWM',
  '2': 'SAE J1850 VPW',
  '3': 'ISO 9141-2',
  '4': 'ISO 14230-4 KWP (5-baud)',
  '5': 'ISO 14230-4 KWP (fast)',
  '6': 'ISO 15765-4 CAN (11-bit, 500k)',
  '7': 'ISO 15765-4 CAN (29-bit, 500k)',
  '8': 'ISO 15765-4 CAN (11-bit, 250k)',
  '9': 'ISO 15765-4 CAN (29-bit, 250k)',
  'A': 'SAE J1939 CAN',
  'B': 'user-defined CAN 1',
  'C': 'user-defined CAN 2',
};

/// #3555 layer 3 — WHICH OBD protocol the ELM negotiated: raw `ATDPN`.
/// `A6` ⇒ auto-found ISO 15765-4 CAN; a bare `0` means no protocol was
/// ever negotiated — on a silent (engine-off) bus that is the expected
/// non-fault signature, so it maps to `noResponse`, not a red fail.
Future<Obd2SelfTestStepResult> _protocolStep(
  Obd2Service service,
  Obd2CommDiagnostics diag,
  Duration deadline,
) async {
  final sw = Stopwatch()..start();
  try {
    final raw = await service
        .sendCommand(Elm327Protocol.describeProtocolNumberCommand)
        .timeout(deadline);
    sw.stop();
    diag.recordHandshakeLine('ATDPN', raw, sw.elapsedMilliseconds);
    final cleaned = raw.replaceAll(RegExp(r'[\r\n>]'), '').trim().toUpperCase();
    if (cleaned.isEmpty || cleaned.contains('?')) {
      return _step(Obd2SelfTestStepId.protocol, Obd2SelfTestStepStatus.garbage,
          sw.elapsedMilliseconds,
          detail: cleaned.isEmpty ? null : cleaned);
    }
    final auto = cleaned.startsWith('A');
    final digit = auto ? cleaned.substring(1) : cleaned;
    if (digit == '0') {
      return _step(Obd2SelfTestStepId.protocol,
          Obd2SelfTestStepStatus.noResponse, sw.elapsedMilliseconds,
          detail: 'no protocol negotiated (silent bus)');
    }
    final name = _kElmProtocolNames[digit];
    if (name == null) {
      return _step(Obd2SelfTestStepId.protocol, Obd2SelfTestStepStatus.garbage,
          sw.elapsedMilliseconds,
          detail: cleaned);
    }
    return _step(Obd2SelfTestStepId.protocol, Obd2SelfTestStepStatus.ok,
        sw.elapsedMilliseconds,
        detail: auto ? '$name \u00b7 auto [$cleaned]' : '$name [$cleaned]');
  } on TimeoutException {
    sw.stop();
    diag.recordHandshakeLine('ATDPN', 'TIMEOUT', sw.elapsedMilliseconds);
    return _step(Obd2SelfTestStepId.protocol, Obd2SelfTestStepStatus.timeout,
        sw.elapsedMilliseconds);
  } catch (e, st) {
    sw.stop();
    debugPrint('OBD2 self-test protocol step failed: $e\n$st');
    return _step(Obd2SelfTestStepId.protocol, Obd2SelfTestStepStatus.fail,
        sw.elapsedMilliseconds,
        detail: e.runtimeType.toString());
  }
}

/// #3555 layer 5 — sustained polling at recording cadence: [_kSoakReads]
/// alternating RPM/speed reads back-to-back (the scheduler's hot path),
/// reporting success rate + p50/max round-trip. Catches the "connects
/// fine, dies under load" class no single read shows (buffer overruns,
/// adaptive-timing collapse, a socket that only wedges under pressure).
const int _kSoakReads = 12;

Future<Obd2SelfTestStepResult> _soakStep(
  Obd2Service service,
  Obd2CommDiagnostics diag,
  Duration deadline,
) async {
  const pids = ['010C', '010D'];
  var ok = 0;
  var noData = 0;
  final rtts = <int>[];
  final sw = Stopwatch()..start();
  for (var i = 0; i < _kSoakReads; i++) {
    final pid = pids[i % pids.length];
    diag.noteDispatch(pid);
    final pidSw = Stopwatch()..start();
    try {
      final raw = await service.sendCommand('$pid\r').timeout(deadline);
      pidSw.stop();
      rtts.add(pidSw.elapsedMilliseconds);
      final cls = classifyObd2Response(raw);
      diag.noteResult(pid, cls, rttMs: pidSw.elapsedMilliseconds);
      if (cls == ResponseClass.ok) ok++;
      if (cls == ResponseClass.noData) noData++;
    } on TimeoutException {
      pidSw.stop();
      diag.noteResult(pid, ResponseClass.timeout,
          rttMs: pidSw.elapsedMilliseconds);
    } catch (_) {
      pidSw.stop();
    }
  }
  sw.stop();
  rtts.sort();
  final p50 = rtts.isEmpty ? null : rtts[rtts.length ~/ 2];
  final max = rtts.isEmpty ? null : rtts.last;
  final detail = 'ok $ok/$_kSoakReads'
      '${p50 == null ? '' : ' \u00b7 p50 ${p50}ms \u00b7 max ${max}ms'}';
  // Rate → status: >=90% ok is a healthy link. A NO-DATA-dominated run
  // with ZERO real answers is the engine-off signature — but even one
  // parsed value proves the engine is ON, so a mixed rate is a DEGRADED
  // link (garbage), never engine-off. No answers of any kind = the
  // adapter itself went silent (timeout-class fault).
  final Obd2SelfTestStepStatus status;
  if (ok >= (_kSoakReads * 0.9).ceil()) {
    status = Obd2SelfTestStepStatus.ok;
  } else if (ok == 0 && noData >= _kSoakReads ~/ 2) {
    status = Obd2SelfTestStepStatus.noResponse;
  } else if (ok + noData == 0) {
    status = Obd2SelfTestStepStatus.timeout;
  } else {
    status = Obd2SelfTestStepStatus.garbage;
  }
  return _step(Obd2SelfTestStepId.soak, status, sw.elapsedMilliseconds,
      detail: detail);
}
