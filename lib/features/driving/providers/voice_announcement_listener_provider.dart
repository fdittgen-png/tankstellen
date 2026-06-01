// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/services/announcement_engine.dart';
import '../../../core/services/approach_detector.dart';
import '../../../core/services/voice_announcement_providers.dart';
import '../../../core/services/voice_announcement_service.dart';
import '../../../core/utils/station_extensions.dart';
import '../../approach/providers/approach_state_provider.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/voice_announcements_enabled_provider.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';
import 'voice_announcement_settings_provider.dart';

part 'voice_announcement_listener_provider.g.dart';

/// Live call site that wires the dormant [AnnouncementEngine] into the
/// real driving flow (#2569).
///
/// This is the ONE integration listener the feature needs. It piggybacks
/// on the existing live geofence (`approachStateProvider`) the approach
/// overlay already drives — no second GPS subscription, no second poll
/// loop. On every [ApproachInRadius] transition it hands the imminent
/// station to [AnnouncementEngine.evaluateAndAnnounce] with the user's
/// persisted [AnnouncementConfig]; the engine then enforces the price
/// threshold, the (voice-specific) proximity radius, and the per-station
/// repeat cooldown that already prevent over-announcing. The engine
/// short-circuits when its `enabled` flag is false, and this provider
/// never subscribes at all while the feature gate is off — so the flag
/// is honoured at two layers.
///
/// `keepAlive: true` because a trip + its approach stream outlive widget
/// rebuilds as the driver navigates the app mid-trip.
@Riverpod(keepAlive: true)
class VoiceAnnouncementListener extends _$VoiceAnnouncementListener {
  @override
  void build() {
    final enabled = ref.watch(voiceAnnouncementsEnabledProvider);

    // Flag OFF → never subscribe, never announce. (The engine would also
    // short-circuit on its `enabled:false` config, but not subscribing at
    // all is the stronger guarantee the issue asks for.) Riverpod re-runs
    // `build` when the gate flips and auto-disposes the listener set up on
    // the previous run, so there is no subscription to tear down by hand.
    if (!enabled) return;

    // The TTS engine is lazily created the first time we announce; warm it
    // up now so the first spoken line isn't dropped while it initialises.
    final ttsService = ref.read(voiceAnnouncementServiceProvider);
    unawaited(_initTts(ttsService));

    // Listen to the SAME live geofence the overlay drives. Reacts to
    // forward transitions only — no replay of the current state on
    // subscribe — so a station already in-radius when the trip screen
    // re-mounts is not re-announced (the engine cooldown would catch a
    // duplicate anyway).
    ref.listen<AsyncValue<ApproachState>>(
      approachStateProvider,
      (prev, next) {
        final state = next.value;
        if (state is ApproachInRadius) {
          unawaited(_announce(state));
        }
      },
    );
  }

  Future<void> _initTts(VoiceAnnouncementService ttsService) async {
    try {
      await ttsService.initialize();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'VoiceAnnouncementListener._initTts',
      }));
    }
  }

  Future<void> _announce(ApproachInRadius state) async {
    final config = ref.read(voiceAnnouncementSettingsProvider);
    // Re-check the user toggle: the feature flag is on but the user may
    // have the in-feature enable switch off.
    if (!config.enabled) return;

    final fuel = ref.read(effectiveFuelTypeProvider);
    final engine = ref.read(announcementEngineProvider);
    engine.updateConfig(config);

    final station = state.station;
    final distanceKm = state.distanceMeters / 1000.0;

    try {
      await engine.evaluateAndAnnounce(
        nearbyStations: [station],
        fuelType: fuel.displayName,
        priceExtractor: (s) => _priceFor(s, fuel),
        // The detector already computed the live distance to this station;
        // reuse it so we don't recompute a haversine from a position the
        // engine doesn't have.
        distanceExtractor: (_) => distanceKm,
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'VoiceAnnouncementListener._announce',
      }));
    }
  }

  double _priceFor(Station s, FuelType fuel) => s.priceFor(fuel) ?? 0;
}
