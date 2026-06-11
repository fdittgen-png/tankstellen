// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_cipher_loader.dart';
import 'hive_isolate_ownership.dart';
import 'hive_legacy_migration.dart';
import 'hive_schema_migration.dart';

/// Thrown by [HiveBoxes.init] when a persistent box cannot be opened —
/// its file is damaged beyond Hive's own crash recovery (#1686).
///
/// Box corruption is never resolved by silently deleting the file —
/// favorites, profiles and price history are user data. The failure is
/// surfaced to the startup error path so the app can show a recovery
/// prompt instead of booting with data missing.
class HiveCorruptionException implements Exception {
  /// Human-readable detail of what failed.
  final String message;

  const HiveCorruptionException(this.message);

  @override
  String toString() => 'HiveCorruptionException: $message — the box file '
      'is left on disk for recovery, not deleted.';
}

/// Shared Hive box names and initialization logic.
///
/// All domain stores access their boxes through this class.
/// Box-opening, encryption setup, and migration live here so
/// that each domain store stays focused on its own data operations.
class HiveBoxes {
  HiveBoxes._();

  static const String settings = 'settings';
  static const String favorites = 'favorites';
  static const String cache = 'cache';
  static const String profiles = 'profiles';
  static const String priceHistory = 'price_history';
  static const String alerts = 'alerts';

  /// Per-vehicle per-situation consumption baselines (#769). Plain
  /// averages like "7.2 L/100 km at highway cruise" are not PII and
  /// live outside the encrypted set to keep startup cheap.
  static const String obd2Baselines = 'obd2_baselines';

  /// Rolling log of finalised OBD2 trips (#726). Aggregated driving
  /// metrics (distance, avg L/100 km, harsh events). Treated like the
  /// baselines box: unencrypted, opened once at startup.
  static const String obd2TripHistory = 'obd2_trip_history';

  /// Earned gamification badges (#781). One JSON payload per earned
  /// badge keyed by enum name; not PII.
  static const String achievements = 'achievements';

  /// Supported-PID bitmap cache (#811). Keyed by VIN (preferred) or
  /// `make:model:year` (fallback). Sorted `List<int>` of Mode-01 PID
  /// indices the car implements. Small, not PII, opened unencrypted.
  static const String obd2SupportedPids = 'obd2_supported_pids';

  /// Negotiated ELM327 protocol cache (#2261). Keyed `adapterMac(:vin)`;
  /// value is the `ATDPN` protocol digit for warm `ATSP{n}` connects.
  static const String obd2NegotiatedProtocol = 'obd2_negotiated_protocol';

  /// Odometer-based service reminders (#584). One JSON payload per
  /// reminder keyed by reminder id. Not PII (label + interval +
  /// odometer) — unencrypted to keep startup cheap, same as
  /// [obd2Baselines] and [achievements].
  static const String serviceReminders = 'service_reminders';

  /// In-flight OBD2 trips that were paused by a transient Bluetooth
  /// drop (#797 phase 1). One JSON payload per paused session keyed by
  /// the session id (ISO start timestamp). Entries are consumed by
  /// [TripRecordingController.resume] or auto-finalised into
  /// [obd2TripHistory] when the grace window expires. Same privacy
  /// treatment as the other OBD2 boxes — unencrypted, opened once at
  /// startup.
  static const String obd2PausedTrips = 'obd2_paused_trips';

  /// Write-through snapshot of the currently-recording OBD2 trip
  /// (#1303). At most ONE entry — keyed on a fixed sentinel — that the
  /// [TripRecording] provider rewrites every few seconds while a trip is
  /// live. Survives a process death so the recovery service can put the
  /// user back on the recording screen with their captured samples on
  /// next launch. Unencrypted, opened once at startup.
  static const String obd2ActiveTrip = 'obd2_active_trip';

  /// Rolling price snapshots used by the price-drop velocity detector
  /// (#579). One JSON payload per (station, fuel, timestamp); coords are
  /// captured per-snapshot for radius filtering. Pruned to the last 6 h
  /// on every write. Unencrypted — no PII beyond public coordinates.
  static const String priceSnapshots = 'price_snapshots';

