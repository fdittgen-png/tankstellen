// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dtc_decoder.dart';
import 'mode01_reply_bytes.dart';
import 'health_signal_definitions.dart';

/// Raw replies → portable numeric evidence, with read-based coverage. No
/// component diagnosis, fabricated lambda or unsupported-PID inference.
class DiagnosticEvidence {
  final Map<String, _Signal> _signals = {};
  final Map<String, Map<String, int>> _outcomes = {};
  final Map<String, Set<String>> _dtcs = {};
  final Map<String, List<String>> _latestDtcs = {};
  final List<Map<String, Object?>> _faultChanges = [];
  int _droppedFaultChanges = 0;
  final Map<String, String> _freezeFrames = {};
  final Map<String, int> _fuelStates = {};
  Map<String, Object?> _vehicle = {};
  bool? _mil;
  int? _reportedDtcCount;
  List<int>? _readinessBytes;
  final Map<String, int> _oxygenPresence = {};
  bool _truncated = false, _ended = false;
  int _malformed = 0;
  static const int timelineRowCap = 20000;
  final List<Map<String, Object?>> _timeline = [];
  int _omittedTimelineRows = 0;

  void _recordTimeline(Map<String, Object?> row) {
    if (_timeline.length < timelineRowCap) {
      _timeline.add(row);
    } else {
      _omittedTimelineRows++;
    }
  }

  void addLine(String line) {
    try {
      final value = jsonDecode(line);
      if (value is Map<String, dynamic>) {
        _add(value);
      } else {
        _malformed++;
      }
    } on FormatException {
      _malformed++;
    }
  }

  void _add(Map<String, dynamic> m) {
    if (m['k'] == 'header') {
      final vehicle = m['vehicle'];
      if (vehicle is Map) {
        _vehicle = {
          for (final key in [
            'make',
            'model',
            'year',
            'engineCc',
            'fuel',
            'type',
          ])
            if (vehicle[key] is String || vehicle[key] is num)
              key: vehicle[key],
        };
      }
    }
    if (m['k'] == 'mark') {
      if (m['p'] == 'truncated') _truncated = true;
      if (m['p'] == 'end') _ended = true;
    }
    if (m['k'] != 'cmd' || m['c'] is! String) return;
    final c = (m['c'] as String).toUpperCase().replaceAll(' ', '');
    final r = m['r'] is String ? (m['r'] as String).toUpperCase() : '';
    final t = m['t'] is num ? (m['t'] as num).toInt() : null;
    final values = <String, Object?>{};
    var outcome = 'invalidReply';
    if (m.containsKey('e')) {
      outcome = 'error';
    } else if (r.contains('NO DATA') || r.contains('NODATA')) {
      outcome = 'noData';
    } else if (c.startsWith('01') && c.length == 4) {
      final pid = int.tryParse(c.substring(2), radix: 16);
      final b = pid == null ? null : mode01Bytes(r, pid);
      if (b != null) {
        for (final d in healthSignalDefinitions.where((d) => d.pid == pid)) {
          if (b.length < d.bytes) continue;
          final value = d.decode(b);
          if (value != null && value.isFinite && t != null) {
            (_signals[d.name] ??= _Signal()).add(value, t);
            values[d.name] = value;
            outcome = 'answered';
          }
        }
        if (pid == 0x13 || pid == 0x1D) {
          _oxygenPresence[c] = b[0];
          values['oxygenSensorPresenceByte'] = b[0];
          outcome = 'answered';
        }
        if (pid == 0x03 && b.length >= 2) {
          outcome = 'answered';
          values['fuelSystemStatusBytes'] = b.take(2).toList();
          for (var bank = 0; bank < b.length && bank < 2; bank++) {
            final state =
                'system${bank + 1}_0x${b[bank].toRadixString(16).padLeft(2, '0')}';
            _fuelStates[state] = (_fuelStates[state] ?? 0) + 1;
          }
        }
        if (pid == 0x01 && b.length >= 4) {
          outcome = 'answered';
          _mil = b[0] & 0x80 != 0;
          _reportedDtcCount = b[0] & 0x7F;
          _readinessBytes = b.take(4).toList();
          values['monitorStatusBytes'] = _readinessBytes;
        }
      }
    } else if (c == 'ATRV') {
      final v = double.tryParse(
        r.replaceAll('>', '').replaceAll('V', '').trim(),
      );
      if (v != null && v.isFinite && v > 0 && v < 30 && t != null) {
        (_signals['adapterVoltage'] ??= _Signal()).add(v, t);
        values['adapterVoltage'] = v;
        outcome = 'answered';
      }
    } else if (const ['03', '07', '0A', '020200'].contains(c)) {
      if (isCompleteDtcReply(c, r)) {
        final codes = decodeDtcReply(c, r.replaceAll('|', '\n'));
        (_dtcs[c] ??= {}).addAll(codes);
        if (jsonEncode(_latestDtcs[c]) != jsonEncode(codes)) {
          if (_faultChanges.length == 100) {
            _faultChanges.removeAt(0);
            _droppedFaultChanges++;
          }
          _faultChanges.add({'command': c, 'atEpochMs': t, 'codes': codes});
        }
        _latestDtcs[c] = codes;
        outcome = 'answered';
      }
    } else if (c.startsWith('02') && r.contains('42 ')) {
      _freezeFrames[c] = r;
      outcome = 'answered';
    }
    if (t != null && values.isNotEmpty) {
      _recordTimeline({
        'atEpochMs': t,
        'command': c,
        'values': values,
        if (m['ms'] is num) 'roundTripMs': m['ms'],
      });
    }
    final counts = _outcomes[c] ??= {};
    counts[outcome] = (counts[outcome] ?? 0) + 1;
  }

