import 'package:flutter/foundation.dart';

import '../../features/search/domain/entities/station.dart';
import 'voice_announcement_service.dart';

/// Configuration for voice announcements.
class AnnouncementConfig {
  /// Whether voice announcements are enabled.
  final bool enabled;

  /// Maximum distance in km for a station to be announced.
  final double proximityRadiusKm;

  /// Cooldown period before the same station can be announced again.
  final Duration cooldown;

  /// Optional price threshold. Only stations with a price at or below
  /// this value are announced. Null means announce all nearby stations.
  final double? priceThreshold;

  const AnnouncementConfig({
    this.enabled = false,
    this.proximityRadiusKm = 2.0,
    this.cooldown = const Duration(minutes: 30),
    this.priceThreshold,
  });

  AnnouncementConfig copyWith({
    bool? enabled,
    double? proximityRadiusKm,
    Duration? cooldown,
    double? priceThreshold,
  }) {
    return AnnouncementConfig(
      enabled: enabled ?? this.enabled,
      proximityRadiusKm: proximityRadiusKm ?? this.proximityRadiusKm,
      cooldown: cooldown ?? this.cooldown,
      priceThreshold: priceThreshold ?? this.priceThreshold,
    );
  }
}

/// Decides which stations to announce and enforces cooldown.
///
/// This is a pure-logic class with no platform dependencies. It receives
/// nearby stations and determines which (if any) should be spoken.
/// The actual TTS call is delegated to [VoiceAnnouncementService].
class AnnouncementEngine {
  AnnouncementEngine({
    required VoiceAnnouncementService ttsService,
    AnnouncementConfig config = const AnnouncementConfig(),
    @visibleForTesting DateTime Function()? clock,
  })  : _ttsService = ttsService,
        _config = config,
        _clock = clock ?? DateTime.now;

  final VoiceAnnouncementService _ttsService;
  AnnouncementConfig _config;
  final DateTime Function() _clock;

  /// Station ID -> last announcement time.
  final Map<String, DateTime> _announcedStations = {};

  /// Read the current config.
  AnnouncementConfig get config => _config;

  /// Update the configuration at runtime (e.g. from settings screen).
  void updateConfig(AnnouncementConfig config) {
    _config = config;
  }

  /// Evaluate a list of nearby stations and announce eligible ones.
  ///
  /// A station is eligible when:
  /// 1. Announcements are enabled
  /// 2. It is within [AnnouncementConfig.proximityRadiusKm]
  /// 3. Its price is at or below [AnnouncementConfig.priceThreshold] (if set)
  /// 4. It has not been announced within the cooldown period
  ///
  /// Returns the list of stations that were actually announced.
  Future<List<AnnouncementCandidate>> evaluateAndAnnounce({
    required List<Station> nearbyStations,
    required String fuelType,
    required double Function(Station) priceExtractor,
    required double Function(Station) distanceExtractor,
  }) async {
    if (!_config.enabled) return [];

    _purgeExpiredCooldowns();

    final candidates = <AnnouncementCandidate>[];

    for (final station in nearbyStations) {
      final distance = distanceExtractor(station);
      final price = priceExtractor(station);

      if (distance > _config.proximityRadiusKm) continue;
      if (price <= 0) continue;
      if (_config.priceThreshold != null && price > _config.priceThreshold!) {
        continue;
      }
      if (_isOnCooldown(station.id)) continue;

      candidates.add(AnnouncementCandidate(
        station: station,
        fuelType: fuelType,
        price: price,
        distanceKm: distance,
      ));
    }

    // Sort by distance so closest station is announced first.
    candidates.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // Announce only the single closest eligible station to avoid spam.
    if (candidates.isNotEmpty) {
      final best = candidates.first;
      try {
        await _ttsService.announce(best);
        _announcedStations[best.station.id] = _clock();
        return [best];
      } catch (e, st) {
        debugPrint('VoiceAnnouncement: TTS error: $e\n$st');
      }
    }

    return [];
  }

  /// Check if a station is still in its cooldown window.
  bool _isOnCooldown(String stationId) {
    final lastAnnounced = _announcedStations[stationId];
    if (lastAnnounced == null) return false;
    return _clock().difference(lastAnnounced) < _config.cooldown;
  }

  /// Remove expired cooldown entries to prevent memory leaks.
  void _purgeExpiredCooldowns() {
    final now = _clock();
    _announcedStations.removeWhere(
      (_, time) => now.difference(time) >= _config.cooldown,
    );
  }

  /// Clear all cooldowns (e.g. when user resets settings).
  void clearCooldowns() => _announcedStations.clear();

  /// Number of stations currently on cooldown (for testing).
  @visibleForTesting
  int get cooldownCount => _announcedStations.length;
}
