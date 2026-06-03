// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../language/language_provider.dart';
import 'announcement_engine.dart';
import 'impl/flutter_tts_announcement_service.dart';
import 'voice_announcement_service.dart';

part 'voice_announcement_providers.g.dart';

/// Provides the platform TTS service singleton.
///
/// Kept alive for the app lifetime so the TTS engine is initialized once.
///
/// Binds the service to the app's SELECTED locale (#2762): the initial
/// language is read from [activeLanguageProvider] (the persisted/profile
/// language the rest of the app uses), and a [Ref.listen] re-applies it
/// whenever the user changes language — so both the native TTS voice and
/// the spoken sentence follow the app language rather than the device
/// default voice + hardcoded English words.
///
/// The locale binding is best-effort by design: this is an app-lifetime
/// singleton, so it MUST NOT make every transitive consumer (e.g. the active
/// driving screen) depend on the Hive-backed profile store being open. During
/// early startup — and in widget tests that don't open the profile box —
/// [activeLanguageProvider] (which watches the profile) may still be in error
/// state; reading it would otherwise poison this provider and every consumer.
/// We therefore read defensively and start on the device-default voice, then
/// let the [Ref.listen] below snap the locale to the app language the instant
/// the profile resolves (and on every later language change).
@Riverpod(keepAlive: true)
VoiceAnnouncementService voiceAnnouncementService(Ref ref) {
  final service = FlutterTtsAnnouncementService();

  // Initial selected locale — defensively, see doc comment above.
  try {
    unawaited(service.setAppLocale(ref.read(activeLanguageProvider).code));
  } catch (_) {
    // Profile store not ready yet; keep the device-default voice until the
    // listener below fires once the language resolves.
  }

  // Re-apply on every language change without recreating the singleton. The
  // onError handler keeps a not-yet-ready profile from surfacing as an
  // unhandled provider error while the box is still opening.
  ref.listen<AppLanguage>(
    activeLanguageProvider,
    (_, next) => unawaited(service.setAppLocale(next.code)),
    onError: (_, _) {},
  );

  ref.onDispose(() => service.dispose());
  return service;
}

/// Provides the announcement engine that evaluates nearby stations.
///
/// Kept alive so cooldown state persists across screen navigations.
@Riverpod(keepAlive: true)
AnnouncementEngine announcementEngine(Ref ref) {
  final ttsService = ref.watch(voiceAnnouncementServiceProvider);
  return AnnouncementEngine(ttsService: ttsService);
}
