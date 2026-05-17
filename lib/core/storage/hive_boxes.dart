import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  /// `make:model:year` (fallback when the car doesn't return a VIN).
  /// Values are sorted `List<int>` of PID indices the car implements
  /// for Mode 01. Small, not PII, opened unencrypted like the other
  /// OBD2 boxes.
  static const String obd2SupportedPids = 'obd2_supported_pids';

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
  /// (#1303). At most ONE entry — keyed on a fixed sentinel — that
  /// the [TripRecording] provider rewrites every few seconds while a
  /// trip is live. Survives a process death so the recovery service
  /// can put the user back on the recording screen with their
  /// captured samples on next launch. Same privacy treatment as the
  /// other OBD2 boxes — unencrypted, opened once at startup.
  static const String obd2ActiveTrip = 'obd2_active_trip';

  /// Rolling price snapshots used by the price-drop velocity detector
  /// (#579). One JSON payload per (station, fuel, timestamp) with a
  /// synthetic key. Coords are captured per-snapshot so the detector
  /// can filter by radius without re-joining against station data.
  /// Pruned to the last 6 h on every write to keep the box small.
  /// Unencrypted like the other OBD2 boxes — contains no PII beyond
  /// public station coordinates.
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
  static const _hiveEncryptionKeyName = 'hive_encryption_key';

  /// Meta box recording the schema version of each persistent box
  /// (#1686). Unencrypted — it holds only small integers, no PII — and
  /// is keyed by box name. Lets a future release detect and run a
  /// schema migration instead of silently mis-reading old on-disk data.
  static const String boxSchema = 'box_schema';

  /// Current persistent-storage schema version. Bump when the on-disk
  /// shape of any box changes; pair the bump with a migration step.
  static const int currentSchemaVersion = 1;

  static Future<HiveAesCipher> _loadCipher() async {
    const secureStorage = FlutterSecureStorage();
    final existing = await secureStorage.read(key: _hiveEncryptionKeyName);
    if (existing != null) {
      final keyBytes = base64Url.decode(existing);
      return HiveAesCipher(keyBytes);
    }
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _hiveEncryptionKeyName,
      value: base64UrlEncode(key),
    );
    return HiveAesCipher(key);
  }

  /// One-time migration of a pre-encryption plaintext [boxName] into an
  /// encrypted box (#1686).
  ///
  /// A box already written with the cipher opens cleanly — nothing to
  /// do. When the cipher open fails, a plaintext open is attempted: a
  /// box that still carries plaintext data is migrated; one that fails
  /// the plaintext open too is damaged and is **left on disk
  /// untouched** — corruption is never resolved by deleting user data.
  /// A box Hive cannot open at all then surfaces in [init]'s Phase 2 as
  /// a [HiveCorruptionException].
  static Future<void> _migrateLegacyPlaintextBox(
      String boxName, HiveAesCipher cipher) async {
    try {
      final box = await Hive.openBox(boxName, encryptionCipher: cipher);
      await box.close();
      return; // Already encrypted, or a fresh install.
    } catch (_) {
      // Fall through — the box may be a pre-encryption plaintext box.
    }

    Box<dynamic> plain;
    try {
      plain = await Hive.openBox(boxName);
    } catch (e, st) { // ignore: unused_catch_stack
      debugPrint('Hive: "$boxName" unreadable during the migration probe '
          '— left on disk for Phase 2 to surface.');
      return;
    }

    await _migrateToEncrypted(boxName, plain, cipher);
  }

  /// Copies an already-open plaintext [plain] box into an encrypted box
  /// of the same name (#1686).
  ///
  /// The plaintext file is deleted only *after* its entries are held in
  /// memory, so an interruption mid-migration cannot lose data — a
  /// crash leaves the still-intact plaintext box, never an empty one.
  static Future<void> _migrateToEncrypted(
      String boxName, Box<dynamic> plain, HiveAesCipher cipher) async {
    final entries = Map<dynamic, dynamic>.from(plain.toMap());
    await plain.close();

    await Hive.deleteBoxFromDisk(boxName);
    final encryptedBox =
        await Hive.openBox(boxName, encryptionCipher: cipher);
    if (entries.isNotEmpty) {
      await encryptedBox.putAll(entries);
    }
    await encryptedBox.close();
    debugPrint('Hive: migrated "$boxName" to encrypted storage '
        '(${entries.length} entries)');
  }

  /// Test hook for [_migrateToEncrypted] (#1686).
  @visibleForTesting
  static Future<void> migrateToEncryptedForTest(
          String boxName, Box<dynamic> plain, HiveAesCipher cipher) =>
      _migrateToEncrypted(boxName, plain, cipher);

  /// Boxes only read by deep OBD2 / trip / badge / snapshot / glide
  /// features — none is needed to paint the landing search screen, so
  /// [initDeferred] opens them *after* the first frame (#1794).
  static const _deferredBoxes = {
    obd2Baselines,
    obd2TripHistory,
    achievements,
    obd2SupportedPids,
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
    final cipher = await _loadCipher();

    // Phase 1 — migrate any pre-encryption plaintext boxes. The probes
    // are independent, so they (and any migration) run in parallel.
    await Future.wait<void>(
      _encryptedBoxes
          .map((boxName) => _migrateLegacyPlaintextBox(boxName, cipher)),
    );

    // Phase 2 — open the first-frame-critical boxes in one parallel
    // batch: the 6 encrypted domain boxes plus the unencrypted boxes the
    // landing path / background isolate need immediately.
    //
    // #1686 — a box file damaged beyond Hive's own crash recovery
    // throws here. It is re-tagged as a HiveCorruptionException so the
    // startup error path can prompt for recovery, rather than crashing
    // on a raw HiveError or booting with the box silently missing.
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
      // HiveError is Hive's runtime storage-failure type (a damaged box
      // file), not a programmer bug — re-tag it for the startup path.
    } on HiveError catch (e) { // ignore: avoid_catching_errors
      throw HiveCorruptionException(
          'a storage box could not be opened (${e.message})');
    }

    // #1686 — stamp the current schema version for any box that lacks
    // one, so a future release can detect and migrate old on-disk data.
    await _ensureSchemaVersions();
  }

  /// Records [currentSchemaVersion] for every encrypted domain box that
  /// is not yet stamped (#1686). Existing stamps are left untouched — a
  /// real schema migration owns bumping them.
  static Future<void> _ensureSchemaVersions() async {
    final schema = Hive.box<int>(boxSchema);
    for (final boxName in _encryptedBoxes) {
      if (schema.get(boxName) == null) {
        await schema.put(boxName, currentSchemaVersion);
      }
    }
  }

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
      );

  /// Initialize Hive in a background isolate with proper encryption.
  static Future<void> initInIsolate() async {
    await Hive.initFlutter();
    final cipher = await _loadCipher();
    await Hive.openBox(settings, encryptionCipher: cipher);
    await Hive.openBox(favorites, encryptionCipher: cipher);
    await Hive.openBox(alerts, encryptionCipher: cipher);
    await Hive.openBox(cache, encryptionCipher: cipher);
    await Hive.openBox(priceHistory, encryptionCipher: cipher);
    // #579 — velocity detector reads/writes snapshots from the BG
    // isolate, mirroring the main-isolate open above.
    await Hive.openBox<String>(priceSnapshots);
    // #1105 — isolate error spool: background-isolate errors written
    // here while Riverpod is unavailable, drained by the foreground
    // initialiser into TraceRecorder.
    await Hive.openBox<String>(isolateErrorSpool);
  }

  /// Close all Hive boxes opened by [initInIsolate].
  ///
  /// Must be called at the end of every background task to release file
  /// handles and prevent race conditions with the main isolate.
  static Future<void> closeIsolateBoxes() async {
    final boxNames = [settings, favorites, alerts, cache, priceHistory, priceSnapshots, isolateErrorSpool];
    for (final name in boxNames) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).close();
        }
      } catch (e, st) {
        debugPrint('HiveBoxes: failed to close box "$name": $e\n$st');
      }
    }
  }

  @visibleForTesting
  static Future<void> initForTest() async {
    await Hive.openBox(settings);
    await Hive.openBox(favorites);
    await Hive.openBox(cache);
    await Hive.openBox(profiles);
    await Hive.openBox(priceHistory);
    await Hive.openBox(alerts);
    // #584 — service reminders live in their own box so tests that
    // exercise the vehicle feature can open it without pulling in the
    // rest of the app. String-typed to match runtime.
    await Hive.openBox<String>(serviceReminders);
    // #797 — paused trips box, string-typed JSON, matches runtime.
    await Hive.openBox<String>(obd2PausedTrips);
    // #1303 — active-trip snapshot box, string-typed JSON.
    await Hive.openBox<String>(obd2ActiveTrip);
    // #579 — velocity detector snapshots. String-typed JSON so the
    // same one-adapter pattern covers unit tests + runtime.
    await Hive.openBox<String>(priceSnapshots);
    // #1686 — schema-version meta box, mirrors the runtime open.
    await Hive.openBox<int>(boxSchema);
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
