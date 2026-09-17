// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../obd2/api.dart' show PausedTripRepository;

/// Delete the paused-trip row of the trip [id] names (#4314).
///
/// A link drop writes a paused row next to the active-trip WAL row, under
/// the same id. Whatever ends that trip — a finalise into history, a
/// discard — must take both rows with it: a paused row left behind is
/// swept into history on a later launch as a sample-less copy, and
/// `TripHistoryRepository.save` is keyed by id, so the copy can overwrite
/// the good row.
///
/// No-op without an id or an open box; the repository logs and swallows a
/// failed delete, because the caller is already finishing the trip.
Future<void> deletePausedTripRow(String? id) async {
  if (id == null || !Hive.isBoxOpen(HiveBoxes.obd2PausedTrips)) return;
  await PausedTripRepository(box: Hive.box<String>(HiveBoxes.obd2PausedTrips))
      .delete(id);
}
