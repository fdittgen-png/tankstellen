// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/language/language_provider.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/services/voice_announcement_providers.dart';
import '../../../core/services/voice_announcement_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../consumption/domain/driving_coaching.dart'
    show DrivingCoachingHint, coachingHint;
import '../../consumption/domain/harsh_event.dart'
    show HarshEvent, HarshEventType;
import '../../consumption/providers/trip_recording_provider.dart';
import 'live_harsh_event_bus_provider.dart';
import 'voice_coaching_enabled_provider.dart';

part 'driving_coach_voice_listener_provider.g.dart';

/// Per-cue throttle so a stream of qualifying events does not turn into a
/// torrent of spoken lines while driving (#2663). Distinct from the
/// harsh-event detector's own de-noising (#2653): even a single REAL
/// event per second of hard braking should be spoken at most once per
/// window.
const Duration _cueCooldown = Duration(seconds: 20);

/// The dead-link fix (#2663): wires the driving coach into TTS.
///
/// Before this provider, every driving cue dead-ended — OBD2/GPS coaching
/// hints rendered as silent tiles, GlideCoach lift fired only haptics, and
/// harsh events surfaced only at trip-stop. The ONE TTS listener
/// ([VoiceAnnouncementListener]) watched only the station approach stream.
/// This listener is the missing event→coach→speak wire, mirroring that
/// sibling but driven by driving events instead of station proximity.
///
/// In [build] it:
///   * returns early (no subscription, guaranteed silence) when the
///     [voiceCoachingEnabledProvider] toggle is off;
///   * warms the shared TTS engine;
///   * subscribes to the live harsh-event bus ([liveHarshEventBusProvider])
///     — fed by both the OBD2 and GPS-only recorders the instant the
///     de-noised [HarshEventDetector] fires — and speaks a localised cue;
///   * listens to [tripRecordingProvider] for OBD2/GPS coaching-hint
///     *transitions* (shift up/down, ease pedal, GlideCoach lift, …) and
///     speaks those too.
///
/// A per-cue cooldown (keyed on the event's own wall clock, so it elapses
/// with the trip rather than a never-advancing test clock) prevents spam.
///
/// `keepAlive: true` because a trip + its event flow outlive widget
/// rebuilds as the driver navigates the app mid-trip.
@Riverpod(keepAlive: true)
class DrivingCoachVoiceListener extends _$DrivingCoachVoiceListener {
  /// Last time each cue *category* was spoken. Harsh events key on the
  /// event's wall clock; hint transitions key on [_clock].
  final Map<String, DateTime> _lastSpokenAt = {};

  /// Wall clock for hint-transition cooldowns. Injectable for tests so a
  /// rapid-repeat assertion is deterministic.
  @visibleForTesting
  static DateTime Function()? clockOverride;

  DateTime get _clock => (clockOverride ?? DateTime.now)();

  @override
  void build() {
    final enabled = ref.watch(voiceCoachingEnabledProvider);

    // Toggle OFF → never subscribe, never speak. Riverpod re-runs build
    // when the toggle flips and disposes the previous run's listeners, so
    // there is nothing to tear down by hand.
    if (!enabled) return;

    final ttsService = ref.read(voiceAnnouncementServiceProvider);
    unawaited(_initTts(ttsService));

    // Live harsh-event bus — the de-noised (#2653) events both recorders
    // push. Each qualifying event is a spoken cue (cooldown-gated).
    final sub = ref.read(liveHarshEventBusProvider.notifier).stream.listen(
      (event) => unawaited(_speakHarsh(event, ttsService)),
      onError: (Object e, StackTrace st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
          'where': 'DrivingCoachVoiceListener.harshStream',
        }));
      },
    );
    ref.onDispose(sub.cancel);

    // OBD2 / GPS coaching-hint TRANSITIONS. The OBD2 hint is derived from
    // the live reading; the GPS hint is already on the state. Speak only
    // when the resolved hint *changes* to a non-null value, so a hint that
    // stays latched across emits is spoken once (the cooldown is a second
    // backstop). We listen to the whole state and resolve the hint here
    // rather than via `.select`, comparing the resolved hint across emits.
    DrivingCoachingHint? lastHint;
    ref.listen<TripRecordingState>(
      tripRecordingProvider,
      (prev, next) {
        final hint = _resolveHint(next);
        if (hint != null && hint != lastHint) {
          unawaited(_speakHint(hint, ttsService));
        }
        lastHint = hint;
      },
    );
  }

  /// Resolve the single active coaching hint from a recording state: the
  /// GPS-only hint when present (dongle-less trips), else the OBD2 hint
  /// classified from the live reading.
  DrivingCoachingHint? _resolveHint(TripRecordingState state) {
    final gps = state.gpsCoachingHint;
    if (gps != null) return gps;
    final live = state.live;
    if (live == null) return null;
    return coachingHint(
      live,
      situation: state.situation,
      band: state.band,
    );
  }

  Future<void> _initTts(VoiceAnnouncementService ttsService) async {
    try {
      await ttsService.initialize();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'DrivingCoachVoiceListener._initTts',
      }));
    }
  }

  Future<void> _speakHarsh(
    HarshEvent event,
    VoiceAnnouncementService ttsService,
  ) async {
    final key = 'harsh.${event.type.name}';
    // Key the cooldown on the EVENT's wall clock so it elapses with the
    // trip — a test feeding timestamps 30 s apart sees the throttle clear.
    if (_onCooldown(key, event.timestamp)) return;
    final l = _l10n();
    final cue = switch (event.type) {
      HarshEventType.brake => l.coachingVoiceHarshBraking,
      HarshEventType.acceleration => l.coachingVoiceHardAcceleration,
    };
    _lastSpokenAt[key] = event.timestamp;
    await _speak(cue, ttsService);
  }

  Future<void> _speakHint(
    DrivingCoachingHint hint,
    VoiceAnnouncementService ttsService,
  ) async {
    final key = 'hint.${hint.name}';
    final now = _clock;
    if (_onCooldown(key, now)) return;
    final l = _l10n();
    final cue = switch (hint) {
      DrivingCoachingHint.shiftUp => l.coachingVoiceShiftUp,
      DrivingCoachingHint.shiftDown => l.coachingVoiceShiftDown,
      DrivingCoachingHint.easePedal => l.coachingVoiceEasePedal,
      DrivingCoachingHint.gpsLiftOffCoast => l.coachingVoiceLiftOff,
      DrivingCoachingHint.gpsAnticipateBrake => l.coachingVoiceAnticipateBrake,
      DrivingCoachingHint.gpsSmoothAccel => l.coachingVoiceSmoothAccel,
    };
    _lastSpokenAt[key] = now;
    await _speak(cue, ttsService);
  }

  bool _onCooldown(String key, DateTime at) {
    final last = _lastSpokenAt[key];
    if (last == null) return false;
    return at.difference(last) < _cueCooldown;
  }

  Future<void> _speak(
    String cue,
    VoiceAnnouncementService ttsService,
  ) async {
    try {
      await ttsService.speakLine(cue);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'DrivingCoachVoiceListener._speak',
      }));
    }
  }

  /// Resolve [AppLocalizations] for the active in-app language without a
  /// BuildContext (this is a provider). `lookupAppLocalizations` is a pure
  /// synchronous constructor; falls back to English on an unknown code.
  AppLocalizations _l10n() {
    final code = ref.read(activeLanguageProvider).code;
    try {
      return lookupAppLocalizations(ui.Locale(code));
    } catch (_) {
      return lookupAppLocalizations(const ui.Locale('en'));
    }
  }
}