  Map<String, Object?> _command(String c) {
    final outcomes = _outcomes[c] ?? const <String, int>{};
    final attempts = outcomes.values.fold(0, (a, b) => a + b);
    return {
      'attempts': attempts,
      'outcomes': outcomes,
      'status': attempts == 0
          ? 'notRequested'
          : (outcomes['answered'] ?? 0) > 0
          ? 'answered'
          : 'requestedWithoutUsableReply',
    };
  }

  Map<String, Object?> toJson() => {
    'schema': 1,
    'systemScope': {
      'standardObd': 'Engine/emissions and supported standard signals only',
      'electrical': 'Supply-voltage evidence, not an electronics/module scan',
      'robotizedTransmission': {
        'assessment': 'notAssessed',
        'missingManufacturerSpecificEvidence': [
          'TCU fault scan', 'requested versus engaged gear',
          'clutch and selector requested versus actual position',
          'actuator current or force and adaptation state',
        ],
        'limits': 'Engine RPM/speed scores cannot establish a failed downshift, '
            'actuator force or engine power loss. Generic gear observations, '
            'when available, are not a complete transmission assessment.',
      },
      'absAirbagBodyModules': 'notAssessed',
      'ethanol': 'Only a supported measured PID52 establishes ethanol percentage; '
          'a profile fuel label or owner-reported E10 is not a measurement.',
    },
    'status': 'recorded',
    'vehicle': _vehicle,
    'completeTrace': _ended && !_truncated && _malformed == 0,
    'truncated': _truncated,
    'malformedLines': _malformed,
    'coverageBasis':
        'decodedReadings / commandAttempts; not trip-time coverage',
    'signals': {
      for (final d in healthSignalDefinitions)
        d.name: {
          'unit': d.unit,
          'command': d.command,
          ..._command(d.command),
          ...(_signals[d.name] ?? _Signal()).toJson(),
        },
      'adapterVoltage': {
        'unit': 'V',
        'command': 'ATRV',
        ..._command('ATRV'),
        ...(_signals['adapterVoltage'] ?? _Signal()).toJson(),
      },
    },
    'oxygenSensorPresenceBytes': _oxygenPresence,
    'fuelSystemStatus': {
      'command': '0103',
      ..._command('0103'),
      'counts': _fuelStates,
      'legend': {
        '0x01': 'openLoopInsufficientTemperature',
        '0x02': 'closedLoop',
        '0x04': 'openLoopLoadOrDeceleration',
        '0x08': 'openLoopSystemFailure',
        '0x10': 'closedLoopFeedbackFault',
      },
    },
    'faults': {
      'changes': _faultChanges,
      'droppedChanges': _droppedFaultChanges,
      'milOn': _mil,
      'reportedDtcCount': _reportedDtcCount,
      'monitorStatusBytes': _readinessBytes,
      for (final e in {
        'stored': '03',
        'pending': '07',
        'permanent': '0A',
        'freezeFrame': '020200',
      }.entries)
        e.key: {
          ..._command(e.value),
          'observedCodes': (_dtcs[e.value] ?? {}).toList()..sort(),
          'latestCodes': _latestDtcs[e.value],
        },
    },
    'freezeFrameReplies': _freezeFrames,
    'sensorTimeline': {
      'rows': _timeline,
      'rowCap': timelineRowCap,
      'omittedRows': _omittedTimelineRows,
      'resampled': false,
      'timeBasis':
          'adapter request epoch milliseconds; roundTripMs gives reply latency',
      'limits':
          'First rows retained when capped; statistics use all decoded readings. '
          'The separately downloadable raw NDJSON keeps the original command series.',
    },
    'limits':
        'First replying ECU per Mode01 command; diagnostic rates can be '
        'reduced on slow adapters. No answer is not proof of no fault. '
        'Narrowband O2 voltage is not an air/fuel ratio. A trim correction or '
        'retarded ignition alone does not diagnose a fuel pump or knock sensor. '
        'Generic OBD does not guarantee ABS, airbag or manufacturer-specific coverage.',
  };
}

class _Signal {
  int count = 0;
  double sum = 0;
  double? min, max, last;
  int? firstAt, lastAt, minAt, maxAt;
  int maxGapMs = 0;
  void add(double v, int t) {
    count++;
    sum += v;
    last = v;
    if (min == null || v < min!) {
      min = v;
      minAt = t;
    }
    if (max == null || v > max!) {
      max = v;
      maxAt = t;
    }
    firstAt ??= t;
    if (lastAt != null && t - lastAt! > maxGapMs) maxGapMs = t - lastAt!;
    lastAt = t;
  }

  Map<String, Object?> toJson() => {
    'decodedReadings': count,
    'mean': count == 0 ? null : sum / count,
    'min': min,
    'max': max,
    'last': last,
    'firstAtEpochMs': firstAt,
    'lastAtEpochMs': lastAt,
    'minAtEpochMs': minAt,
    'maxAtEpochMs': maxAt,
    'maxGapMs': count < 2 ? null : maxGapMs,
  };
}
