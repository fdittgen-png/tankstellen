// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/sync/supabase_client.dart';
import '../../../core/sync/sync_transport.dart'
    show JsonRow, SyncFencedException;
import '../../../core/time/app_clock.dart';
import '../domain/document_meta.dart';

/// The `retention_class` value the SERVER column carries (#4215).
///
/// snake_case like every other column vocabulary, and separate from
/// the Dart enum's spelling for the same reason `status` is: a
/// retention rule is read by SQL, and a rename on the Dart side must
/// not silently change what a retention job matches.
String documentRetentionColumn(DocumentRetentionClass retention) =>
    switch (retention) {
      DocumentRetentionClass.accountingDocument => 'accounting_document',
      DocumentRetentionClass.attributionEvidence => 'attribution_evidence',
      DocumentRetentionClass.userManaged => 'user_managed',
    };

/// The private-object seam the receipt bytes cross (#4215).
///
/// Four operations and no fifth. There is deliberately **no
/// `publicUrl`**: ADR 0025 forbids a publicly-addressable receipt, and
/// the way to guarantee that is for the seam not to be able to produce
/// one. Reads are short-lived signed URLs, and [logAccess] is the
/// audit row that must exist before one is handed out.
abstract class FleetDocumentTransport {
  /// The authenticated caller.
  String get userId;

  /// Write [bytes] to [objectKey] in the private bucket, replacing any
  /// previous version of the same key.
  Future<void> putObject({
    required String objectKey,
    required Uint8List bytes,
    required String contentType,
  });

  /// A signed URL for [objectKey], valid for [ttl] and never persisted
  /// by the caller.
  Future<String> signedUrl({
    required String objectKey,
    required Duration ttl,
  });

  /// Upsert one `fleet_documents` metadata row.
  Future<void> upsertMetadata(JsonRow row);

  /// The caller's own metadata rows.
  Future<List<JsonRow>> selectOwnMetadata();

  /// Remove [objectKeys] from the private bucket through the Storage
  /// API.
  ///
  /// This is the ONLY path that deletes the stored bytes: a SQL
  /// `DELETE FROM storage.objects` removes the row and orphans the
  /// object — and on Supabase it does not even get that far, because a
  /// statement-level `BEFORE DELETE` trigger refuses direct SQL
  /// deletes outright.
  Future<void> removeObjects(List<String> objectKeys);

  /// `fleet_log_document_access(p_document)` — the audit row for a
  /// privileged read. False when the server declined to record it.
  Future<bool> logAccess(String documentId);
}

/// The production [FleetDocumentTransport] over the live
/// [TankSyncClient].
class SupabaseFleetDocumentTransport implements FleetDocumentTransport {
  SupabaseFleetDocumentTransport._(this._client, this.userId);

  final SupabaseClient _client;

  @override
  final String userId;

  /// The transport for the current session, or `null` when the client
  /// is not initialised / nobody is signed in.
  static FleetDocumentTransport? currentOrNull() {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;
    return SupabaseFleetDocumentTransport._(client, userId);
  }

