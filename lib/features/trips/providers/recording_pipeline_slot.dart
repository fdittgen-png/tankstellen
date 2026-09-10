// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../obd2/api.dart';
import 'recording_pipeline.dart';

/// The recording notifier's selected strategy, held in a slot it owns
/// (#4036, epic #4032) instead of a bare field two of its `part` files
/// wrote.
///
/// #2190 / #2227 — both modes run a [RecordingPipeline]: `start(service)`
/// installs an [Obd2RecordingPipeline], the dongle-less #2025 flow a
/// [GpsOnlyRecordingPipeline]. The historical "null means inline OBD2"
/// branch is gone — every lifecycle boundary dispatches through the slot.
/// A future third source (CarPlay / Android Auto telemetry) becomes
/// another implementation rather than another `_xMode` bool, which was
/// the #2190 motivation.
///
/// Empty only between trips and in the cold-start-recovered state
/// (#1347), where the WAL snapshot — not a live pipeline — is the source
/// of truth.
class RecordingPipelineSlot {
  RecordingPipeline? _pipeline;

  /// The selected pipeline, or null when nothing is running.
  RecordingPipeline? get pipeline => _pipeline;

  /// The active OBD2 pipeline, or null when no trip is running, a
  /// GPS-only trip is running, or we are in the recovered-no-controller
  /// state. The WAL snapshot helpers, `pause` / `resume` and
  /// `debugController` reach the live controller through it (#2227).
  Obd2RecordingPipeline? get obd2 {
    final p = _pipeline;
    return p is Obd2RecordingPipeline ? p : null;
  }

  /// True while the running trip is the dongle-less GPS-only kind.
  bool get isGpsOnly => _pipeline?.isGpsOnly ?? false;

  /// Install [pipeline] as the strategy for the trip about to run.
  void select(RecordingPipeline pipeline) => _pipeline = pipeline;

  /// Empty the slot, returning what was there.
  ///
  /// The stop path releases only AFTER `stop()` has returned: the persist
  /// step inside the teardown reaches the live controller through [obd2]
  /// to read the captured sample buffer, so releasing first saves a trip
  /// with no samples at all.
  RecordingPipeline? release() {
    final p = _pipeline;
    _pipeline = null;
    return p;
  }
}
