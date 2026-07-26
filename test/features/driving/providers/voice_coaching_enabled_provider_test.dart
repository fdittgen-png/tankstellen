// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/features/driving/providers/voice_coaching_enabled_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

import '../../../helpers/silence_error_logger.dart';

/// Tests for [VoiceCoachingEnabled] (#2663).
///
/// #3605 — spoken coaching is now gated by the master
/// [Feature.voiceFeedback] switch (default OFF on every channel, because
/// flutter_tts leaks a TTS connection per not-ready speak()); WITH the
/// master on, the #2663 semantics hold: default ON, persisted mute
/// honoured.
void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  /// A container with the master TTS feature ON — the pre-#3605 world.
  ProviderContainer voiceOn() => ProviderContainer(overrides: [
        enabledFeaturesProvider
            .overrideWithValue(const {Feature.voiceFeedback}),
      ]);

  test('SILENT by default — the master voiceFeedback feature is off '
      '(#3605)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(voiceCoachingEnabledProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(voiceCoachingEnabledProvider), isFalse,
        reason: 'no TTS may run unless the user opts into the master '
            'feature — flutter_tts leaks a connection per not-ready '
            'speak()');
  });

  test('master feature ON + no persisted value → coach defaults ON '
      '(#2663 semantics preserved behind the gate)', () async {
    final container = voiceOn();
    addTearDown(container.dispose);

    container.read(voiceCoachingEnabledProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(voiceCoachingEnabledProvider), isTrue);
  });

  test('restores a persisted opt-out (false) on startup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      VoiceCoachingEnabled.prefsKey: false,
    });
    final container = voiceOn();
    addTearDown(container.dispose);

    container.read(voiceCoachingEnabledProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(voiceCoachingEnabledProvider), isFalse,
        reason: 'an explicit opt-out is honoured');
  });

  test('setEnabled(false) mutes and writes through to SharedPreferences',
      () async {
    final container = voiceOn();
    addTearDown(container.dispose);

    await container
        .read(voiceCoachingEnabledProvider.notifier)
        .setEnabled(false);

    expect(container.read(voiceCoachingEnabledProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(VoiceCoachingEnabled.prefsKey), isFalse);
  });

  test('setEnabled(true) re-enables and persists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      VoiceCoachingEnabled.prefsKey: false,
    });
    final container = voiceOn();
    addTearDown(container.dispose);

    await container
        .read(voiceCoachingEnabledProvider.notifier)
        .setEnabled(true);

    expect(container.read(voiceCoachingEnabledProvider), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(VoiceCoachingEnabled.prefsKey), isTrue);
  });
}
