// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_transport.dart' show JsonRow;
import 'package:tankstellen/core/sync/user_data_sync.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/data/fleet_document_store.dart';
import 'package:tankstellen/features/fleet/domain/document_meta.dart';

import '../../../helpers/silence_error_logger.dart';

/// An in-memory [FleetDocumentTransport] that records what crossed the
/// seam, in what order (#4215).
class _FakeDocumentTransport implements FleetDocumentTransport {
  _FakeDocumentTransport({this.auditSucceeds = true});

  @override
  String userId = 'employee-1';

  bool auditSucceeds;
  Exception? failure;

  final List<String> calls = [];
  final Map<String, Uint8List> objects = {};
  final List<JsonRow> metadata = [];
  final List<String> audited = [];

  @override
  Future<void> putObject({
    required String objectKey,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (failure != null) throw failure!;
    calls.add('put:$objectKey');
    objects[objectKey] = bytes;
  }

  @override
  Future<String> signedUrl({
    required String objectKey,
    required Duration ttl,
  }) async {
    if (failure != null) throw failure!;
    calls.add('sign:$objectKey:${ttl.inSeconds}');
    return 'https://example.invalid/signed/$objectKey?exp=${ttl.inSeconds}';
  }

  @override
  Future<void> upsertMetadata(JsonRow row) async {
    if (failure != null) throw failure!;
    calls.add('meta:${row['id']}');
    metadata.add(row);
  }

  @override
  Future<List<JsonRow>> selectOwnMetadata() async {
    if (failure != null) throw failure!;
    calls.add('select');
    return metadata;
  }

  @override
  Future<void> removeObjects(List<String> objectKeys) async {
    if (failure != null) throw failure!;
    calls.add('remove:${objectKeys.join(',')}');
    objects.removeWhere((key, _) => objectKeys.contains(key));
  }

  @override
  Future<bool> logAccess(String documentId) async {
    if (failure != null) throw failure!;
    calls.add('audit:$documentId');
    audited.add(documentId);
    return auditSucceeds;
  }
}

/// #4215 (F7) — the private-document store.
///
/// Three promises, each one a test: the bucket is only ever reached
/// through a short-lived signed URL, no privileged read happens
/// without an audit row, and nothing here can carry image bytes into
/// a row, a log or an export.
void main() {
  silenceErrorLoggerSpool();

  final pinned = DateTime.utc(2026, 3, 11, 14, 30);
  final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));

  DocumentMeta meta({
    DocumentDeletionStatus deletion = DocumentDeletionStatus.active,
    DocumentRetentionClass retention =
        DocumentRetentionClass.accountingDocument,
  }) =>
      DocumentMeta(
        id: 'doc-1',
        orgId: 'org-1',
        ownerId: 'employee-1',
        type: FleetDocumentType.receiptPhoto,
        objectKey: '',
        sha256: 'a' * 64,
        capturedAt: pinned,
        retentionClass: retention,
        deletionStatus: deletion,
      );

  FleetDocumentStore store(_FakeDocumentTransport fake) => FleetDocumentStore(
        transport: fake,
        clock: FixedClock(pinned),
      );

  group('upload', () {
    test('derives the canonical object key and writes the bytes before '
        'the row — a row pointing at absent bytes would promise a '
        'receipt the app cannot show', () async {
      final fake = _FakeDocumentTransport();

      final stored = await store(fake).upload(meta(), bytes);

      expect(stored!.objectKey, 'org-1/employee-1/doc-1');
      expect(fake.calls, ['put:org-1/employee-1/doc-1', 'meta:doc-1']);
      expect(fake.objects['org-1/employee-1/doc-1'], bytes);
    });

    test('the metadata row carries the server columns and no bytes',
        () async {
      final fake = _FakeDocumentTransport();

      await store(fake).upload(meta(), bytes);

      final row = fake.metadata.single;
      expect(row['id'], 'doc-1');
      expect(row['user_id'], 'employee-1');
      expect(row['org_id'], 'org-1');
      expect(row['object_key'], 'org-1/employee-1/doc-1');
      expect(row['sha256'], 'a' * 64);
      expect(row['retention_class'], 'accounting_document');
      expect(row['deleted_at'], isNull);
      expect(row.toString(), isNot(contains('Uint8List')));
      final blob = row['data'] as Map<String, dynamic>;
      expect(blob.keys, isNot(contains('bytes')));
    });

    test('deleted_at is stamped only once the bytes are actually gone — '
        'a PENDING deletion is not an honoured one', () async {
      final fake = _FakeDocumentTransport();
      final pendingRow = store(fake).metadataRow(
          meta(deletion: DocumentDeletionStatus.pendingDeletion),
          userId: 'employee-1');
      final goneRow = store(fake).metadataRow(
          meta(deletion: DocumentDeletionStatus.deleted),
          userId: 'employee-1');

      expect(pendingRow['deleted_at'], isNull);
      expect(goneRow['deleted_at'], pinned.toIso8601String());
    });

    test('every retention class has a column spelling', () {
      final fake = _FakeDocumentTransport();
      for (final retention in DocumentRetentionClass.values) {
        expect(documentRetentionColumn(retention), isNotEmpty,
            reason: retention.name);
      }
      expect(
          store(fake).metadataRow(
              meta(retention: DocumentRetentionClass.userManaged),
              userId: 'x')['retention_class'],
          'user_managed');
    });

    test('a wire fault degrades to null rather than throwing', () async {
      final fake = _FakeDocumentTransport()..failure = Exception('offline');
      expect(await store(fake).upload(meta(), bytes), isNull);
    });

    test('with no transport and no session nothing is uploaded', () async {
      expect(
          await const FleetDocumentStore().upload(meta(), bytes), isNull);
    });
  });

  group('readUrl', () {
    test('audits BEFORE it signs — an unaudited privileged read is not '
        'a state the app can reach', () async {
      final fake = _FakeDocumentTransport();
      final stored = await store(fake).upload(meta(), bytes);
      fake.calls.clear();

      final url = await store(fake).readUrl(stored!);

      expect(fake.calls, ['audit:doc-1', 'sign:org-1/employee-1/doc-1:300']);
      expect(url, startsWith('https://'));
    });

    test('refuses to sign when the server declines to record the '
        'access', () async {
      final fake = _FakeDocumentTransport(auditSucceeds: false);
      final stored = await store(fake).upload(meta(), bytes);
      fake.calls.clear();

      expect(await store(fake).readUrl(stored!), isNull);
      expect(fake.calls, ['audit:doc-1'],
          reason: 'the signing must not even be attempted');
    });

    test('the grant is short-lived — minutes, not days', () async {
      final fake = _FakeDocumentTransport();
      final stored = await store(fake).upload(meta(), bytes);
      await store(fake).readUrl(stored!);
      expect(
          const FleetDocumentStore().signedUrlTtl.inMinutes, lessThanOrEqualTo(15));
      expect(fake.calls.last, endsWith(':300'));
    });

    test('a deleted document is not signed at all', () async {
      final fake = _FakeDocumentTransport();
      final gone = meta(deletion: DocumentDeletionStatus.deleted)
          .copyWith(objectKey: 'org-1/employee-1/doc-1');

      expect(await store(fake).readUrl(gone), isNull);
      expect(fake.calls, isEmpty);
    });
  });

  group('loadOwn', () {
    test('decodes the blob and skips a row this build cannot read',
        () async {
      final fake = _FakeDocumentTransport();
      await store(fake).upload(meta(), bytes);
      fake.metadata.add({'id': 'doc-bad', 'data': 'not-an-object'});

      final loaded = await store(fake).loadOwn();

      expect(loaded.map((d) => d.id), ['doc-1']);
    });

    test('a wire fault yields an empty list, never a partial one',
        () async {
      final fake = _FakeDocumentTransport()..failure = Exception('offline');
      expect(await store(fake).loadOwn(), isEmpty);
    });
  });

  group('eraseOwnObjects — the bytes, before the rows that name them', () {
    test('hands every own key to the Storage API and the objects go',
        () async {
      final fake = _FakeDocumentTransport();
      await store(fake).upload(meta(), bytes);
      fake.calls.clear();

      final removed = await store(fake).eraseOwnObjects();

      expect(removed, 1);
      expect(fake.calls, ['select', 'remove:org-1/employee-1/doc-1']);
      expect(fake.objects, isEmpty,
          reason: 'only the Storage API removes the stored bytes; a SQL '
              'delete on storage.objects is refused outright and would '
              'orphan the object even where it is not');
    });

    test('nothing to erase is not a call', () async {
      final fake = _FakeDocumentTransport();
      expect(await store(fake).eraseOwnObjects(), 0);
      expect(fake.calls, ['select']);
    });

    test('a wire fault reports 0 and never throws — the row erasure '
        'that follows must still run', () async {
      final fake = _FakeDocumentTransport();
      await store(fake).upload(meta(), bytes);
      fake.failure = Exception('offline');

      expect(await store(fake).eraseOwnObjects(), 0);
    });

    test('with no session there is nothing to remove', () async {
      expect(await const FleetDocumentStore().eraseOwnObjects(), 0);
    });
  });

  // #2349 — the class DOCUMENTS "every method degrades rather than
  // throws". That sentence is only worth the line if a fault actually
  // gets injected, so here every public method is driven with a
  // transport that throws on every call and each one is required to
  // return normally. A store that let a storage outage escape would
  // take the GDPR erasure down with it.
  group('the never-throws contract, with the wire failing on every call',
      () {
    _FakeDocumentTransport broken() =>
        _FakeDocumentTransport()..failure = Exception('wire down');

    test('upload completes instead of throwing', () async {
      await expectLater(store(broken()).upload(meta(), bytes), completes);
    });

    test('readUrl completes instead of throwing', () async {
      await expectLater(
          store(broken()).readUrl(
              meta().copyWith(objectKey: 'org-1/employee-1/doc-1')),
          completes);
    });

    test('loadOwn completes instead of throwing', () async {
      await expectLater(store(broken()).loadOwn(), completes);
    });

    test('eraseOwnObjects completes instead of throwing', () async {
      await expectLater(store(broken()).eraseOwnObjects(), completes);
    });

    test('metadataRow is pure and returns normally', () {
      expect(() => store(broken()).metadataRow(meta(), userId: 'employee-1'),
          returnsNormally);
    });
  });

  test('the bucket and table names the policies key on are the ones the '
      'client uses', () {
    expect(FleetDocumentStore.bucket, 'fleet-documents');
    expect(FleetDocumentStore.table, 'fleet_documents');
  });

  test('erasure covers the document metadata — a receipt is the '
      'employee\'s to have deleted (ADR 0025 D9)', () {
    expect(UserDataSync.deletableTables[FleetDocumentStore.table], 'user_id');
    expect(UserDataSync.readableTables[FleetDocumentStore.table], 'user_id');
  });
}
