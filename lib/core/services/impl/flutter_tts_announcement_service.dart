import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../voice_announcement_service.dart';

/// Platform TTS implementation using [FlutterTts].
///
/// Delegates to the native speech engine on Android/iOS. Volume is tied
/// to the media channel so the system silent/vibrate mode is respected
/// automatically.
class FlutterTtsAnnouncementService implements VoiceAnnouncementService {
  FlutterTtsAnnouncementService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setSharedInstance(true);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  @override
  Future<void> announce(AnnouncementCandidate candidate) async {
    if (!_initialized) {
      debugPrint('VoiceAnnouncement: TTS not initialized, skipping');
      return;
    }
    final text = _formatAnnouncement(candidate);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
    _initialized = false;
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
  }

  /// Build the spoken text for a candidate.
  ///
  /// Format: "Shell, 1.2 kilometers ahead, Diesel 1 euro 42"
  /// This is a plain English fallback; localised formatting happens in
  /// the [AnnouncementEngine] which calls this service.
  String _formatAnnouncement(AnnouncementCandidate candidate) {
    final name = candidate.station.brand.isNotEmpty
        ? candidate.station.brand
        : candidate.station.name;
    final dist = candidate.distanceKm.toStringAsFixed(1);
    final priceParts = candidate.price.toStringAsFixed(2).split('.');
    return '$name, $dist kilometers ahead, '
        '${candidate.fuelType} ${priceParts[0]} euro ${priceParts[1]}';
  }
}
