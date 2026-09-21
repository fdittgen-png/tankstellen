// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/pending_deletions_journal.dart';
import 'package:tankstellen/core/sync/sync_device_identity.dart';
import 'package:tankstellen/features/fleet/data/fleet_expenses_sync.dart';
import 'package:tankstellen/features/fleet/domain/expense.dart';
import 'package:tankstellen/features/fleet/domain/expense_fields.dart';
import 'package:tankstellen/features/fleet/domain/money.dart';

import '../../../core/sync/fake_sync_transport.dart';
import '../../../helpers/silence_error_logger.dart';

/// #4215 (F7) — the `fleet_expenses` sync config over a fake
/// transport.
///
/// The claim this file exists to prove is that an expense is an
/// ORDINARY user-owned entity: it needs no new merge engine, and the
/// row it produces carries the four explicit columns the SERVER acts
/// on (tenancy, the policy's `status` predicate, and the two join
/// keys) alongside the blob. A round trip through the fake must come
/// back equal, or a manager's policy is filtering on a column the
/// client never filled.
void main() {
  silenceErrorLoggerSpool();

  setUp(() {
    SyncDeviceIdentity.resetForTest('device-under-test');
    PendingDeletionsJournal.load = () => null;
    PendingDeletionsJournal.persist = (_) async {};
  });

  tearDown(() {
    SyncDeviceIdentity.resetForTest();
    PendingDeletionsJournal.resetForTest();
  });

  const fields = ExtractedReceiptFields(
    stationName: 'Aral Köln',
    litres: 50,
    pricePerLitre: 1.7,
    total: Money(amount: 85, currency: 'EUR'),
  );

  final captured = DateTime.utc(2026, 3, 11, 14, 30);

  Expense expense({
    String id = 'e1',
    ExpenseStatus status = ExpenseStatus.draft,
    String? fillUpId,
    String? vehicleId = 'veh-9',
  }) =>
      Expense(
        id: id,
        orgId: 'org-1',
        userId: 'user-1',
        fillUpId: fillUpId,
        fleetAttribution: vehicleId == null
            ? null
            : FleetAttribution(
                orgId: 'org-1',
                fleetVehicleId: vehicleId,
                capturedAt: captured,
              ),
        extracted: fields,
        confirmed: fields,
        importSource: ExpenseImportSource.ocrPhoto,
        status: status,
      );

  group('the upload row', () {
    test('carries the four server columns beside the blob', () async {
      final fake = FakeSyncTransport();
      await FleetExpensesSync.merge(
        [expense(status: ExpenseStatus.submitted, fillUpId: 'f-3')],
        transport: fake,
      );
      final row = fake.upsertedRows(FleetExpensesSync.table).single;
      expect(row['id'], 'e1');
      expect(row['user_id'], 'user-1');
      expect(row['org_id'], 'org-1');
      expect(row['fleet_vehicle_id'], 'veh-9');
      expect(row['fill_up_id'], 'f-3');
      expect(row['status'], 'submitted');
      expect(fake.upsertCalls.single.onConflict, 'user_id,id');
    });

    test('the status COLUMN is snake_case, not the enum spelling — it '
        'is what the RLS predicate reads', () async {
      final fake = FakeSyncTransport();
      await FleetExpensesSync.merge(
        [expense(status: ExpenseStatus.needsReview)],
        transport: fake,
      );
      expect(fake.upsertedRows(FleetExpensesSync.table).single['status'],
          'needs_review');
      // …and every state has a column value, with no gaps.
      for (final status in ExpenseStatus.values) {
        final column = expenseStatusColumn(status);
        expect(column, isNotEmpty);
        expect(expenseStatusFromColumn(column), status, reason: column);
      }
      expect(expenseStatusFromColumn('a_status_from_the_future'), isNull,
          reason: 'an older client must not throw on a newer vocabulary');
    });

    test('carries no document bytes — the blob is the Expense, which '
        'cannot hold an image', () async {
      final fake = FakeSyncTransport();
      await FleetExpensesSync.merge([expense()], transport: fake);
      final blob = fake.upsertedRows(FleetExpensesSync.table).single['data']
          as Map<String, dynamic>;
      expect(blob.keys, isNot(contains('bytes')));
      expect(blob.keys, isNot(contains('image')));
      // The link to the document is an id and nothing else.
      expect(blob['documentId'], isNull);
    });
  });

  group('the round trip', () {
    test('a server-only expense comes back decoded and equal', () async {
      final remote = expense(id: 'e-remote', status: ExpenseStatus.approved);
      final fake = FakeSyncTransport(tables: {
        FleetExpensesSync.table: [
          {
            'id': 'e-remote',
            'user_id': 'user-1',
            'org_id': 'org-1',
            'status': 'approved',
            'data': remote.toJson(),
            'updated_at': captured.toIso8601String(),
          },
        ],
      });

      final merged = await FleetExpensesSync.merge(const [], transport: fake);

      expect(merged, hasLength(1));
      expect(merged.single, remote);
    });

    test('upload then download reproduces the record exactly', () async {
      final fake = FakeSyncTransport();
      final local = expense(id: 'e-round', fillUpId: 'f-1');

      await FleetExpensesSync.merge([local], transport: fake);
      // A second device: nothing local, everything on the server.
      final pulled = await FleetExpensesSync.merge(const [], transport: fake);

      expect(pulled, hasLength(1));
      expect(pulled.single, local,
          reason: 'the forensic stamps ride inside the blob and decode '
              'ignores unknown keys, so the record must survive intact');
    });

    test('a corrupt blob is skipped, not fatal — one bad row does not '
        'hide the rest of somebody\'s expenses', () async {
      final good = expense(id: 'e-good');
      final fake = FakeSyncTransport(tables: {
        FleetExpensesSync.table: [
          {'id': 'e-bad', 'user_id': 'user-1', 'data': 'not-an-object'},
          {
            'id': 'e-good',
            'user_id': 'user-1',
            'data': good.toJson(),
            'updated_at': captured.toIso8601String(),
          },
        ],
      });

      final merged = await FleetExpensesSync.merge(const [], transport: fake);

      expect(merged.map((e) => e.id), ['e-good']);
    });

    test('the unauthenticated path returns the input unchanged', () async {
      final local = [expense()];
      expect(await FleetExpensesSync.merge(local), local);
    });
  });

  group('the last-write-wins stamp', () {
    test('is null for an expense with no history, no corrections and no '
        'attribution — "no opinion", not "epoch"', () {
      expect(expenseChangedAt(expense(vehicleId: null)), isNull);
    });

    test('is the attribution capture time when that is all there is', () {
      expect(expenseChangedAt(expense()), captured);
    });

    test('is the LATEST of history, corrections and attribution', () {
      final later = DateTime.utc(2026, 3, 12, 9);
      final withHistory = expense().copyWith(
        history: [
          ExpenseTransition(
            from: ExpenseStatus.draft,
            to: ExpenseStatus.needsReview,
            at: later,
            byUserId: 'user-1',
          ),
        ],
        corrections: [
          FieldCorrection(
            field: 'litres',
            before: '4218',
            after: '42.18',
            correctedAt: captured,
            correctedBy: 'user-1',
          ),
        ],
      );
      expect(expenseChangedAt(withHistory), later);
    });

    test('a local edit re-uploads over an older server row (#3122)',
        () async {
      final later = DateTime.utc(2026, 3, 12, 9);
      final local = expense().copyWith(
        history: [
          ExpenseTransition(
            from: ExpenseStatus.draft,
            to: ExpenseStatus.needsReview,
            at: later,
            byUserId: 'user-1',
          ),
        ],
        status: ExpenseStatus.needsReview,
      );
      final fake = FakeSyncTransport(tables: {
        FleetExpensesSync.table: [
          {
            'id': 'e1',
            'user_id': 'user-1',
            'org_id': 'org-1',
            'status': 'draft',
            'data': expense().toJson(),
            'updated_at': captured.toIso8601String(),
          },
        ],
      });

      final merged = await FleetExpensesSync.merge([local], transport: fake);

      expect(fake.upsertedRows(FleetExpensesSync.table).single['status'],
          'needs_review');
      expect(merged.single.status, ExpenseStatus.needsReview);
    });
  });

  test('delete is a no-op when unauthenticated', () async {
    await FleetExpensesSync.delete('e1');
  });
}
