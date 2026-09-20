// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../perf/startup_timer.dart';
import 'hive_first_frame_boxes.dart';
import 'hive_cipher_loader.dart';
import 'hive_deferred_user_boxes.dart';
import 'impl/hive_directory_resolver.dart';
import 'hive_isolate_boxes.dart';
import 'hive_isolate_ownership.dart';
import 'hive_legacy_migration.dart';
import 'hive_schema_migration.dart';
import 'hive_test_boxes.dart';
import 'hive_trip_box_encryption.dart';

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

  /// Whole-country bulk datasets (#4110). Separate from [cache] because
  /// `openBox` DESERIALIZES every value: these are multi-MB national
  /// payloads (~11k `Station.fromJson`), and paying for them inside
  /// `hive_init` defeated the `compute()` in `PersistentDataset.readAsync`
  /// that exists to keep exactly that work off the UI isolate. Deferred,
  /// so the first frame no longer waits for it.
  static const String datasets = 'datasets';
  static const String profiles = 'profiles';
  static const String priceHistory = 'price_history';
  static const String alerts = 'alerts';

  /// Per-vehicle per-situation consumption baselines (#769).
  /// Driving-behaviour data — encrypted since #3611.
  static const String obd2Baselines = 'obd2_baselines';

  /// Rolling log of finalised OBD2 trips (#726): distance, avg
  /// L/100 km, harsh events, GPS paths (#1374). Encrypted since #3611.
  static const String obd2TripHistory = 'obd2_trip_history';

  /// badge keyed by enum name; not PII.

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
  /// treatment as the other trip boxes — encrypted since #3611.
  static const String obd2PausedTrips = 'obd2_paused_trips';

  /// Write-through snapshot of the currently-recording OBD2 trip
  /// (#1303). At most ONE entry — keyed on a fixed sentinel — that the
  /// [TripRecording] provider rewrites every few seconds while a trip is
  /// live. Survives a process death so the recovery service can put the
  /// user back on the recording screen with their captured samples on
  /// next launch. Encrypted since #3611.
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

  /// #4212 — org directory per `SyncContextKey|orgId`; encrypted, deferred.
  static const String fleetDirectory = 'fleet_directory';

  /// #4215 — fleet expenses built from scanned receipts and imported
  /// invoices, one JSON payload per expense id. Encrypted (a receipt
  /// names a person, a place, a time and a payment reference — ADR
  /// 0025 D9 files it as an accounting document) and deferred (the
  /// landing search screen needs nothing from it).
  static const String fleetExpenses = 'fleet_expenses';

  static const _encryptedBoxes = {
    settings,
    profiles,
    favorites,
    cache,
    priceHistory,
    alerts,
  };

  /// #3867 (Epic #3865) — EVERY box the app owns, for the local erasure
  /// (`LocalDataEraser`) and the export drift guards. A new box constant
  /// must be added here too: `test/core/storage/local_data_eraser_test.dart`
  /// scans this file's `static const String` declarations and fails when
  /// one is missing from this set.
  static const Set<String> allBoxes = {
    settings, favorites, cache, profiles, priceHistory, alerts,
    obd2Baselines, obd2TripHistory, obd2SupportedPids,
    obd2NegotiatedProtocol, serviceReminders, obd2PausedTrips,
    obd2ActiveTrip, priceSnapshots, isolateErrorSpool, trafficSignalsCache,
    featureFlags, appProfile, boxSchema, errorTraces, datasets,
    fleetDirectory, fleetExpenses,
  };

  /// Meta box recording the schema version of each persistent box
  /// (#1686). Unencrypted — it holds only small integers, no PII — and
  /// is keyed by box name. Lets a future release detect and run a
  /// schema migration instead of silently mis-reading old on-disk data.
  static const String boxSchema = 'box_schema';

  /// The error-trace box `TraceStorage` opens (#3867 — registered so the
  /// local erasure and the export drift guard know it exists).
  static const String errorTraces = 'error_traces';

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
  /// #4110 — 2 → 3: the `dataset:` entries moved out of [cache] into
  /// [datasets]. The bump drives the same eviction to drop the orphaned
  /// copies from the cache box; they are caches with a hard TTL, so the
  /// next search refetches one per country, once.
  /// #4189 — 3 → 4: `Station` gained `priceUpdatedAt`, the machine-
  /// readable price stamp the freshness gate reads. The field is
  /// additive and a cached blob without it degrades to today's
  /// behaviour, but the bump is what makes the fix REACH existing
  /// users: without it, a device keeps serving pre-#4189 Station blobs
  /// from cache and the confident pick stays withheld in FR/DK/PT until
  /// every entry's TTL happens to expire.
  static const int currentSchemaVersion = 4;

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
    obd2SupportedPids,
    obd2NegotiatedProtocol,
    serviceReminders,
    obd2PausedTrips,
    obd2ActiveTrip,
    priceSnapshots,
    trafficSignalsCache,
    fleetDirectory,
    fleetExpenses,
  };

  /// Deferred boxes holding driving telemetry — AES-encrypted since
  /// #3611, with a crash-safe migration in [HiveTripBoxEncryption].
  static const _encryptedDeferredBoxes = {
    obd2Baselines, obd2TripHistory, obd2PausedTrips, obd2ActiveTrip,
    // #3870 (Epic #3865) — VIN-keyed, adapter-MAC-keyed and odometer data
    // were the last plaintext identifiers on disk; same crash-safe
    // one-time migration. (`priceSnapshots` holds public station data
    // and is opened by the alert isolate — deliberately left as is.)
    obd2SupportedPids, obd2NegotiatedProtocol, serviceReminders,
    fleetDirectory, // #4212 — assignments name the person
    fleetExpenses, // #4215 — a receipt names the person who paid
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
  /// #4110 — the marks below are INSIDE this method because one
  /// `hive_init` phase around it owned 8,855 ms of an 8,891 ms cold
  /// start and could not say which kind of work did. [HiveOpenTiming]
  /// names the slowest single box; see it for why the phase cannot.
  static Future<void> init() async {
    // #3747 — on iOS the base dir is Application Support (out of the
    // UIFileSharingEnabled Documents surface), with a one-time move of
    // the legacy box files; elsewhere identical to Hive.initFlutter().
    await HiveDirectoryResolver.initHive();
    StartupTimer.instance.mark('hive_dir');
    // #4118/#4341 — throws StorageKeyLostException, before any key is
    // written or any box opened, when the files on disk need another key.
    final cipher = await HiveCipherLoader.loadGuarded();
    StartupTimer.instance.mark('hive_cipher');
    HiveDeferredUserBoxes.arm(cipher); // #4318 — the deferred opens' key

    // Phase 1 — migrate any pre-encryption plaintext boxes, ONCE ever.
    // #4110 — this ran on every cold start and cost a full open+close of
    // every encrypted box before Phase 2 opened them again. See
    // HiveLegacyMigration.runOnce. `boxSchema` is opened here rather than
    // in Phase 2 because the flag has to be readable before the decision;
    // Phase 2's open of it is then a no-op on an already-open box.
    await HiveLegacyMigration.runOnce(
        _encryptedBoxes, cipher, await Hive.openBox<int>(boxSchema));
    StartupTimer.instance.mark('hive_migrate');

    await HiveFirstFrameBoxes.openAll(cipher);
    StartupTimer.instance.mark('hive_open');

    // #2670 — the main isolate owns these for the whole app lifetime; a
    // foreground background scan's closeIsolateBoxes() must never close them.
    HiveIsolateOwnership.markOwned(mainIsolateOwnedBoxes);

    // #1686 stamp missing schema versions + #2922 run the cache eviction for
    // any box whose stamp is below currentSchemaVersion.
    await _ensureSchemaVersions();
    StartupTimer.instance.mark('hive_schema');
  }

  /// Every box the main isolate will EVER open — first-frame and deferred
  /// alike — marked owned the moment [init] returns (#2670, #4057).
  ///
  /// Ownership is a statement about the FILE, not about whether the box is
  /// open yet. The deferred boxes used to be marked only when
  /// [initDeferred] completed, which left a window after first frame in
  /// which a foreground-isolate scan's `closeIsolateBoxes()` saw
  /// `price_snapshots` as unowned. That was harmless only because the
  /// close threw on a type mismatch; #4053 fixed the close, and the
  /// window became a real "price alerts silently stop for the session".
  /// Marking up-front closes it: the scan skips the box whether or not
  /// [initDeferred] has run, and `closeIfOpen` tolerates the not-yet-open
  /// case anyway.
  @visibleForTesting
  static List<String> get mainIsolateOwnedBoxes => [
        settings, profiles, favorites, cache, priceHistory, alerts,
        isolateErrorSpool, featureFlags, appProfile, boxSchema,
        ..._deferredBoxes,
        datasets,
      ];

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

  /// Test hook for the #2922 stamp + cache-eviction migration: drives the
  /// `init()` path against already-opened boxes, without secure storage.
  @visibleForTesting
  static Future<void> ensureSchemaVersionsForTest() => _ensureSchemaVersions();

  /// The recorded schema version of [boxName], or null when the box has
  /// no stamp yet or the meta box is not open (#1686).
  static int? schemaVersionOf(String boxName) {
    if (!Hive.isBoxOpen(boxSchema)) return null;
    return Hive.box<int>(boxSchema).get(boxName);
  }

  /// Opens the deep-feature boxes ([_deferredBoxes]) that the landing
  /// screen does not need (#1794), plus the #4318 deferred user-data boxes.
  /// Idempotent — the result is cached; post-first-frame readers await
  /// `HiveBoxes.initDeferred()` without re-running the opens.
  ///
  /// #3611 — the four trip boxes ([_encryptedDeferredBoxes]) open with
  /// the same AES cipher as the first-frame boxes, after a crash-safe
  /// one-time plain→encrypted migration.
  static Future<void> initDeferred() => _deferredInit ??= _openDeferred()
      .whenComplete(() => HiveIsolateOwnership.markOwned(_deferredBoxes));

  static Future<void> _openDeferred() async {
    final cipher = await HiveCipherLoader.loadGuarded();
    // The per-box migrations are independent — run in parallel (#1764).
    await Future.wait(_encryptedDeferredBoxes
        .map((name) => HiveTripBoxEncryption.migrate(name, cipher)));
    await Future.wait([
      for (final name in _deferredBoxes)
        Hive.openBox<String>(name,
            encryptionCipher:
                _encryptedDeferredBoxes.contains(name) ? cipher : null),
      // #4110 — dynamic, not String: it holds the JSON envelopes.
      Hive.openBox<dynamic>(datasets, encryptionCipher: cipher),
      ...HiveDeferredUserBoxes.names.map(HiveDeferredUserBoxes.settled),
    ]);
    // #3882 — the deferred trip boxes carry a schema stamp too (the trip
    // history box changed its row layout to meta + columnar chunks; the
    // rewrite of legacy rows is opportunistic + background in
    // `TripHistoryRepository`, so the stamp only records the version).
    if (Hive.isBoxOpen(boxSchema)) {
      await HiveSchemaMigration.ensureSchemaVersions(
        boxSchema: boxSchema,
        encryptedBoxes: _encryptedDeferredBoxes,
        cacheBox: cache,
        currentSchemaVersion: currentSchemaVersion,
      );
    }
  }

  /// Initialize Hive in a background isolate with proper encryption. #3689 —
  /// [HiveIsolateBoxes] pins never-compact so a BG isolate can't rename files.
  static Future<void> initInIsolate() => HiveIsolateBoxes.initInIsolate();

  /// Close the Hive boxes opened by [initInIsolate] (#2670 ownership guard
  /// applies — see [HiveIsolateBoxes.closeIsolateBoxes]).
  static Future<void> closeIsolateBoxes() =>
      HiveIsolateBoxes.closeIsolateBoxes();

  /// Test stand-in for [init] — the opens live in [HiveTestBoxes]
  /// since #4215, so this file stays under the 400-line norm.
  @visibleForTesting
  static Future<void> initForTest() => HiveTestBoxes.openAll();
}
