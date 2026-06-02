// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

  /// Speak an already-formatted line of text (#2663).
  ///
  /// The plain-text counterpart to [announce]: where [announce] takes a
  /// station [AnnouncementCandidate] and formats the spoken string
  /// internally, [speakLine] speaks [text] verbatim. The driving-coach
  /// voice listener builds a localised cue sentence and hands it here, so
  /// the station-only [AnnouncementCandidate] contract is not overloaded
  /// with non-station cues. Both paths drive the same underlying engine.
  Future<void> speakLine(String text);

  /// Stop any currently playing announcement.
  Future<void> stop();

  /// Release TTS resources.
  Future<void> dispose();

  /// Set the language for announcements (BCP-47 code, e.g. "de-DE").
  Future<void> setLanguage(String languageCode);
}
