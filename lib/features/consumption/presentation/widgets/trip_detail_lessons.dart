// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/lessons/driving_lesson_registry.dart';
import '../../data/trip_history_entry.dart';
import '../../domain/driving_insight.dart';
import '../../domain/driving_score.dart';
import '../../domain/lessons/driving_lesson.dart';
import '../../domain/lessons/driving_lesson_rule.dart';
import '../../domain/trip_sample.dart';
import '../../../fill_ups/api.dart';

/// Post-trip lesson resolution for the trip-detail body (#2251), split
/// out of `trip_detail_body.dart` for the file-length norm.
///
/// Resolved per build because the localized titles depend on the active
/// locale, but built off the caller's CACHED insights / score (and the
/// stored summary) so the O(n) analyzer / score passes don't re-run on a
/// theme / locale rebuild.
///
/// #3701 — the tank-mix ethanol share (from the #3652 mix model) rides
/// into [LessonContext] so the combustion-health rule can tell "the ECU
/// is trimming for E85" from "the ECU is fighting a fault". Null
/// (unknown vehicle / single-fuel) keeps every rule stock.
List<DrivingLesson> buildTripDetailLessons({
  required WidgetRef ref,
  required DrivingLessonRegistry registry,
  required TripHistoryEntry entry,
  required List<TripSample> samples,
  required DrivingScore score,
  required List<DrivingInsight> insights,
  required AppLocalizations l,
}) {
  final vehicleId = entry.vehicleId;
  return registry.evaluateContext(
    LessonContext(
      summary: entry.summary,
      samples: samples,
      score: score,
      insights: insights,
      expectedEthanolShare: vehicleId == null
          ? null
          : ref.watch(tankMixProvider(vehicleId))?.ethanolVolumeFraction,
    ),
    l,
  );
}
