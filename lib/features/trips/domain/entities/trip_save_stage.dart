// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Stage surfaced while a stopped trip is being wrapped up and saved.
/// Drives the inline [TripSaveProgress] card (#2548).
///
/// The mirror of [TripStartStage] for the stop→summary gap: the
/// recording screen renders these beats while [TripRecording.stop]
/// finalises the summary, writes it to Hive history, and (when cloud
/// sync is enabled) kicks off the fire-and-forget upload — so the
/// ~300-700 ms save is no longer a frozen, feedback-less swap to the
/// summary view.
///
/// Lives in the domain layer (rather than alongside the presentation
/// widget) so the [TripRecordingState] can carry it without a
/// provider→presentation import — exactly the [TripStartStage] idiom.
enum TripSaveStage {
  /// Finalising the trip summary (odometer refresh / summary build).
  finalizingSummary,

  /// Writing the finished trip into the rolling Hive history log.
  savingToHistory,

  /// Kicking off the fire-and-forget TankSync cloud upload. Only ever
  /// surfaced when cloud sync is enabled; the upload itself is
  /// unawaited, so this stage is worded "Syncing in background…" and
  /// never blocks the resolve to the summary.
  syncingToCloud,
}
