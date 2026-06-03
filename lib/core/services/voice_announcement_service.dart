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

  /// Bind the service to the app's currently SELECTED locale (#2762).
  ///
  /// [languageCode] is the app two-letter language code (e.g. `fr`, `de`,
  /// `en`). This both (a) drives the native TTS voice — the code is mapped
  /// to a BCP-47 tag and pushed via [setLanguage] so a French user hears a
  /// French voice instead of the device default — and (b) selects which
  /// [AppLocalizations] the spoken sentence in [announce] is resolved
  /// against. Safe to call repeatedly when the user changes language; an
  /// unavailable native locale is swallowed so the engine keeps working.
  Future<void> setAppLocale(String languageCode);
}
