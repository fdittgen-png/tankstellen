// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Standard J1979 scalings. Narrowband voltage is NOT wideband phi/lambda;
/// fuel pressure is only available where the ECU exposes the corresponding PID.
class HealthSignalDefinition {
  const HealthSignalDefinition(
    this.pid,
    this.name,
    this.unit,
    this.bytes,
    this.decode,
  );
  final int pid, bytes;
  final String name, unit;
  final double? Function(List<int>) decode;
  String get command =>
      '01${pid.toRadixString(16).toUpperCase().padLeft(2, '0')}';
}

double _u16(List<int> b) => (b[0] * 256 + b[1]).toDouble();
double _trim(List<int> b) => (b[0] - 128) * 100 / 128;

final healthSignalDefinitions = <HealthSignalDefinition>[
  HealthSignalDefinition(0x04, 'engineLoad', '%', 1, (b) => b[0] * 100 / 255),
  HealthSignalDefinition(0x0C, 'rpm', 'rpm', 2, (b) => _u16(b) / 4),
  HealthSignalDefinition(0x0D, 'speed', 'km/h', 1, (b) => b[0].toDouble()),
  HealthSignalDefinition(0x05, 'coolant', 'degC', 1, (b) => b[0] - 40.0),
  for (final entry in {
    0x06: 'stftBank1',
    0x07: 'ltftBank1',
    0x08: 'stftBank2',
    0x09: 'ltftBank2',
  }.entries)
    HealthSignalDefinition(entry.key, entry.value, '%', 1, _trim),
  HealthSignalDefinition(
    0x0A,
    'fuelPressureGauge',
    'kPa',
    1,
    (b) => b[0] * 3.0,
  ),
  HealthSignalDefinition(
    0x22,
    'fuelRailPressureRelative',
    'kPa',
    2,
    (b) => _u16(b) * 0.079,
  ),
  HealthSignalDefinition(
    0x23,
    'fuelRailPressureGauge',
    'kPa',
    2,
    (b) => _u16(b) * 10,
  ),
  HealthSignalDefinition(0x0B, 'map', 'kPa', 1, (b) => b[0].toDouble()),
  HealthSignalDefinition(
    0x0F,
    'intakeAirTemperature',
    'degC',
    1,
    (b) => b[0] - 40.0,
  ),
  HealthSignalDefinition(
    0x0E,
    'ignitionTimingAdvance',
    'degBTDC',
    1,
    (b) => b[0] / 2 - 64,
  ),
  HealthSignalDefinition(0x10, 'maf', 'g/s', 2, (b) => _u16(b) / 100),
  HealthSignalDefinition(
    0x33,
    'barometricPressure',
    'kPa',
    1,
    (b) => b[0].toDouble(),
  ),
  HealthSignalDefinition(
    0x42,
    'controlModuleVoltage',
    'V',
    2,
    (b) => _u16(b) / 1000,
  ),
  HealthSignalDefinition(0x11, 'throttle', '%', 1, (b) => b[0] * 100 / 255),
  HealthSignalDefinition(0x49, 'pedal', '%', 1, (b) => b[0] * 100 / 255),
  HealthSignalDefinition(
    0x44,
    'commandedLambda',
    'lambda',
    2,
    (b) => _u16(b) / 32768,
  ),
  for (var pid = 0x14; pid <= 0x1B; pid++) ...[
    HealthSignalDefinition(
      pid,
      'o2Sensor${pid - 0x13}Voltage',
      'V',
      2,
      (b) => b[0] / 200,
    ),
    HealthSignalDefinition(
      pid,
      'o2Sensor${pid - 0x13}Trim',
      '%',
      2,
      (b) => b[1] == 0xFF ? null : (b[1] - 128) * 100 / 128,
    ),
  ],
  for (var pid = 0x24; pid <= 0x2B; pid++)
    HealthSignalDefinition(
      pid,
      'widebandVoltageSensor${pid - 0x23}Lambda',
      'lambda',
      4,
      (b) => _u16(b) / 32768,
    ),
  for (var pid = 0x34; pid <= 0x3B; pid++)
    HealthSignalDefinition(
      pid,
      'widebandCurrentSensor${pid - 0x33}Lambda',
      'lambda',
      4,
      (b) => _u16(b) / 32768,
    ),
];
