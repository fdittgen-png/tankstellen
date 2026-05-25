// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../data/osm_traffic_signal_client.dart';
import '../data/traffic_signal_repository.dart';
import '../domain/entities/glide_coach_settings.dart';
import '../domain/services/glide_coach_evaluator.dart';
import '../domain/services/imminent_signal_detector.dart';
import 'glide_coach_enabled_provider.dart';
import 'glide_coach_settings_provider.dart';

part 'glide_coach_evaluator_provider.g.dart';

/// Provider for the glide-coach evaluator (#1125 phase 3b).
///
/// Returns `null` when [glideCoachEnabledProvider] is `false`
/// (`Feature.glideCoach`, default-off) — that's production today, and
/// every consumer (currently only `tripRecordingProvider`) early-outs
/// on the null. Callers MUST treat null as "feature disabled, do
/// nothing" rather than constructing their own evaluator; the layered
/// gate is the whole point.
///
/// When the feature is enabled, the provider wires:
///   1. An [OsmTrafficSignalClient] (default Dio).
///   2. A [TrafficSignalRepository] backed by the
///      `traffic_signals_cache` Hive box (opened at startup by
///      [HiveBoxes.init]).
///   3. An [ImminentSignalDetector] over the repo.
///   4. A [GlideCoachEvaluator] over the detector, with the cool-down
///      and throttle threshold sourced from the user's
///      [GlideCoachSettings] (read once at construction; the evaluator
///      itself is stateless w.r.t. settings flips, so a settings change
///      that should re-tune thresholds invalidates this provider via
///      `ref.watch`).
///
/// Returns `null` (rather than throwing) when the Hive box isn't open —
/// matching the loyalty repository pattern for widget-test-friendly
/// no-ops on missing infrastructure.
@Riverpod(keepAlive: true)
GlideCoachEvaluator? glideCoachEvaluator(Ref ref) {
  // Feature gate (#1824) — central Feature.glideCoach, default-off.
  if (!ref.watch(glideCoachEnabledProvider)) return null;

  // Defensive: the Overpass cache box is opened at app startup. A
  // widget test that didn't run the Hive bootstrapper hits this path
  // and gets null — same shape as `loyaltyCardRepositoryProvider`.
  if (!Hive.isBoxOpen(TrafficSignalRepository.boxName)) return null;

  final settings = ref.watch(glideCoachSettingsProvider);

  final client = OsmTrafficSignalClient();
  final repo = TrafficSignalRepository(
    client: client,
    cacheBox: Hive.box<String>(TrafficSignalRepository.boxName),
  );
  final detector = ImminentSignalDetector(repo: repo);
  return GlideCoachEvaluator(
    detector: detector,
    cooldown: settings.cooldown,
    throttleThresholdPercent: settings.throttleThresholdPercent,
  );
}
