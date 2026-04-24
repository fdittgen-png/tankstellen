import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/providers/sync_wizard_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('SyncWizardState', () {
    test('default constructor has expected initial values', () {
      const s = SyncWizardState();
      expect(s.mode, SyncWizardMode.choose);
      expect(s.createStep, 0);
      expect(s.testing, isFalse);
      expect(s.connecting, isFalse);
      expect(s.isSignUp, isTrue);
      expect(s.useEmail, isFalse);
      expect(s.testResult, isNull);
      expect(s.testSuccess, isFalse);
      expect(s.schemaStatus, isNull);
      expect(s.migrationSql, isNull);
      expect(s.showKey, isFalse);
    });

    test('copyWith updates each field independently', () {
      const base = SyncWizardState();
      final updated = base.copyWith(
        mode: SyncWizardMode.createNew,
        createStep: 3,
        testing: true,
        connecting: true,
        isSignUp: false,
        useEmail: true,
        testResult: 'ok',
        testSuccess: true,
        schemaStatus: const {'favorites': true},
        migrationSql: 'CREATE TABLE ...',
        showKey: true,
      );
      expect(updated.mode, SyncWizardMode.createNew);
      expect(updated.createStep, 3);
      expect(updated.testing, isTrue);
      expect(updated.connecting, isTrue);
      expect(updated.isSignUp, isFalse);
      expect(updated.useEmail, isTrue);
      expect(updated.testResult, 'ok');
      expect(updated.testSuccess, isTrue);
      expect(updated.schemaStatus, {'favorites': true});
      expect(updated.migrationSql, 'CREATE TABLE ...');
      expect(updated.showKey, isTrue);
    });

    test('copyWith without args preserves all fields', () {
      const base = SyncWizardState(
        mode: SyncWizardMode.auth,
        createStep: 2,
        testing: true,
        isSignUp: false,
        useEmail: true,
        testResult: 'prev',
        testSuccess: true,
        schemaStatus: {'a': true},
        migrationSql: 'sql',
        showKey: true,
      );
      final copy = base.copyWith();
      expect(copy.mode, base.mode);
      expect(copy.createStep, base.createStep);
      expect(copy.testing, base.testing);
      expect(copy.isSignUp, base.isSignUp);
      expect(copy.useEmail, base.useEmail);
      expect(copy.testResult, base.testResult);
      expect(copy.testSuccess, base.testSuccess);
      expect(copy.schemaStatus, base.schemaStatus);
      expect(copy.migrationSql, base.migrationSql);
      expect(copy.showKey, base.showKey);
    });

    test('clearTestResult nulls testResult even with override provided', () {
      const base = SyncWizardState(testResult: 'old');
      final cleared =
          base.copyWith(testResult: 'ignored', clearTestResult: true);
      expect(cleared.testResult, isNull);
    });

    test('clearSchemaStatus nulls schemaStatus', () {
      const base = SyncWizardState(schemaStatus: {'x': true});
      final cleared = base.copyWith(clearSchemaStatus: true);
      expect(cleared.schemaStatus, isNull);
    });

    test('clearMigrationSql nulls migrationSql', () {
      const base = SyncWizardState(migrationSql: 'CREATE ...');
      final cleared = base.copyWith(clearMigrationSql: true);
      expect(cleared.migrationSql, isNull);
    });
  });

  group('SyncWizardController.build', () {
    test('returns default SyncWizardState', () {
      final s = makeContainer().read(syncWizardControllerProvider);
      expect(s.mode, SyncWizardMode.choose);
      expect(s.createStep, 0);
      expect(s.testing, isFalse);
      expect(s.connecting, isFalse);
      expect(s.isSignUp, isTrue);
      expect(s.useEmail, isFalse);
      expect(s.testResult, isNull);
      expect(s.testSuccess, isFalse);
      expect(s.schemaStatus, isNull);
      expect(s.migrationSql, isNull);
      expect(s.showKey, isFalse);
    });
  });

  group('SyncWizardController mutators', () {
    test('setMode updates mode', () {
      final c = makeContainer();
      c
          .read(syncWizardControllerProvider.notifier)
          .setMode(SyncWizardMode.createNew);
      expect(
        c.read(syncWizardControllerProvider).mode,
        SyncWizardMode.createNew,
      );
    });

    test('setCreateStep sets the specific step', () {
      final c = makeContainer();
      c.read(syncWizardControllerProvider.notifier).setCreateStep(4);
      expect(c.read(syncWizardControllerProvider).createStep, 4);
    });

    test('incrementStep moves createStep by +1', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.setCreateStep(2);
      n.incrementStep();
      expect(c.read(syncWizardControllerProvider).createStep, 3);
    });

    test('decrementStep moves createStep by -1', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.setCreateStep(2);
      n.decrementStep();
      expect(c.read(syncWizardControllerProvider).createStep, 1);
    });

    test('decrementStep from 0 goes to -1 (no floor guard)', () {
      final c = makeContainer();
      c.read(syncWizardControllerProvider.notifier).decrementStep();
      expect(c.read(syncWizardControllerProvider).createStep, -1);
    });

    test('toggleKeyVisibility flips showKey both ways', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      expect(c.read(syncWizardControllerProvider).showKey, isFalse);
      n.toggleKeyVisibility();
      expect(c.read(syncWizardControllerProvider).showKey, isTrue);
      n.toggleKeyVisibility();
      expect(c.read(syncWizardControllerProvider).showKey, isFalse);
    });

    test('setUseEmail updates useEmail', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.setUseEmail(true);
      expect(c.read(syncWizardControllerProvider).useEmail, isTrue);
      n.setUseEmail(false);
      expect(c.read(syncWizardControllerProvider).useEmail, isFalse);
    });

    test('toggleSignUp flips isSignUp both ways', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      expect(c.read(syncWizardControllerProvider).isSignUp, isTrue);
      n.toggleSignUp();
      expect(c.read(syncWizardControllerProvider).isSignUp, isFalse);
      n.toggleSignUp();
      expect(c.read(syncWizardControllerProvider).isSignUp, isTrue);
    });

    test('startTesting sets testing=true and clears prior testResult', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.testFailed('previous error');
      expect(c.read(syncWizardControllerProvider).testResult, 'previous error');

      n.startTesting();
      final s = c.read(syncWizardControllerProvider);
      expect(s.testing, isTrue);
      expect(s.testResult, isNull);
    });

    test('testSucceeded records message + testSuccess=true + testing=false',
        () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.startTesting();
      n.testSucceeded('connected');
      final s = c.read(syncWizardControllerProvider);
      expect(s.testing, isFalse);
      expect(s.testResult, 'connected');
      expect(s.testSuccess, isTrue);
    });

    test('testFailed records message + testSuccess=false + testing=false', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.startTesting();
      n.testFailed('bad credentials');
      final s = c.read(syncWizardControllerProvider);
      expect(s.testing, isFalse);
      expect(s.testResult, 'bad credentials');
      expect(s.testSuccess, isFalse);
    });

    test('setConnecting updates connecting', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.setConnecting(true);
      expect(c.read(syncWizardControllerProvider).connecting, isTrue);
      n.setConnecting(false);
      expect(c.read(syncWizardControllerProvider).connecting, isFalse);
    });

    test('connectFailed sets testResult + testSuccess=false', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.connectFailed('network down');
      final s = c.read(syncWizardControllerProvider);
      expect(s.testResult, 'network down');
      expect(s.testSuccess, isFalse);
    });

    test(
        'showSchemaStep sets mode=schema + populates schemaStatus + migrationSql',
        () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      const schema = {'favorites': true, 'prices': false};
      const sql = 'CREATE TABLE prices (...);';
      n.showSchemaStep(schema: schema, migrationSql: sql);
      final s = c.read(syncWizardControllerProvider);
      expect(s.mode, SyncWizardMode.schema);
      expect(s.schemaStatus, schema);
      expect(s.migrationSql, sql);
    });

    test('updateSchemaStatus with non-null sets schemaStatus', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.updateSchemaStatus({'favorites': true});
      expect(
        c.read(syncWizardControllerProvider).schemaStatus,
        {'favorites': true},
      );
    });

    test('updateSchemaStatus with null clears schemaStatus', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.updateSchemaStatus({'favorites': true});
      expect(
        c.read(syncWizardControllerProvider).schemaStatus,
        isNotNull,
      );
      n.updateSchemaStatus(null);
      expect(c.read(syncWizardControllerProvider).schemaStatus, isNull);
    });

    test('touch preserves all field values (rebuild signal)', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.setMode(SyncWizardMode.createNew);
      n.setCreateStep(2);
      n.setUseEmail(true);
      n.toggleKeyVisibility();
      final before = c.read(syncWizardControllerProvider);

      n.touch();
      final after = c.read(syncWizardControllerProvider);
      expect(after.mode, before.mode);
      expect(after.createStep, before.createStep);
      expect(after.useEmail, before.useEmail);
      expect(after.showKey, before.showKey);
    });

    test('reset returns state to default', () {
      final c = makeContainer();
      final n = c.read(syncWizardControllerProvider.notifier);
      n.setMode(SyncWizardMode.schema);
      n.setCreateStep(5);
      n.setConnecting(true);
      n.testSucceeded('ok');
      n.toggleKeyVisibility();

      n.reset();
      final s = c.read(syncWizardControllerProvider);
      expect(s.mode, SyncWizardMode.choose);
      expect(s.createStep, 0);
      expect(s.testing, isFalse);
      expect(s.connecting, isFalse);
      expect(s.isSignUp, isTrue);
      expect(s.useEmail, isFalse);
      expect(s.testResult, isNull);
      expect(s.testSuccess, isFalse);
      expect(s.schemaStatus, isNull);
      expect(s.migrationSql, isNull);
      expect(s.showKey, isFalse);
    });
  });
}
