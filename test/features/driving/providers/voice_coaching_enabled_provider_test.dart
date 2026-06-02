// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/features/driving/providers/voice_coaching_enabled_provider.dart';

import '../../../helpers/silence_error_logger.dart';

/// Tests for [VoiceCoachingEnabled] (#2663).
///
/// Unlike the glide-coach / voice-announcement settings, spoken driving
/// coaching is **default ON** and **decoupled from any Feature flag** —
/// the bug was that it was never wired, not that users opted out.
void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('defaults to ON on first launch (no persisted value)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(voiceCoachingEnabledProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(voiceCoachingEnabledProvider), isTrue,
        reason: 'spoken coaching speaks by default — no Feature gate');
  });

  test('restores a persisted opt-out (false) on startup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      VoiceCoachingEnabled.prefsKey: false,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(voiceCoachingEnabledProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(voiceCoachingEnabledProvider), isFalse,
        reason: 'an explicit opt-out is honoured');
  });

  test('setEnabled(false) mutes and writes through to SharedPreferences',
      () async {
    final container = ProviderContainer();
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
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(voiceCoachingEnabledProvider.notifier)
        .setEnabled(true);

    expect(container.read(voiceCoachingEnabledProvider), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(VoiceCoachingEnabled.prefsKey), isTrue);
  });
}
