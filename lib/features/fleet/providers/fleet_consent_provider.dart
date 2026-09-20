// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Consent for sharing fleet-relevant data with the user's organisation
/// (#4212, Epic #4211).
///
/// Shaped exactly like the trip-sync consent (#1479): its own
/// `StorageKeys` entry, default false, and **gated on**
/// `consentCloudSync` — a stored `true` can never ride past a withdrawn
/// master cloud-sync consent, because the read itself forces false.
/// Fleet data leaves the device over TankSync or not at all.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';

part 'fleet_consent_provider.g.dart';

/// Whether the user has consented to sharing fleet data with their org.
///
/// `false` whenever the master cloud-sync consent is off, whatever is
/// stored — the same force-off rule `GdprConsent.save` applies to
/// `consentSyncTrips`.
@riverpod
class FleetSharingConsent extends _$FleetSharingConsent {
  @override
  bool build() {
    final storage = ref.watch(storageRepositoryProvider);
    final cloudSync =
        storage.getSetting(StorageKeys.consentCloudSync) as bool? ?? false;
    if (!cloudSync) return false;
    return storage.getSetting(StorageKeys.consentFleetSharing) as bool? ??
        false;
  }

  /// Record the user's choice. Writing `true` while cloud sync is off
  /// persists `false`: there is no backend to share with, and a stored
  /// `true` would silently take effect the moment sync came back.
  Future<void> set(bool value) async {
    final storage = ref.read(storageRepositoryProvider);
    final cloudSync =
        storage.getSetting(StorageKeys.consentCloudSync) as bool? ?? false;
    final effective = cloudSync && value;
    await storage.putSetting(StorageKeys.consentFleetSharing, effective);
    state = effective;
  }
}
