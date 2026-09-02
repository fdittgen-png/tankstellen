// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The topic sub-screens of the Edit-vehicle editor (#3900, Epic #3897).
///
/// The editor's top level keeps identity & engine inline and lists one
/// tappable tile per topic; each tile opens its own screen under
/// `screens/topics/`. The `name` doubles as the tile's widget-key
/// suffix (`vehicleTopic_<name>`) so tests address a tile without
/// depending on its localised title — the #3884 Settings convention.
enum VehicleEditTopic {
  /// OBD2 adapter pairing + the adapter capability tier.
  adapter,

  /// Baseline coverage, calibration mode, advanced overrides, resets.
  calibration,

  /// Service reminders (odometer / date based).
  reminders,

  /// Hands-free trip auto-record settings.
  autoRecord,
}