  /// Ring buffer of background-isolate errors awaiting foreground
  /// replay through `TraceRecorder` (#1105). Up to 50 JSON-encoded
  /// `IsolateErrorSpoolEntry` payloads keyed by a synthetic
  /// timestamp+index string. Lives outside the encrypted set so the
  /// WorkManager isolate can write to it before consent / encryption
  /// keys are available.
  static const String isolateErrorSpool = 'isolate_error_spool';

  /// Glide-coach OSM traffic-signal cache (#1125 phase 1). Public OSM
  /// data, no PII — unencrypted like the other low-sensitivity boxes.
  static const String trafficSignalsCache = 'traffic_signals_cache';

  /// Central feature-flag set (#1373 phase 1).
  static const String featureFlags = 'feature_flags';

  /// Active "use mode" profile (#1517). One entry keyed `profile`
  /// holding the [AppProfile] enum name. Empty box → user has not
  /// onboarded yet → wizard's profile-choice page is the gate. A
  /// pre-#1517 install with feature_flags already populated migrates
  /// to `AppProfile.custom` on first launch (see
  /// `app_profile_provider.dart`).
  static const String appProfile = 'app_profile';

  static const _encryptedBoxes = {
    settings,
    profiles,
    favorites,
    cache,
    priceHistory,
    alerts,
  };

  /// Meta box recording the schema version of each persistent box
  /// (#1686). Unencrypted — it holds only small integers, no PII — and
  /// is keyed by box name. Lets a future release detect and run a
  /// schema migration instead of silently mis-reading old on-disk data.
  static const String boxSchema = 'box_schema';

  /// Current persistent-storage schema version. Bump when the on-disk shape of
  /// any box changes; pair the bump with a migration step.
  ///
  /// #2922 — 1 → 2: `Station.openingHours` went JSON-EXCLUDED (#2722) →
  /// SERIALIZED (#2776/#2777) without a bump, so old-format `Station` blobs kept
  /// being served (phantom brand, truncated far-only results, missing prices)
  /// until a manual app-data clear. The bump drives
  /// [HiveSchemaMigration.evictStaleCacheOnUpgrade] to clear the network-cache
  /// entries (only) so they refetch fresh; the schema-guard test pins the
  /// cached-`Station` key set here so a future change without a bump FAILS.
  static const int currentSchemaVersion = 2;

  // #3149 — the secure-storage cipher load (and its StorageInitException
  // re-tag) lives in HiveCipherLoader so a keychain/keystore fault
  // surfaces typed instead of bricking the splash untyped.

  /// Test hook for [HiveLegacyMigration.migrateToEncrypted] (#1686).
  @visibleForTesting
  static Future<void> migrateToEncryptedForTest(
          String boxName, Box<dynamic> plain, HiveAesCipher cipher) =>
      HiveLegacyMigration.migrateToEncrypted(boxName, plain, cipher);

  /// Boxes only read by deep OBD2 / trip / badge / snapshot / glide
  /// features — none is needed to paint the landing search screen, so
  /// [initDeferred] opens them *after* the first frame (#1794).
  static const _deferredBoxes = {
    obd2Baselines,
    obd2TripHistory,
    achievements,
    obd2SupportedPids,
    obd2NegotiatedProtocol,
    serviceReminders,
    obd2PausedTrips,
    obd2ActiveTrip,
    priceSnapshots,
    trafficSignalsCache,
  };

  static Future<void>? _deferredInit;

