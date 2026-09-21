// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/app/startup/launch_sync_phase.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/app_resume_sync.dart';
import 'package:tankstellen/core/sync/pending_deletions_journal.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/sync_run_trace.dart';
import 'package:tankstellen/core/sync/tanksync_init.dart';
import 'package:tankstellen/core/sync/tanksync_init_retry.dart';
import 'package:tankstellen/core/sync/tanksync_session_gate.dart';

import '../../../fakes/fake_hive_storage.dart';
import 'fake_tanksync_backend.dart';
import 'session_phase_trace.dart';

/// The settings a TankSync session keeps — everything a kill leaves in the
/// settings box that the session reads back.
const List<String> kSyncSettingKeys = [
  'sync_enabled',
  'supabase_url',
  'sync_user_id',
  'sync_mode',
  StorageKeys.consentCloudSync,
  StorageKeys.consentSyncTrips,
];

/// What a process kill leaves of a TankSync session (#4162): the sync
/// settings, the anon key, and the device keychain holding the SDK's
/// persisted session.
class SyncDiskImage {
  const SyncDiskImage({
    this.settings = const {},
    this.anonKey,
    this.keychain = const {},
    this.settingsBox = const {},
  });

  final Map<String, Object?> settings;
  final String? anonKey;
  final Map<String, String> keychain;

  /// The real Hive `settings` box, when a suite opened one — where the
  /// #3123 deletion journal and its last sync context live.
  final Map<dynamic, dynamic> settingsBox;

  SyncDiskImage copyWith({
    Map<String, Object?>? settings,
    Map<String, String>? keychain,
  }) =>
      SyncDiskImage(
        settings: settings ?? this.settings,
        anonKey: anonKey,
        keychain: keychain ?? this.keychain,
        settingsBox: settingsBox,
      );

  /// The image with no keychain — iOS keeps the keychain across a
  /// reinstall while Hive is wiped; this is the reverse, a restore that
  /// brought the settings back without the session.
  SyncDiskImage withoutKeychain() => copyWith(keychain: const {});
}

/// The Supabase URL the suites connect to by default.
const String kHostA = 'a-project.supabase.co';

/// A second, different backend (#4336).
const String kHostB = 'b-project.supabase.co';

String urlOf(String host) => 'https://$host';

/// Resets every process-wide singleton a TankSync session lives in — what
/// a process death does to memory.
void resetSyncProcess() {
  TankSyncClient.resetForTest();
  TankSyncSessionGate.instance.resetForTest();
  TankSyncInit.resetForTest();
  TankSyncInitRetry.instance.disarm();
  SyncPullCoordinator.instance.resetForTest();
  AppResumeSync.instance.resetForTest();
  SyncRunTrace.resetForTest();
  PendingDeletionsJournal.resetForTest();
  LaunchSyncPhase.entriesOverride = null;
}

/// Put [contents] into the real Hive `settings` box, when one is open.
Future<void> _restoreSettingsBox(Map<dynamic, dynamic> contents) async {
  if (!Hive.isBoxOpen(HiveBoxes.settings)) return;
  final box = Hive.box<dynamic>(HiveBoxes.settings);
  await box.clear();
  await box.putAll(contents);
}

/// One app process with a TankSync session over [FakeTankSyncBackend]
/// (#4162): the real `SyncState`, `TankSyncInit`, retry ladder, pull
/// coordinator and session gate, wired the way the launch wires them.
class SyncSession {
  SyncSession._(this.storage, this.backend, this.container, this.trace);

  final TapHiveStorage storage;
  final FakeTankSyncBackend backend;
  final ProviderContainer container;
  final SessionPhaseTrace trace;

  SyncState get sync => container.read(syncStateProvider.notifier);

