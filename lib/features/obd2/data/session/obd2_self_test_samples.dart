// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../protocol/elm327_protocol.dart';

/// The live values the #2645 / #3555 adapter self-test reads, named by the
/// adapter's request constants instead of hex strings (#4159). The comm
/// diagnostics key each request by its bare command (`command.trim()`).
///
/// The sample-reads step sends these in order: RPM, speed, coolant.
const List<String> kSelfTestSampleCommands = [
  Elm327Protocol.engineRpmCommand,
  Elm327Protocol.vehicleSpeedCommand,
  Elm327Protocol.coolantTempCommand,
];

/// The soak step alternates these back-to-back: RPM, speed.
const List<String> kSelfTestSoakCommands = [
  Elm327Protocol.engineRpmCommand,
  Elm327Protocol.vehicleSpeedCommand,
];

/// The comm-diagnostics key of the first supported-PIDs probe.
String get selfTestSupportedPidsKey =>
    Elm327Protocol.supportedPidsCommands.first.trim();

/// #3555 — parse one sample-read reply into a locale-neutral value token
/// for the step detail (`RPM 850` / `13 km/h` / `88°C`). Null when the
/// reply didn't parse — the status classification already covers that.
// i18n-ignore: locale-neutral units on raw protocol data, not UI copy.
String? describeSelfTestSample(String command, String raw) {
  switch (command) {
    case Elm327Protocol.engineRpmCommand:
      final rpm = Elm327Protocol.parseEngineRpm(raw);
      return rpm == null ? null : 'RPM ${rpm.round()}';
    case Elm327Protocol.vehicleSpeedCommand:
      final kmh = Elm327Protocol.parseVehicleSpeed(raw);
      return kmh == null ? null : '$kmh km/h';
    case Elm327Protocol.coolantTempCommand:
      final c = Elm327Protocol.parseCoolantTempCelsius(raw);
      return c == null ? null : '${c.round()}°C';
  }
  return null;
}
