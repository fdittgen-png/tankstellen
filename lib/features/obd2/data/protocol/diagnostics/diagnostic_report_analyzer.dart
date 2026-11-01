// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4552 (Epic #4547) — one full-diagnostic trace (#4548) → a
/// [DiagnosticReport]. Pure and isolate-safe: the screen runs it via
/// `compute`, so a multi-hour trace never stalls the UI isolate.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'mode01_reply_bytes.dart';
import '../../../domain/diagnostics/diagnostic_report.dart';

/// Analyse the NDJSON [trace] text. Malformed lines are skipped.
DiagnosticReport analyzeDiagnosticRecording(String trace) {
  final a = _Analyzer();
  for (final line in const LineSplitter().convert(trace)) {
    if (line.isEmpty) continue;
    Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      continue; // a torn last line after a crash
    }
    if (decoded is Map<String, dynamic>) a.add(decoded);
  }
  return a.finish();
}

class _Analyzer {
  int? _t0;
  int _tLast = 0;
  int _readings = 0;
  final Set<String> _answered = {};
  final Set<String> _asked = {};

  // Latest values with their timestamps (ms).
  double? _rpm, _speed, _pedal, _volt;
  bool _pedalFromPedalPid = false; // 0149 pedal beats 0111 throttle
  int _rpmAt = -1, _speedAt = -1, _pedalAt = -1, _voltAt = -1;
  int? _gear;
  int _gearAt = -1;
  bool _gearReported = false;
  int? _engineStartAt; // first running reading of the current run
  int _runningMs = 0;
  int? _lastRunningAt;

  // Electrical.
  final List<double> _runningV = [];
  double? _restMin;
  int _dips = 0;
  int _lastDipAt = -1 << 40;

  // Drive episodes.
  final List<DriveEpisode> _episodes = [];
  int? _epStart;
  int _epLast = 0;
  double _epSpeed = 0, _epRpm = 0;
  double? _epPedal, _epVolt;
  bool _epNeutral = false;

  // Engine / mixture / emissions.
  double? _coolantMax;
  double? _coolant;
  double? _stft, _ltft;
  final List<double> _trims = [];
  int _warmReadings = 0, _openLoop = 0;
  double? _catMax, _evapMin, _evapMax;

  // Faults.
  bool? _mil;
  final Map<String, List<String>> _dtcs = {};

  static const int _fresh = 1500; // ms a value counts as current
  static const int _crankingMs = 5000;

  void add(Map<String, dynamic> m) {
    final t = (m['t'] as num?)?.toInt();
    if (t == null) return;
    _t0 ??= t;
    _tLast = math.max(_tLast, t);
    switch (m['k']) {
      case 'mark':
        if (m['p'] == 'dtc' && m['c'] is String && m['codes'] is List) {
          _dtcs[m['c'] as String] =
              (m['codes'] as List).whereType<String>().toList();
        }
      case 'cmd':
        final c = (m['c'] as String?)?.toUpperCase();
        if (c == null) return;
        _asked.add(c);
        final r = m['r'] as String?;
        if (r == null) return;
        final upper = r.toUpperCase();
        if (upper.contains('NO DATA') || upper.contains('?') ||
            upper.contains('UNABLE') || upper.contains('ERROR')) {
          return;
        }
        _readings++;
        _answered.add(c);
        _onReply(c, r, t);
    }
  }

  bool _isFresh(int at, int now) => at >= 0 && now - at <= _fresh;

  bool _running(int now) =>
      _rpm != null && _isFresh(_rpmAt, now) && _rpm! > 400;

