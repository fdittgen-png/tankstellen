// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/storage_repository.dart';
import '../storage/storage_keys.dart';
import '../storage/storage_providers.dart';
import '../sync/content_reports_sync.dart';

part 'content_moderation_providers.g.dart';

/// Community-content moderation state (#3726 — Play UGC policy).
///
/// Two device-local, Hive-persisted sets drive what community content is
/// visible:
///
///  * [BlockedContentAuthors] — user ids whose shared content the viewer
///    blocked. Local-only (never synced): blocking is a viewer
///    preference, not shared state.
///  * [ReportedContentTargets] — target ids the viewer reported via
///    "Report content". A reported item hides immediately and stays
///    hidden across restarts, independent of any server-side outcome.
///
/// Every surface that renders another user's content filters against
/// both sets (currently the "Shared with me" trips; future community
/// surfaces reuse the same providers).

/// Reads a persisted string list defensively: a missing key, a
/// malformed value or an unavailable settings box (storage not yet
/// initialised — e.g. widget-test harnesses) all degrade to the empty
/// set. Moderation state must never take a render surface down.
Set<String> _readStringSet(SettingsStorage storage, String key) {
  try {
    final raw = storage.getSetting(key);
    return raw is List ? raw.whereType<String>().toSet() : <String>{};
  } catch (_) {
    return <String>{};
  }
}

/// Best-effort persist: a failed write keeps the in-memory state (the
/// content stays hidden for this session) instead of throwing out of a
/// tap handler.
Future<void> _persistStringSet(
  SettingsStorage storage,
  String key,
  Set<String> value,
) async {
  try {
    await storage.putSetting(key, value.toList());
  } catch (e, st) {
    debugPrint('content_moderation: persisting $key failed: $e\n$st');
  }
}

/// The authors (TankSync user ids) blocked on this device.
@Riverpod(keepAlive: true)
class BlockedContentAuthors extends _$BlockedContentAuthors {
  @override
  Set<String> build() => _readStringSet(
      ref.watch(settingsStorageProvider), StorageKeys.blockedContentAuthorIds);

  /// Block [authorUserId]: their shared content disappears everywhere
  /// it is rendered on this device.
  Future<void> block(String authorUserId) async {
    if (authorUserId.isEmpty || state.contains(authorUserId)) return;
    final next = {...state, authorUserId};
    await _persistStringSet(ref.read(settingsStorageProvider),
        StorageKeys.blockedContentAuthorIds, next);
    state = next;
  }

  /// Unblock a previously blocked author. No UI surfaces this yet
  /// (#3726 keeps the block flow minimal); kept so a future settings
  /// list only needs a widget, not new state plumbing.
  Future<void> unblock(String authorUserId) async {
    if (!state.contains(authorUserId)) return;
    final next = {...state}..remove(authorUserId);
    await _persistStringSet(ref.read(settingsStorageProvider),
        StorageKeys.blockedContentAuthorIds, next);
    state = next;
  }
}

/// The content target ids the viewer reported (and therefore hides).
@Riverpod(keepAlive: true)
class ReportedContentTargets extends _$ReportedContentTargets {
  @override
  Set<String> build() => _readStringSet(
      ref.watch(settingsStorageProvider), StorageKeys.reportedContentTargetIds);

  /// Persistently hide the reported [targetId] on this device.
  Future<void> hide(String targetId) async {
    if (targetId.isEmpty || state.contains(targetId)) return;
    final next = {...state, targetId};
    await _persistStringSet(ref.read(settingsStorageProvider),
        StorageKeys.reportedContentTargetIds, next);
    state = next;
  }
}

/// Signature of the report-submission call the UI invokes — injectable
/// so a widget test can record the call without a live Supabase session.
typedef ContentReportSubmit = Future<bool> Function({
  required String targetKind,
  required String targetId,
});

/// Production submitter: writes one `content_reports` row via
/// [ContentReportsSync.submit]. Returns whether the row reached the
/// server so the UI can confirm honestly.
@Riverpod(keepAlive: true)
ContentReportSubmit contentReportSubmit(Ref ref) =>
    ({required String targetKind, required String targetId}) =>
        ContentReportsSync.submit(targetKind: targetKind, targetId: targetId);