  /// Start a process on [image] (a fresh device by default). With
  /// [launch], runs the production launch sequence; without, stops after
  /// the wiring so a test can drive the init itself.
  static Future<SyncSession> start({
    SyncDiskImage image = const SyncDiskImage(),
    FakeTankSyncBackend? backend,
    List<SyncPullEntry> entries = const [],
    bool launch = true,
  }) async {
    resetSyncProcess();
    await _restoreSettingsBox(image.settingsBox);
    final storage = TapHiveStorage();
    for (final e in image.settings.entries) {
      await storage.putSetting(e.key, e.value);
    }
    final anonKey = image.anonKey;
    if (anonKey != null) await storage.setSupabaseAnonKey(anonKey);
    final b = backend ??
        FakeTankSyncBackend(keychain: Map.of(image.keychain));
    TankSyncClient.debugSdk = b;
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(storage),
    ]);
    final trace = SessionPhaseTrace();
    LaunchSyncPhase.entriesOverride = () => entries;
    final session = SyncSession._(storage, b, container, trace);
    LaunchSyncPhase.registerPulls(container, storage);
    AppResumeSync.instance.configure(recordingActive: () => false);
    if (launch) await session.runLaunch();
    return session;
  }

  /// The deferred launch block: init (8 s budget), the outcome handling,
  /// the launch pulls.
  Future<void> runLaunch() async {
    try {
      await TankSyncInit.run(storage).timeout(const Duration(seconds: 8));
    } catch (_) {
      // AppInitializer logs and carries on; the outcome handling follows.
    }
    LaunchSyncPhase.handleInitOutcome(container, storage);
    if (TankSyncClient.client != null) SyncRunTrace.begin('launch');
    await LaunchSyncPhase.runLaunchPulls(container);
    await settle();
  }

  /// The disk now, as a kill would find it.
  Future<SyncDiskImage> capture() async {
    await settle();
    return snapshot();
  }

  /// The disk at this very instant — for a kill that lands inside a write
  /// sequence, from [TapHiveStorage.onPut].
  SyncDiskImage snapshot() {
    return SyncDiskImage(
      settings: {
        for (final k in kSyncSettingKeys)
          if (storage.getSetting(k) != null) k: storage.getSetting(k),
      },
      anonKey: storage.getSupabaseAnonKey(),
      keychain: Map.of(backend.keychain),
      settingsBox: Hive.isBoxOpen(HiveBoxes.settings)
          ? Map.of(Hive.box<dynamic>(HiveBoxes.settings).toMap())
          : const {},
    );
  }

  /// Kill this process and start a new one on [image] — same device
  /// keychain and servers unless the image says otherwise.
  Future<SyncSession> relaunch(
    SyncDiskImage image, {
    List<SyncPullEntry> entries = const [],
    bool launch = true,
  }) async {
    kill();
    final next = FakeTankSyncBackend(
      keychain: Map.of(image.keychain),
      projects: backend.projects,
    );
    return start(
        image: image, backend: next, entries: entries, launch: launch);
  }

  /// The process dies: nothing it holds in memory runs again.
  void kill() {
    trace.close();
    container.dispose();
  }

  /// Seed a consented device and connect it to [host] through the setup
  /// screen's path; returns the session after the initial sync settled.
  Future<void> connectConsented({String host = kHostA}) async {
    await setConsent(true);
    await sync.connect(urlOf(host), 'anon-key-$host');
    await settle();
  }

  /// Save the Cloud Sync consent the way the privacy screen does.
  Future<void> setConsent(bool cloudSync) async {
    final c = container.read(gdprConsentProvider);
    await container.read(gdprConsentProvider.notifier).save(
          location: c.location,
          errorReporting: c.errorReporting,
          cloudSync: cloudSync,
          vinOnlineDecode: c.vinOnlineDecode,
          syncTrips: c.syncTrips,
        );
    await settle();
  }

  /// Let fire-and-forget work (the initial sync, auth-stream persistence)
  /// land.
  static Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await pumpEventQueue();
    }
  }

  Future<void> dispose() async {
    trace.close();
    container.dispose();
    await backend.dispose();
    resetSyncProcess();
  }
}

/// A pull entry whose body a test holds open: it starts, reports, then
/// waits for [release] before it touches the transport.
class GatedPull {
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  Future<void> Function()? body;

  SyncPullEntry entry({String table = 'favorites'}) => SyncPullEntry(
        tables: [table],
        timeout: const Duration(seconds: 15),
        pull: () async {
          if (!started.isCompleted) started.complete();
          await release.future;
          await body?.call();
          return 0;
        },
      );
}

/// A [FakeHiveStorage] that reports every settings write — the hook a kill
/// test uses to land between two writes of one sequence.
class TapHiveStorage extends FakeHiveStorage {
  void Function(String key)? onPut;

  @override
  Future<void> putSetting(String key, dynamic value) async {
    await super.putSetting(key, value);
    onPut?.call(key);
  }
}
