import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../domain/entities/velocity_alert_config.dart';
import '../domain/velocity_alert_detector.dart';
import 'models/price_snapshot.dart';
import 'price_snapshot_store.dart';
import 'velocity_alert_cooldown.dart';

/// Glue between the background price refresh cycle and the
/// velocity detector (#579).
///
/// The background isolate calls [run] once per cycle after it has
/// fetched fresh prices. The runner:
///   1. records a snapshot for every observation (auto-pruned by
///      the store),
///   2. loads the user's [VelocityAlertConfig] from the settings
///      box (falling back to defaults),
///   3. asks the detector whether an alert-worthy cluster of drops
///      has happened,
///   4. checks the cooldown and, if allowed, fires a single local
///      notification with a localized title/body built by the
///      injected [copyBuilder].
///
/// All collaborators are injected so the background-hook integration
/// test can seed snapshots + assert that exactly one notification
/// was sent when the threshold is crossed.
class VelocityAlertRunner {
  final PriceSnapshotStore snapshotStore;
  final VelocityAlertCooldown cooldown;
  final NotificationService notifier;

  /// How far back the detector diffs current prices against.
  /// Matches the issue's default of 1 h.
  final Duration lookback;

  /// Builder for the user-facing notification copy. The caller
  /// passes in a function that reaches into the ARB bundle. When
  /// the background isolate has no BuildContext (no MaterialApp),
  /// a plain-German/English fallback is used.
  final VelocityAlertCopy Function(VelocityAlertEvent event) copyBuilder;

  VelocityAlertRunner({
    required this.snapshotStore,
    required this.cooldown,
    required this.notifier,
    required this.copyBuilder,
    this.lookback = const Duration(hours: 1),
  });

  /// Executes the whole pipeline once. Safe to call even when
  /// [observations] is empty — the snapshot step is skipped and no
  /// detection runs.
  ///
  /// [userLat]/[userLng] come from the last-known position stored
  /// under the `user_position_*` settings keys. Pass `null` to
  /// disable the radius filter (detector will then accept every
  /// observation, which matches the "better to fire" stance).
  Future<VelocityAlertEvent?> run({
    required List<VelocityStationObservation> observations,
    required DateTime now,
    double? userLat,
    double? userLng,
  }) async {
    final config = await loadConfig();

    // 1. Record current snapshots (auto-pruning inside the store).
    for (final obs in observations) {
      await snapshotStore.recordSnapshot(
        PriceSnapshot(
          stationId: obs.stationId,
          fuelType: config.fuelType.apiValue,
          price: obs.price,
          timestamp: now,
          lat: obs.lat,
          lng: obs.lng,
        ),
      );
    }

    // 2. Fetch baseline snapshots older than `lookback` so the
    //    detector has a "before" per station.
    final previous = await snapshotStore.snapshotsOlderThan(lookback);

    // 3. Run the detector.
    final event = VelocityAlertDetector.detect(
      config: config,
      observations: observations,
      previousSnapshots: previous,
      now: now,
      userLat: userLat,
      userLng: userLng,
      lookback: lookback,
    );
    if (event == null) return null;

    // 4. Cooldown gate + fire.
    final allowed = await cooldown.canFire(
      fuelType: event.fuelType,
      now: now,
      cooldown: Duration(hours: config.cooldownHours),
    );
    if (!allowed) {
      debugPrint(
          'VelocityAlertRunner: cooldown active for ${event.fuelType.apiValue}, skipping notification');
      return event;
    }

    final copy = copyBuilder(event);
    // Deterministic id so re-fires update the existing
    // notification in-place rather than stacking.
    final id = _notificationId(event.fuelType);
    await notifier.showPriceAlert(
      id: id,
      title: copy.title,
      body: copy.body,
    );
    await cooldown.recordFired(fuelType: event.fuelType, now: now);
    return event;
  }

  /// Load the persisted [VelocityAlertConfig] from the `settings`
  /// Hive box or return defaults when missing/corrupt.
  Future<VelocityAlertConfig> loadConfig() async {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.settings)) {
        return VelocityAlertConfig.defaults();
      }
      final raw = Hive.box(HiveBoxes.settings).get(configKey);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final map = HiveBoxes.toStringDynamicMap(decoded);
          if (map != null) {
            return VelocityAlertConfig.fromJson(map);
          }
        }
      }
    } catch (e) {
      debugPrint('VelocityAlertRunner.loadConfig: falling back to defaults: $e');
    }
    return VelocityAlertConfig.defaults();
  }

  /// Persist a fresh [VelocityAlertConfig]. Callers are the future
  /// settings UI and tests.
  Future<void> saveConfig(VelocityAlertConfig config) async {
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      debugPrint('VelocityAlertRunner.saveConfig: settings box closed');
      return;
    }
    await Hive.box(HiveBoxes.settings)
        .put(configKey, jsonEncode(config.toJson()));
  }

  /// Settings-box key for the persisted config blob.
  static const String configKey = 'velocity_alert_config';

  /// Stable notification id per fuel so re-fires overwrite the
  /// existing notification instead of stacking a new one per fire.
  static int _notificationId(FuelType fuelType) =>
      ('velocity:${fuelType.apiValue}').hashCode;
}

/// User-facing copy for a velocity alert notification. Kept as a
/// plain value object so the background isolate and the eventual
/// foreground preview both produce identical strings.
class VelocityAlertCopy {
  final String title;
  final String body;
  const VelocityAlertCopy({required this.title, required this.body});
}