  /// Initialize the Hive boxes required to paint the first frame.
  ///
  /// #1764 — the encrypted-box migration probe and the box opens each
  /// run their disk I/O concurrently via [Future.wait] rather than
  /// awaiting ~30 `openBox` calls one at a time.
  ///
  /// #1794 — only the boxes the landing screen needs open here. The
  /// nine deep-feature boxes in [_deferredBoxes] move to [initDeferred],
  /// which the app-initializer kicks after the first frame. Every box
  /// `init()` opens is still open before it returns.
  static Future<void> init() async {
    await Hive.initFlutter();
    final cipher = await HiveCipherLoader.loadGuarded();

    // Phase 1 — migrate any pre-encryption plaintext boxes. The probes
    // are independent, so they (and any migration) run in parallel.
    await Future.wait<void>(
      _encryptedBoxes.map((boxName) =>
          HiveLegacyMigration.migrateLegacyPlaintextBox(boxName, cipher)),
    );

    // Phase 2 — open the first-frame-critical boxes in one parallel
    // batch. #1686 — a box damaged beyond Hive's crash recovery throws
    // here; it is re-tagged as a HiveCorruptionException for the startup
    // error path rather than crashing on a raw HiveError.
    try {
      await Future.wait<Box<dynamic>>([
        Hive.openBox(settings, encryptionCipher: cipher),
        Hive.openBox(profiles, encryptionCipher: cipher),
        Hive.openBox(favorites, encryptionCipher: cipher),
        Hive.openBox(cache, encryptionCipher: cipher),
        Hive.openBox(priceHistory, encryptionCipher: cipher),
        Hive.openBox(alerts, encryptionCipher: cipher),
        // #1105 — isolate error spool: the background isolate writes
        // here before Riverpod is available, so it must be open now.
        Hive.openBox<String>(isolateErrorSpool),
        // #1373 — central feature-flag set: read during the first build.
        Hive.openBox<dynamic>(featureFlags),
        // #1517 — active "use mode" profile: gates the first route.
        Hive.openBox<dynamic>(appProfile),
        // #1686 — schema-version meta box. Unencrypted: small integers.
        Hive.openBox<int>(boxSchema),
      ]);
      // HiveError is Hive's runtime storage-failure type, not a bug.
    } on HiveError catch (e, st) { // ignore: avoid_catching_errors, unused_catch_stack
      throw HiveCorruptionException(
          'a storage box could not be opened (${e.message})');
    }

    // #2670 — the main isolate owns these for the whole app lifetime; a
    // foreground background scan's closeIsolateBoxes() must never close them.
    HiveIsolateOwnership.markOwned(const [
      settings, profiles, favorites, cache, priceHistory, alerts,
      isolateErrorSpool, featureFlags, appProfile, boxSchema,
    ]);

    // #1686 stamp missing schema versions + #2922 run the cache eviction for
    // any box whose stamp is below currentSchemaVersion.
    await _ensureSchemaVersions();
  }

  /// Stamps + migrates the persistent boxes against [currentSchemaVersion]
  /// (#1686 stamp + #2922 cache eviction). Delegates to [HiveSchemaMigration];
  /// the heavy logic lives there so this box-lifecycle file stays under the
  /// file-length norm.
  static Future<void> _ensureSchemaVersions() =>
      HiveSchemaMigration.ensureSchemaVersions(
        boxSchema: boxSchema,
        encryptedBoxes: _encryptedBoxes,
        cacheBox: cache,
        currentSchemaVersion: currentSchemaVersion,
      );

  /// Test hook for the #2922 stamp + cache-eviction migration: drives the same
  /// [_ensureSchemaVersions] path `init()` runs, against boxes the test has
  /// already opened, without FlutterSecureStorage / `initFlutter` (#2922).
  @visibleForTesting
  static Future<void> ensureSchemaVersionsForTest() => _ensureSchemaVersions();

  /// The recorded schema version of [boxName], or null when the box has
  /// no stamp yet or the meta box is not open (#1686).
  static int? schemaVersionOf(String boxName) {
    if (!Hive.isBoxOpen(boxSchema)) return null;
    return Hive.box<int>(boxSchema).get(boxName);
  }

  /// Opens the deep-feature boxes ([_deferredBoxes]) that the landing
  /// screen does not need (#1794).
  ///
  /// Idempotent — the result is cached, so every post-first-frame
  /// reader of a deferred box can `await HiveBoxes.initDeferred()` to
  /// be sure its box is open without re-running the opens.
  static Future<void> initDeferred() => _deferredInit ??= Future.wait(
        _deferredBoxes.map((name) => Hive.openBox<String>(name)),
      ).whenComplete(() => HiveIsolateOwnership.markOwned(_deferredBoxes));

