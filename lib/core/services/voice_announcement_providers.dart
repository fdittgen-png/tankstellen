import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'announcement_engine.dart';
import 'impl/flutter_tts_announcement_service.dart';
import 'voice_announcement_service.dart';

part 'voice_announcement_providers.g.dart';

/// Provides the platform TTS service singleton.
///
/// Kept alive for the app lifetime so the TTS engine is initialized once.
@Riverpod(keepAlive: true)
VoiceAnnouncementService voiceAnnouncementService(Ref ref) {
  final service = FlutterTtsAnnouncementService();
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
