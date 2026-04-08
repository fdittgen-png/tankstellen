import '../../features/search/domain/entities/station.dart';

/// A station that is near enough and cheap enough to announce.
class AnnouncementCandidate {
  final Station station;
  final String fuelType;
  final double price;
  final double distanceKm;

  const AnnouncementCandidate({
    required this.station,
    required this.fuelType,
    required this.price,
    required this.distanceKm,
  });
}

/// Abstract interface for text-to-speech voice announcements.
///
/// Announces nearby cheap fuel stations while in driving mode so that
/// drivers can receive price information without looking at the screen.
abstract class VoiceAnnouncementService {
  /// Initialize the TTS engine. Must be called before [announce].
  Future<void> initialize();

  /// Speak an announcement for the given candidate.
  Future<void> announce(AnnouncementCandidate candidate);

  /// Stop any currently playing announcement.
  Future<void> stop();

  /// Release TTS resources.
  Future<void> dispose();

  /// Set the language for announcements (BCP-47 code, e.g. "de-DE").
  Future<void> setLanguage(String languageCode);
}
