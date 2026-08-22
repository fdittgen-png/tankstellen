// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'consumption_providers.dart';

/// #3762 — broken-MAP belief persistence, split out of
/// `consumption_providers.dart` as a `part` to satisfy the #1680 file-
/// length ratchet. Move-only: behaviour preserved verbatim. The settings-
/// key constants and the Hive load/persist helpers of
/// [BrokenMapBeliefByVehicle] live here; the `part` keeps them in the
/// same library so private access and every existing import path are
/// unchanged.

/// Settings-box key prefix used by [BrokenMapBeliefByVehicle] for
/// per-vehicle persistence (#1423 phase 4). Separate namespace from
/// [ObdAdapterBlocklist]'s adapter-keyed entries — the two are
/// orthogonal: vehicle-keyed survives an adapter change; adapter-keyed
/// survives a vehicle change.
@visibleForTesting
const String brokenMapBeliefSettingsKeyPrefix = 'brokenMapBelief:';

/// Threshold above which a belief is considered actionable enough to
/// persist into the [ObdAdapterBlocklist] (#1423 phase 4). Mirrors the
/// spec § C wording: "if matched and confidence > 0.7, surface the
/// warning". Below this we still update the per-vehicle belief in
/// settings, but don't pollute the adapter blocklist with weak signals.
@visibleForTesting
const double brokenMapBlocklistThreshold = 0.7;

/// Hive-backed persistence half of [BrokenMapBeliefByVehicle] (#1423
/// phase 4). Constrained `on _$BrokenMapBeliefByVehicle` so it reads the
/// same `ref` the notifier owns; the notifier applies it via `with`.
mixin _BrokenMapBeliefStorePersistence on _$BrokenMapBeliefByVehicle {
  /// Synchronously decode the persisted belief for [vehicleId]. Returns
  /// null when no entry exists or when the JSON payload can't be
  /// parsed (defensive against schema drift / hand-edited values).
  BrokenMapBelief? _loadFromStorage(String vehicleId) {
    try {
      final storage = ref.read(settingsStorageProvider);
      final raw = storage.getSetting(_keyFor(vehicleId));
      if (raw is! String || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return BrokenMapBelief.fromJson(json);
    } catch (e, st) {
      // Synchronous debugPrint instead of errorLogger.log: when this
      // provider runs in an unbound zone (ProviderContainer without
      // bindContainer — every unit test for the notifier), errorLogger
      // falls through to IsolateErrorSpool.enqueue, which opens a Hive
      // box. That fire-and-forget Hive open races the test's tearDown
      // (which deletes the temp Hive dir) and surfaces as
      // PathNotFoundException + LateInitializationError "after test
      // completion". Returning null falls back to a fresh belief —
      // the worst case is one re-probed pair, not a crash.
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'brokenMapBeliefByVehicle.load failed'}));
      return null;
    }
  }

  /// Persist [belief] under [vehicleId]. Async-throws are caught and
  /// logged — the calling fill-up save must not be derailed by a
  /// storage hiccup.
  Future<void> _persist(String vehicleId, BrokenMapBelief belief) async {
    try {
      final SettingsStorage storage = ref.read(settingsStorageProvider);
      final encoded = jsonEncode(belief.toJson());
      await storage.putSetting(_keyFor(vehicleId), encoded);
    } catch (e, st) {
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: const {
          'op': 'brokenMapBeliefByVehicle.persist',
        },
      );
    }
  }

  String _keyFor(String vehicleId) =>
      '$brokenMapBeliefSettingsKeyPrefix$vehicleId';
}