  @override
  Future<void> putObject({
    required String objectKey,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _fence();
    await _client.storage.from(FleetDocumentStore.bucket).uploadBinary(
          objectKey,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
  }

  @override
  Future<String> signedUrl({
    required String objectKey,
    required Duration ttl,
  }) {
    _fence();
    return _client.storage
        .from(FleetDocumentStore.bucket)
        .createSignedUrl(objectKey, ttl.inSeconds);
  }

  @override
  Future<void> upsertMetadata(JsonRow row) async {
    _fence();
    await _client
        .from(FleetDocumentStore.table)
        .upsert(row, onConflict: 'id');
  }

  @override
  Future<List<JsonRow>> selectOwnMetadata() async {
    _fence();
    final rows = await _client
        .from(FleetDocumentStore.table)
        .select('id, org_id, object_key, sha256, retention_class, '
            'deleted_at, data, updated_at')
        .eq('user_id', userId);
    return List<JsonRow>.from(rows);
  }

  @override
  Future<void> removeObjects(List<String> objectKeys) async {
    if (objectKeys.isEmpty) return;
    _fence();
    await _client.storage.from(FleetDocumentStore.bucket).remove(objectKeys);
  }

  @override
  Future<bool> logAccess(String documentId) async {
    _fence();
    final result = await _client.rpc<dynamic>(
      'fleet_log_document_access',
      params: {'p_document': documentId},
    );
    return result == true;
  }

  /// #4337 — refuse to touch a client that is no longer the live one.
  void _fence() {
    if (!identical(TankSyncClient.client, _client)) {
      throw const SyncFencedException();
    }
  }
}

/// Where a receipt's BYTES live, and the only way back to them
/// (#4215, ADR 0025 "what never leaves the device").
///
/// Three rules this class exists to keep:
///
///  * **The bucket is private and the URL is temporary.** There is no
///    code path to a public URL, and a signed URL is returned to the
///    caller for immediate display — never written to a box, a log, a
///    trace or an export. [signedUrlTtl] is minutes, not days.
///  * **A read is audited before it happens.** [readUrl] calls
///    `fleet_log_document_access` FIRST and refuses to issue a URL when
///    the server declines to record the access (ADR 0025 D5.4). An
///    unaudited privileged read is therefore not a state the app can
///    reach — it is not "logged afterwards if all goes well".
///  * **Nothing here can hold an image.** [DocumentMeta] carries no
///    bytes, and the bytes parameter never enters a log line. A
///    failure logs the operation and the document id, never content.
///
/// Every method degrades rather than throws: a wire fault returns
/// `null` / `false` / an empty list after logging to
/// [ErrorLayer.sync], and the caller decides what to show.
class FleetDocumentStore {
  const FleetDocumentStore({
    this.transport,
    this.clock = const SystemClock(),
    this.signedUrlTtl = const Duration(minutes: 5),
  });

  /// The private Storage bucket, in one place.
  static const String bucket = 'fleet-documents';

  /// The metadata table, in one place.
  static const String table = 'fleet_documents';

  /// The wire. `null` resolves
  /// [SupabaseFleetDocumentTransport.currentOrNull] at call time.
  final FleetDocumentTransport? transport;

  /// The injected clock the `deleted_at` stamp is taken from (#3660).
  final AppClock clock;

  /// How long an issued signed URL stays valid. Short on purpose: the
  /// URL is a bearer token for a document that can name a person, a
  /// place, a time and a masked card.
  final Duration signedUrlTtl;

  /// The object key for one document: `<org>/<owner>/<document id>`.
  ///
  /// The shape is not decoration: `fleet_documents_own`'s `WITH CHECK`
  /// requires exactly this string, so a row whose key names anybody
  /// else's path is refused by the server. That is what stops a client
  /// from pointing a metadata row at a VICTIM's object and having the
  /// Storage policy hand over their receipt — the read policies also
  /// re-check the uploader and the role, but the write side is where
  /// the forgery is prevented rather than detected.
  static String objectKeyFor({
    required String orgId,
    required String ownerId,
    required String documentId,
  }) =>
      '$orgId/$ownerId/$documentId';

  /// Store [bytes] for [meta] and record its metadata row.
  ///
  /// Returns the stored [DocumentMeta] — with [DocumentMeta.objectKey]
  /// set to the canonical key — or `null` when either half failed. The
  /// object goes up FIRST: a metadata row pointing at bytes that are
  /// not there would make the app promise a receipt it cannot show,
  /// whereas an orphan object is invisible and swept by the retention
  /// job.
  Future<DocumentMeta?> upload(
    DocumentMeta meta,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    final wire = transport ?? SupabaseFleetDocumentTransport.currentOrNull();
    if (wire == null) return null;
    // The owner is the SIGNED-IN caller, not whatever the caller put on
    // the metadata: the server's WITH CHECK requires
    // `<org>/<auth.uid()>/<id>`, so deriving the key from the session is
    // the only way to build a row the server will accept — and it means
    // this method cannot be talked into naming somebody else's path.
    final stored = meta.copyWith(
      ownerId: wire.userId,
      objectKey: objectKeyFor(
        orgId: meta.orgId,
        ownerId: wire.userId,
        documentId: meta.id,
      ),
    );
    try {
      await wire.putObject(
        objectKey: stored.objectKey,
        bytes: bytes,
        contentType: contentType,
      );
      await wire.upsertMetadata(metadataRow(stored, userId: wire.userId));
      return stored;
    } catch (e, st) {
      _fault('upload', stored.id, e, st);
      return null;
    }
  }

  /// A short-lived signed URL for [meta], AFTER the access has been
  /// audited. `null` when the audit was declined (the caller is not a
  /// member, the document is unknown) or the wire failed — in both
  /// cases the bytes stay unreachable.
  ///
  /// The returned string is for immediate display. Persisting it would
  /// turn a five-minute grant into a permanent one.
  Future<String?> readUrl(DocumentMeta meta) async {
    final wire = transport ?? SupabaseFleetDocumentTransport.currentOrNull();
    if (wire == null) return null;
    if (!meta.isReadable) return null;
    try {
      final audited = await wire.logAccess(meta.id);
      if (!audited) {
        log.warn('FleetDocumentStore.readUrl: access not audited, refusing',
            tag: 'sync',
            layer: ErrorLayer.sync,
            context: {'id': meta.id});
        return null;
      }
      return await wire.signedUrl(
        objectKey: meta.objectKey,
        ttl: signedUrlTtl,
      );
    } catch (e, st) {
      _fault('readUrl', meta.id, e, st);
      return null;
    }
  }

  /// The caller's own document metadata, newest capture first. An
  /// undecodable row is skipped and logged — one bad blob does not
  /// hide the rest of somebody's receipts.
  Future<List<DocumentMeta>> loadOwn() async {
    final wire = transport ?? SupabaseFleetDocumentTransport.currentOrNull();
    if (wire == null) return const [];
    final List<JsonRow> rows;
    try {
      rows = await wire.selectOwnMetadata();
    } catch (e, st) {
      _fault('loadOwn', null, e, st);
      return const [];
    }
    final out = <DocumentMeta>[];
    for (final row in rows) {
      final data = row['data'];
      if (data is! Map<String, dynamic>) continue;
      try {
        out.add(DocumentMeta.fromJson(data));
      } catch (e, st) {
        _fault('decode', '${row['id']}', e, st);
      }
    }
    out.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return out;
  }

  /// Delete every receipt object this user owns, through the Storage
  /// API, and return how many keys were handed over (#4215, GDPR
  /// Art. 17).
  ///
  /// The Storage API is the ONLY path that removes the bytes: on
  /// Supabase a statement-level `BEFORE DELETE` trigger refuses a
  /// direct SQL delete on `storage.objects` — it fired even for a
  /// zero-row statement and aborted the entire erasure until
  /// `erase_my_data()` learned to guard it — and even where such a
  /// delete succeeds it only drops the row and orphans the object.
  ///
  /// The account-deletion path does the equivalent from
  /// `UserDataSync.deleteAll`, which cannot call this without
  /// `lib/core/` importing `lib/features/` (epic #3129 pins that at
  /// zero). This is the feature-side entry point — for a retention
  /// sweep, an admin erase, or any fleet caller that already has the
  /// store — and the seam-testable reference for the same rule; the
  /// shared bucket constant is pinned across the two by test.
  ///
  /// Never throws: a failure is logged and reported as `0`, because a
  /// wire fault here must not stop the row erasure that follows. The
  /// caller surfaces the shortfall rather than claiming a clean wipe.
  Future<int> eraseOwnObjects() async {
    final wire = transport ?? SupabaseFleetDocumentTransport.currentOrNull();
    if (wire == null) return 0;
    try {
      final rows = await wire.selectOwnMetadata();
      final keys = <String>[
        for (final row in rows)
          if (row['object_key'] is String) row['object_key'] as String,
      ];
      if (keys.isEmpty) return 0;
      await wire.removeObjects(keys);
      return keys.length;
    } catch (e, st) {
      _fault('eraseOwnObjects', null, e, st);
      return 0;
    }
  }

  /// The `fleet_documents` row for [meta].
  ///
  /// The whole [DocumentMeta] rides in the JSONB blob; the explicit
  /// columns are the ones the SERVER acts on — tenancy, the key the
  /// Storage policy joins, the duplicate hash, the retention rule a
  /// sweep reads and the `deleted_at` a sweep sets. `deleted_at` is
  /// stamped only once the bytes are actually gone: a document
  /// AWAITING deletion is still present, and flattening the two would
  /// make a pending erasure look honoured.
  JsonRow metadataRow(DocumentMeta meta, {required String userId}) => {
        'id': meta.id,
        'user_id': userId,
        'org_id': meta.orgId,
        'object_key': meta.objectKey,
        'sha256': meta.sha256,
        'retention_class': documentRetentionColumn(meta.retentionClass),
        'deleted_at':
            meta.deletionStatus == DocumentDeletionStatus.deleted
                ? clock.now().toUtc().toIso8601String()
                : null,
        'data': meta.toJson(),
        'updated_at': clock.now().toUtc().toIso8601String(),
      };

  void _fault(String op, String? id, Object e, StackTrace st) =>
      log.error(e, st, layer: ErrorLayer.sync, context: {
        'where': 'FleetDocumentStore.$op failed',
        'id': id ?? '',
      });
}
