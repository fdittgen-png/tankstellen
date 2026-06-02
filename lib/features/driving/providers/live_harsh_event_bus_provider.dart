// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../consumption/domain/harsh_event.dart' show HarshEvent;

part 'live_harsh_event_bus_provider.g.dart';

/// App-wide broadcast bus for live harsh-driving events (#2663).
///
/// The recording recorders (OBD2 via [TripRecordingController] and the
/// GPS-only pipeline) both feed their `onHarshEvent` callback into this
/// single sink the instant the [HarshEventDetector] fires a (de-noised,
/// post-#2653) event. The [DrivingCoachVoiceListener] subscribes to
/// [stream] and speaks a localised cue per qualifying event.
///
/// Decoupling the recorders from the listener through a bus avoids
/// threading a new stream out through the deeply layered
/// [TripRecording] notifier + its pipeline collaborators — each recorder
/// just `add`s, and any number of consumers can listen. `keepAlive`
/// because a trip + its event flow outlive widget rebuilds as the driver
/// navigates the app mid-trip.
@Riverpod(keepAlive: true)
class LiveHarshEventBus extends _$LiveHarshEventBus {
  final StreamController<HarshEvent> _controller =
      StreamController<HarshEvent>.broadcast();

  @override
  Stream<HarshEvent> build() {
    ref.onDispose(() => unawaited(_controller.close()));
    return _controller.stream;
  }

  /// The live harsh-event stream consumers subscribe to. Broadcast, so
  /// the listener and any future consumer can each attach independently.
  Stream<HarshEvent> get stream => _controller.stream;

  /// Push one detected harsh event onto the bus. Safe after dispose (a
  /// closed controller drops the add silently rather than throwing).
  void add(HarshEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }
}
