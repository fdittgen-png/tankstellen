// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/permissions/permission_rationale_dialog.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/fake_settings_storage.dart';

/// #3872 (epic #3865, GDPR) — pre-permission rationale for camera,
/// Bluetooth and notifications.
///
/// * Renders the per-kind copy: title, bold lead, "what happens" heading,
///   the transparency bullets, the revoke hint and the Art. 6(1)(a)
///   footnote.
/// * ONE `Continue` action and nothing else (App Review 5.1.1(iv), #3535):
///   no decline / skip / cancel, barrier not dismissible.
/// * Shown at most once per kind: the acknowledgement is persisted under
///   `permission_rationale_shown_<kind>`; a second `show` returns
///   immediately without rendering a dialog.
void main() {
  group('PermissionRationaleDialog — persistence', () {
    test('storage keys are the StorageKeys constants, one per kind', () {
      expect(
        PermissionRationaleDialog.storageKeyFor(PermissionRationaleKind.camera),
        StorageKeys.permissionRationaleShownCamera,
      );
      expect(
        PermissionRationaleDialog.storageKeyFor(
          PermissionRationaleKind.bluetooth,
        ),
        StorageKeys.permissionRationaleShownBluetooth,
      );
      expect(
        PermissionRationaleDialog.storageKeyFor(
          PermissionRationaleKind.notifications,
        ),
        StorageKeys.permissionRationaleShownNotifications,
      );
      expect(StorageKeys.permissionRationaleShownCamera,
          'permission_rationale_shown_camera');
    });

    test('hasBeenShown is false on a fresh storage, true after markShown',
        () async {
      final storage = FakeSettingsStorage();
      for (final kind in PermissionRationaleKind.values) {
        expect(PermissionRationaleDialog.hasBeenShown(storage, kind), isFalse);
      }
      await PermissionRationaleDialog.markShown(
        storage,
        PermissionRationaleKind.bluetooth,
      );
      expect(
        PermissionRationaleDialog.hasBeenShown(
          storage,
          PermissionRationaleKind.bluetooth,
        ),
        isTrue,
      );
      // Kinds are independent — acknowledging one never covers another.
      expect(
        PermissionRationaleDialog.hasBeenShown(
          storage,
          PermissionRationaleKind.camera,
        ),
        isFalse,
      );
      expect(storage.data, {'permission_rationale_shown_bluetooth': true});
    });

    test('hasBeenShown requires strict boolean true', () {
      final storage = FakeSettingsStorage()
        ..data['permission_rationale_shown_camera'] = 1;
      expect(
        PermissionRationaleDialog.hasBeenShown(
          storage,
          PermissionRationaleKind.camera,
        ),
        isFalse,
      );
    });
  });

  group('PermissionRationaleDialog — dialog UX', () {
    testWidgets('camera: renders the copy, one Continue, no decline',
        (tester) async {
      final storage = FakeSettingsStorage();
      final done = await _pumpAndShow(
        tester,
        PermissionRationaleKind.camera,
        storage,
      );

      expect(find.byKey(PermissionRationaleDialog.dialogKey), findsOneWidget);
      expect(find.text('Camera Access'), findsOneWidget);
      expect(
        find.text('This app would like to use your camera to read receipts, '
            'pump displays and QR codes.'),
        findsOneWidget,
      );
      expect(find.text('What happens with the camera image:'), findsOneWidget);
      expect(find.textContaining('recognition runs on your device'),
          findsOneWidget);
      expect(find.text('The photo is discarded after the scan.'),
          findsOneWidget);
      expect(find.textContaining('bad-scan report'), findsOneWidget);
      expect(
        find.text('You can revoke this in your device settings at any time.'),
        findsOneWidget,
      );
      expect(find.text('Legal basis: Art. 6(1)(a) GDPR (Consent)'),
          findsOneWidget);
      _expectContinueOnly(tester);

      await tester.tap(find.byKey(PermissionRationaleDialog.continueKey));
      await tester.pumpAndSettle();
      expect(await done, isTrue);
      expect(find.byKey(PermissionRationaleDialog.dialogKey), findsNothing);
      expect(
        PermissionRationaleDialog.hasBeenShown(
          storage,
          PermissionRationaleKind.camera,
        ),
        isTrue,
      );
    });

    testWidgets('bluetooth: renders the copy incl. the Android ≤ 11 note',
        (tester) async {
      await _pumpAndShow(
        tester,
        PermissionRationaleKind.bluetooth,
        FakeSettingsStorage(),
      );
      expect(find.text('Bluetooth Access'), findsOneWidget);
      expect(find.textContaining('connect to your OBD2 adapter'),
          findsOneWidget);
      expect(find.text('What happens with Bluetooth:'), findsOneWidget);
      expect(find.textContaining('find and talk to your OBD2 adapter'),
          findsOneWidget);
      expect(find.textContaining('synced only with TankSync'), findsOneWidget);
      expect(find.textContaining('Android 11 and below'), findsOneWidget);
      expect(find.text('Legal basis: Art. 6(1)(a) GDPR (Consent)'),
          findsOneWidget);
      _expectContinueOnly(tester);
    });

    testWidgets('notifications: renders the copy', (tester) async {
      await _pumpAndShow(
        tester,
        PermissionRationaleKind.notifications,
        FakeSettingsStorage(),
      );
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('price alerts and the trip-recording status'),
          findsWidgets);
      expect(find.text('What happens with notifications:'), findsOneWidget);
      expect(find.textContaining('nothing leaves the device'), findsOneWidget);
      expect(find.text('Legal basis: Art. 6(1)(a) GDPR (Consent)'),
          findsOneWidget);
      _expectContinueOnly(tester);
    });

    testWidgets('barrier tap does not dismiss — Continue is the only exit',
        (tester) async {
      await _pumpAndShow(
        tester,
        PermissionRationaleKind.camera,
        FakeSettingsStorage(),
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(PermissionRationaleDialog.dialogKey), findsOneWidget);
    });

    testWidgets('shown once — the second show returns without a dialog',
        (tester) async {
      final storage = FakeSettingsStorage();
      await _pumpAndShow(tester, PermissionRationaleKind.camera, storage);
      await tester.tap(find.byKey(PermissionRationaleDialog.continueKey));
      await tester.pumpAndSettle();

      final second = await _pumpAndShow(
        tester,
        PermissionRationaleKind.camera,
        storage,
      );
      expect(find.byKey(PermissionRationaleDialog.dialogKey), findsNothing);
      expect(await second, isTrue);
    });

    testWidgets('a pre-acknowledged storage skips the dialog entirely',
        (tester) async {
      final done = await _pumpAndShow(
        tester,
        PermissionRationaleKind.notifications,
        FakeSettingsStorage.rationalesShown(),
      );
      expect(find.byKey(PermissionRationaleDialog.dialogKey), findsNothing);
      expect(await done, isTrue);
    });

    testWidgets('German copy renders through AppLocalizations',
        (tester) async {
      await _pumpAndShow(
        tester,
        PermissionRationaleKind.bluetooth,
        FakeSettingsStorage(),
        locale: const Locale('de'),
      );
      expect(find.text('Bluetooth-Zugriff'), findsOneWidget);
      expect(
        find.text('Rechtsgrundlage: Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)'),
        findsOneWidget,
      );
      expect(find.text('Weiter'), findsOneWidget);
    });
  });
}

/// Only ONE action, and it is the Continue button — no TextButton /
/// OutlinedButton decline affordance anywhere in the dialog.
void _expectContinueOnly(WidgetTester tester) {
  final dialog = find.byKey(PermissionRationaleDialog.dialogKey);
  expect(
    find.descendant(of: dialog, matching: find.byType(FilledButton)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: dialog, matching: find.byType(TextButton)),
    findsNothing,
  );
  expect(
    find.descendant(of: dialog, matching: find.byType(OutlinedButton)),
    findsNothing,
  );
  expect(find.byKey(PermissionRationaleDialog.continueKey), findsOneWidget);
  expect(find.text('Continue'), findsOneWidget);
  expect(find.text('Cancel'), findsNothing);
}

/// Pumps a host page and invokes `show` for [kind]; the returned future
/// completes with `true` once `show` returns.
Future<Future<bool>> _pumpAndShow(
  WidgetTester tester,
  PermissionRationaleKind kind,
  FakeSettingsStorage storage, {
  Locale locale = const Locale('en'),
}) async {
  late Future<bool> done;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              done = PermissionRationaleDialog.show(
                context,
                kind: kind,
                storage: storage,
              ).then((_) => true);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return done;
}