  void _onReply(String c, String r, int t) {
    if (c == 'ATRV') {
      final v = double.tryParse(r.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (v != null && v > 5 && v < 20) _onVoltage(v, t);
      return;
    }
    if (!c.startsWith('01') || c.length != 4) return;
    final pid = int.tryParse(c.substring(2), radix: 16);
    if (pid == null) return;
    final b = mode01Bytes(r, pid);
    if (b == null) return;
    switch (pid) {
      case 0x0C when b.length >= 2:
        _rpm = (b[0] * 256 + b[1]) / 4;
        _rpmAt = t;
        _onEngine(t);
        _onDrive(t);
      case 0x0D:
        _speed = b[0].toDouble();
        _speedAt = t;
        _onDrive(t);
      case 0x11 when _pedalAt < 0 || !_pedalFromPedalPid:
        _pedal = b[0] * 100 / 255;
        _pedalAt = t;
      case 0x49:
        _pedalFromPedalPid = true;
        _pedal = b[0] * 100 / 255;
        _pedalAt = t;
      case 0x42 when b.length >= 2:
        final v = (b[0] * 256 + b[1]) / 1000;
        if (v > 5 && v < 20) _onVoltage(v, t);
      case 0xA4 when b.length >= 2:
        // [A1] = gear supported; [B7..B4] = actual gear (0 = neutral).
        if (b[0] & 0x02 != 0) {
          _gearReported = true;
          _gear = b[1] >> 4;
          _gearAt = t;
          _onDrive(t);
        }
      case 0x05:
        final c0 = b[0] - 40.0;
        _coolant = c0;
        _coolantMax = math.max(_coolantMax ?? c0, c0);
      case 0x06:
        _stft = (b[0] - 128) * 100 / 128;
        _onTrim(t);
      case 0x07:
        _ltft = (b[0] - 128) * 100 / 128;
        _onTrim(t);
      case 0x03:
        if (_running(t) && (_coolant ?? 0) >= EngineThresholds.coolantWarmC) {
          _warmReadings++;
          if (b[0] & 0x05 != 0) _openLoop++; // 1 = cold OL, 4 = load OL
        }
      case 0x3C when b.length >= 2:
        final c0 = (b[0] * 256 + b[1]) / 10 - 40;
        _catMax = math.max(_catMax ?? c0, c0);
      case 0x32 when b.length >= 2:
        var raw = b[0] * 256 + b[1];
        if (raw >= 0x8000) raw -= 0x10000;
        final pa = raw / 4;
        _evapMin = math.min(_evapMin ?? pa, pa);
        _evapMax = math.max(_evapMax ?? pa, pa);
      case 0x01:
        _mil = b[0] & 0x80 != 0;
    }
  }


  void _onEngine(int t) {
    if (_running(t)) {
      final last = _lastRunningAt;
      if (last == null || t - last > 10000) _engineStartAt = t;
      if (last != null && t - last <= 10000) _runningMs += t - last;
      _lastRunningAt = t;
    }
  }

  void _onVoltage(double v, int t) {
    _volt = v;
    _voltAt = t;
    if (_running(t)) {
      final start = _engineStartAt;
      if (start != null && t - start < _crankingMs) return;
      _runningV.add(v);
      if (v < ElectricalThresholds.dipV && t - _lastDipAt > 5000) _dips++;
      if (v < ElectricalThresholds.dipV) _lastDipAt = t;
    } else if (_rpm != null && _isFresh(_rpmAt, t)) {
      _restMin = math.min(_restMin ?? v, v);
    }
  }

  void _onTrim(int t) {
    if (_stft == null || _ltft == null || !_running(t)) return;
    if ((_coolant ?? 0) < EngineThresholds.coolantWarmC) return;
    _trims.add(_stft! + _ltft!);
  }

  void _onDrive(int t) {
    final rpm = _rpm, speed = _speed;
    if (rpm == null || speed == null) return;
    if (!_isFresh(_rpmAt, t) || !_isFresh(_speedAt, t)) return;
    final pedal = _isFresh(_pedalAt, t) ? _pedal : null;
    final neutral = _gearReported &&
        _isFresh(_gearAt, t) &&
        _gear == 0 &&
        speed >= DriveThresholds.minSpeedKmh;
    final starved = speed >= DriveThresholds.minSpeedKmh &&
        speed <= DriveThresholds.maxSpeedKmh &&
        rpm > 0 &&
        rpm < DriveThresholds.maxRpm &&
        (pedal ?? 0) >= DriveThresholds.minPedalPct;
    if (neutral || starved) {
      final start = _epStart;
      if (start == null || t - _epLast > 3000) {
        _closeEpisode();
        _epStart = t;
        _epSpeed = speed;
        _epRpm = rpm;
        _epPedal = pedal;
        _epVolt = _isFresh(_voltAt, t) ? _volt : null;
        _epNeutral = neutral;
      } else {
        _epNeutral = _epNeutral || neutral;
        if (_isFresh(_voltAt, t) && _volt != null) {
          _epVolt = math.min(_epVolt ?? _volt!, _volt!);
        }
      }
      _epLast = t;
    } else if (_epStart != null && t - _epLast > 3000) {
      _closeEpisode();
    }
  }

  void _closeEpisode() {
    final start = _epStart;
    if (start == null) return;
    _epStart = null;
    // One stray reading is noise (unless the gearbox said neutral).
    if (_epLast == start && !_epNeutral) return;
    _episodes.add(DriveEpisode(
      at: Duration(milliseconds: start - (_t0 ?? start)),
      duration: Duration(milliseconds: _epLast - start),
      speedKmh: _epSpeed,
      rpm: _epRpm,
      pedalPct: _epPedal,
      voltageV: _epVolt,
      neutral: _epNeutral,
    ));
  }

  DiagnosticReport finish() {
    _closeEpisode();
    return DiagnosticReport(
      duration: Duration(milliseconds: _tLast - (_t0 ?? _tLast)),
      readings: _readings,
      distinctValues: _answered.length,
      electrical: _electrical(),
      transmission: _transmission(),
      engine: _engine(),
      mixture: _mixture(),
      emissions: _emissions(),
      faults: _faults(),
      unanswered: (_asked
          .difference(_answered)
          .where((c) => !c.startsWith('AT'))
          .toList()
        ..sort()),
    );
  }

  ElectricalHealth _electrical() {
    if (_runningV.isEmpty) {
      final rest = _restMin;
      return ElectricalHealth(
        verdict: rest == null
            ? HealthVerdict.notReported
            : rest >= ElectricalThresholds.restGoodV
                ? HealthVerdict.good
                : HealthVerdict.check,
        restV: rest,
      );
    }
    final avg = _runningV.reduce((x, y) => x + y) / _runningV.length;
    final min = _runningV.reduce(math.min);
    final max = _runningV.reduce(math.max);
    final verdict = (avg < ElectricalThresholds.chargingProblemV || _dips > 0)
        ? HealthVerdict.problem
        : (avg < ElectricalThresholds.chargingLowV ||
                max > ElectricalThresholds.chargingHighV ||
                (_restMin != null &&
                    _restMin! < ElectricalThresholds.restGoodV))
            ? HealthVerdict.check
            : HealthVerdict.good;
    return ElectricalHealth(
      verdict: verdict,
      runningAvgV: avg,
      runningMinV: min,
      runningMaxV: max,
      dipCount: _dips,
      restV: _restMin,
    );
  }

  TransmissionHealth _transmission() {
    final sawDrive = _answered.contains('010D') && _answered.contains('010C');
    if (!sawDrive || (!_gearReported && _episodes.isEmpty)) {
      return const TransmissionHealth(
          verdict: HealthVerdict.notReported, gearReported: false);
    }
    final verdict = _episodes.isEmpty
        ? HealthVerdict.good
        : _episodes.length >= 2 || _episodes.any((e) => e.neutral)
            ? HealthVerdict.problem
            : HealthVerdict.check;
    return TransmissionHealth(
      verdict: verdict,
      gearReported: _gearReported,
      episodes: List.unmodifiable(_episodes),
    );
  }

  EngineHealth _engine() {
    final max = _coolantMax;
    final minutes = _runningMs ~/ 60000;
    if (max == null) {
      return EngineHealth(
          verdict: HealthVerdict.notReported, runningMinutes: minutes);
    }
    final verdict = max > EngineThresholds.coolantHotC
        ? HealthVerdict.problem
        : (max < EngineThresholds.coolantWarmC &&
                minutes >= EngineThresholds.warmUpMinutes)
            ? HealthVerdict.check
            : HealthVerdict.good;
    return EngineHealth(
        verdict: verdict, coolantMaxC: max, runningMinutes: minutes);
  }

  MixtureHealth _mixture() {
    final openShare = _warmReadings == 0 ? null : _openLoop / _warmReadings;
    if (_trims.isEmpty) {
      return MixtureHealth(
          verdict: HealthVerdict.notReported, openLoopShare: openShare);
    }
    final avg = _trims.reduce((x, y) => x + y) / _trims.length;
    final verdict = avg.abs() > MixtureThresholds.problemPct
        ? HealthVerdict.problem
        : avg.abs() > MixtureThresholds.checkPct
            ? HealthVerdict.check
            : HealthVerdict.good;
    return MixtureHealth(
        verdict: verdict, avgTrimPct: avg, openLoopShare: openShare);
  }

  EmissionsHealth _emissions() {
    if (_catMax == null && _evapMin == null) {
      return const EmissionsHealth(verdict: HealthVerdict.notReported);
    }
    final verdict = (_catMax ?? 0) > EmissionsThresholds.catalystHotC
        ? HealthVerdict.problem
        : HealthVerdict.good;
    return EmissionsHealth(
      verdict: verdict,
      catalystMaxC: _catMax,
      evapMinPa: _evapMin,
      evapMaxPa: _evapMax,
    );
  }

  FaultCodeHealth _faults() {
    final stored = _dtcs['03'] ?? const <String>[];
    final pending = _dtcs['07'] ?? const <String>[];
    final permanent = _dtcs['0A'] ?? const <String>[];
    final freeze = _dtcs['020200'] ?? const <String>[];
    final asked = _answered.contains('03') || _answered.contains('0101');
    final verdict = !asked && _mil == null
        ? HealthVerdict.notReported
        : (_mil ?? false) || stored.isNotEmpty || permanent.isNotEmpty
            ? HealthVerdict.problem
            : pending.isNotEmpty
                ? HealthVerdict.check
                : HealthVerdict.good;
    return FaultCodeHealth(
      verdict: verdict,
      milOn: _mil,
      stored: stored,
      pending: pending,
      permanent: permanent,
      freezeFrame: freeze,
    );
  }
}
