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
@Riverpod(keepAlive: true)
VoiceAnnouncementService voiceAnnouncementService(Ref ref) {
  final service = FlutterTtsAnnouncementService();

  // Initial selected locale.
  unawaited(service.setAppLocale(ref.read(activeLanguageProvider).code));

  // Re-apply on every language change without recreating the singleton.
  ref.listen<AppLanguage>(
    activeLanguageProvider,
    (_, next) => unawaited(service.setAppLocale(next.code)),
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