  /// Initialize Hive in a background isolate with proper encryption.
  static Future<void> initInIsolate() async {
    await Hive.initFlutter();
    final cipher = await HiveCipherLoader.loadGuarded();
    await Hive.openBox<dynamic>(settings, encryptionCipher: cipher);
    await Hive.openBox<dynamic>(favorites, encryptionCipher: cipher);
    await Hive.openBox<dynamic>(profiles, encryptionCipher: cipher); // #2205 BG widget
    await Hive.openBox<dynamic>(alerts, encryptionCipher: cipher);
    await Hive.openBox<dynamic>(cache, encryptionCipher: cipher);
    await Hive.openBox<dynamic>(priceHistory, encryptionCipher: cipher);
    // #579 — velocity detector reads/writes snapshots from the BG
    // isolate, mirroring the main-isolate open above.
    await Hive.openBox<String>(priceSnapshots);
    // #1105 — isolate error spool: background-isolate errors written
    // here while Riverpod is unavailable, drained by the foreground
    // initialiser into TraceRecorder.
    await Hive.openBox<String>(isolateErrorSpool);
    // #2866 — feature flags (uncipher'd, mirroring the foreground open) so the
    // background scan can read the developer-mode flag to dev-gate the #2824
    // data-access trace export. Best-effort; the scan no-ops the trace if this
    // is unavailable.
    await Hive.openBox<dynamic>(featureFlags);
  }

  /// Close the Hive boxes opened by [initInIsolate] at the end of a
  /// background task to release file handles.
  ///
  /// #2670 — boxes [HiveIsolateOwnership] records as main-isolate-owned (from
  /// [init] / [initDeferred] / [initForTest]) are **skipped**: when the scan
  /// ran inside the foreground isolate these are the live, shared global
  /// handles the rest of the app still uses, and closing them produced the
  /// `FileSystemException: File closed, path='…/cache.hive'` field crash. A
  /// true spawned `dart:isolate` worker never ran [init], so its registry is
  /// empty and every [initInIsolate] handle is still closed.
  static Future<void> closeIsolateBoxes() async {
    final boxNames = [settings, favorites, alerts, cache, priceHistory, priceSnapshots, isolateErrorSpool, featureFlags];
    for (final name in boxNames) {
      if (HiveIsolateOwnership.isOwned(name)) continue;
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box<dynamic>(name).close();
        }
      } catch (e, st) {
        debugPrint('HiveBoxes: failed to close box "$name": $e\n$st');
      }
    }
  }

  @visibleForTesting
  static Future<void> initForTest() async {
    await Hive.openBox<dynamic>(settings);
    await Hive.openBox<dynamic>(favorites);
    await Hive.openBox<dynamic>(cache);
    await Hive.openBox<dynamic>(profiles);
    await Hive.openBox<dynamic>(priceHistory);
    await Hive.openBox<dynamic>(alerts);
    // #584 — service reminders live in their own box so tests that
    // exercise the vehicle feature can open it without pulling in the
    // rest of the app. String-typed to match runtime.
    await Hive.openBox<String>(serviceReminders);
    // #797 — paused trips box, string-typed JSON, matches runtime.
    await Hive.openBox<String>(obd2PausedTrips);
    await Hive.openBox<String>(obd2NegotiatedProtocol); // #2261
    // #1303 — active-trip snapshot box, string-typed JSON.
    await Hive.openBox<String>(obd2ActiveTrip);
    // #579 — velocity detector snapshots. String-typed JSON so the
    // same one-adapter pattern covers unit tests + runtime.
    await Hive.openBox<String>(priceSnapshots);
    // #1686 — schema-version meta box, mirrors the runtime open.
    await Hive.openBox<int>(boxSchema);
    // #2670 — initForTest stands in for the main isolate's init(): the boxes
    // it opens are main-isolate-owned, so closeIsolateBoxes() leaves them open
    // (mirroring the production foreground-isolate scenario).
    HiveIsolateOwnership.markOwned(const [
      settings, favorites, cache, profiles, priceHistory, alerts,
      serviceReminders, obd2PausedTrips, obd2NegotiatedProtocol,
      obd2ActiveTrip, priceSnapshots, boxSchema,
    ]);
  }

  /// Safely converts any Hive map to a typed map.
  /// Returns null if input is not a Map.
  static Map<String, dynamic>? toStringDynamicMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return _deepConvert(value);
    if (value is Map) {
      return _deepConvert(Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      ));
    }
    return null;
  }

  /// Recursively convert nested Hive `_Map` to `Map<String, dynamic>`.
  static Map<String, dynamic> _deepConvert(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Map && value is! Map<String, dynamic>) {
        return MapEntry(key, toStringDynamicMap(value));
      }
      if (value is List) {
        return MapEntry(key, value.map((e) {
          if (e is Map) return toStringDynamicMap(e);
          return e;
        }).toList());
      }
      return MapEntry(key, value);
    });
  }
}
