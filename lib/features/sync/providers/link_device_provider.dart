// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/supabase_client.dart';
import '../../alerts/api.dart';
import '../../../core/sync/favorites_sync.dart';
import '../../fill_ups/api.dart';
import '../../../core/sync/vehicles_sync.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../../../core/logging/error_logger.dart';

part 'link_device_provider.g.dart';

/// UI state for the "Link device" screen. The text controller itself
/// is owned by the screen; this provider only tracks loading + result.
/// How a device-link attempt ended (#3988).
///
/// Was a hard-coded English sentence in [LinkDeviceState.result], which the
/// UI then classified by `startsWith('Link failed')` — a user-visible string
/// doing double duty as state. The provider has no BuildContext, so it names
/// the outcome and the card localizes it.
enum LinkDeviceOutcome {
  /// The pasted code is too short to be a device id.
  invalidCode,

  /// TankSync is not connected, so there is nothing to link against.
  notConnected,

  /// Imported — [LinkDeviceState.counts] carries what arrived.
  linked,

  /// The attempt threw; [LinkDeviceState.errorDetail] carries the localized
  /// reason.
  failed,
}

/// What a successful link imported.
typedef LinkDeviceCounts = ({
  int favorites,
  int alerts,
  int vehicles,
  int fillUps,
});

class LinkDeviceState {
  final bool isLinking;
  final LinkDeviceOutcome? outcome;
  final LinkDeviceCounts? counts;
  final String? errorDetail;

  const LinkDeviceState({
    this.isLinking = false,
    this.outcome,
    this.counts,
    this.errorDetail,
  });

  LinkDeviceState copyWith({
    bool? isLinking,
    LinkDeviceOutcome? outcome,
    LinkDeviceCounts? counts,
    String? errorDetail,
    bool clearResult = false,
  }) {
    return LinkDeviceState(
      isLinking: isLinking ?? this.isLinking,
      outcome: clearResult ? null : (outcome ?? this.outcome),
      counts: clearResult ? null : (counts ?? this.counts),
      errorDetail: clearResult ? null : (errorDetail ?? this.errorDetail),
    );
  }

  bool get hasResult => outcome != null;
  bool get isError => outcome != null && outcome != LinkDeviceOutcome.linked;
}

@riverpod
class LinkDeviceController extends _$LinkDeviceController {
  @override
  LinkDeviceState build() => const LinkDeviceState();

  Future<void> linkDevice(String otherUserId) async {
    final trimmed = otherUserId.trim();
    if (trimmed.isEmpty || trimmed.length < 10) {
      state = state.copyWith(outcome: LinkDeviceOutcome.invalidCode);
      return;
    }

    state = const LinkDeviceState(isLinking: true);

    try {
      final client = TankSyncClient.client;
      if (client == null) {
        state = const LinkDeviceState(
            outcome: LinkDeviceOutcome.notConnected);
        return;
      }

      // 1. Fetch the other device's favorites
      final otherFavorites = await client
          .from('favorites')
          .select('station_id')
          .eq('user_id', trimmed);

      final importedFavIds = (otherFavorites as List)
          .map((r) => r['station_id'] as String)
          .toList();

      // 2. Fetch the other device's alerts
      final otherAlerts =
          await client.from('alerts').select().eq('user_id', trimmed);

      // 3. Merge favorites locally
      int addedFavorites = 0;
      final currentFavs = ref.read(favoritesProvider);
      for (final stationId in importedFavIds) {
        if (!currentFavs.contains(stationId)) {
          await ref.read(favoritesProvider.notifier).add(stationId);
          addedFavorites++;
        }
      }

      // 4. Merge alerts locally
      int addedAlerts = 0;
      final currentAlerts = ref.read(alertProvider);
      final currentAlertIds = currentAlerts.map((a) => a.id).toSet();
      for (final row in otherAlerts as List) {
        if (!currentAlertIds.contains(row['id'])) {
          try {
            final alert = PriceAlert.fromJson({
              'id': row['id'],
              'stationId': row['station_id'],
              'stationName': row['station_name'] ?? '',
              'fuelType': row['fuel_type'] ?? 'e10',
              'targetPrice': (row['target_price'] as num).toDouble(),
              'isActive': row['is_active'] ?? true,
              'createdAt':
                  row['created_at'] ?? DateTime.now().toIso8601String(),
            });
            await ref.read(alertProvider.notifier).addAlert(alert);
            addedAlerts++;
          } catch (e, st) {
            unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'Alert import failed'}));
          }
        }
      }

      // 5. Fetch + merge the other device's vehicles (#713)
      int addedVehicles = 0;
      try {
        final otherVehicles = await client
            .from('vehicles')
            .select('id, data')
            .eq('user_id', trimmed);
        final parsed = (otherVehicles as List)
            .map((r) {
              final data = (r as Map)['data'];
              if (data is Map<String, dynamic>) {
                try {
                  return VehicleProfile.fromJson(data);
                } catch (e, st) {
                  unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'Vehicle import decode failed'}));
                  return null;
                }
              }
              return null;
            })
            .whereType<VehicleProfile>()
            .toList();
        addedVehicles = await ref
            .read(vehicleProfileListProvider.notifier)
            .mergeFrom(parsed);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'Vehicle import failed'}));
      }

      // 6. Fetch + merge the other device's fill-ups (#713)
      int addedFillUps = 0;
      try {
        final otherFillUps = await client
            .from('fill_ups')
            .select('id, data')
            .eq('user_id', trimmed);
        final parsed = (otherFillUps as List)
            .map((r) {
              final data = (r as Map)['data'];
              if (data is Map<String, dynamic>) {
                try {
                  return FillUp.fromJson(data);
                } catch (e, st) {
                  unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUp import decode failed'}));
                  return null;
                }
              }
              return null;
            })
            .whereType<FillUp>()
            .toList();
        addedFillUps =
            await ref.read(fillUpListProvider.notifier).mergeFrom(parsed);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'FillUp import failed'}));
      }

      // 7. Sync merged data back to our server account. Profile is NOT
      // synced — each device keeps its own local profile + defaulting.
      // #3452 — favorites upload as full records (fuel + EV, payloads).
      await FavoritesSync.merge(
          FavoritesSync.localRecords(ref.read(storageRepositoryProvider)));
      await AlertsSync.merge(ref.read(alertProvider));
      await VehiclesSync.merge(ref.read(vehicleProfileListProvider));
      await FillUpsSync.merge(ref.read(fillUpListProvider));

      state = LinkDeviceState(
        outcome: LinkDeviceOutcome.linked,
        counts: (
          favorites: addedFavorites,
          alerts: addedAlerts,
          vehicles: addedVehicles,
          fillUps: addedFillUps,
        ),
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'LinkDeviceController: device link failed'
      }));
      // #3988 — the exception never reaches the user verbatim; the card
      // renders the localized reason.
      state = LinkDeviceState(
        outcome: LinkDeviceOutcome.failed,
        errorDetail: e.toString(),
      );
    }
  }
}
