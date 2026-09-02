// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/consent/presentation/widgets/consent_record_footer.dart';
import 'package:tankstellen/features/consent/presentation/widgets/consent_switch_rows.dart';
import 'package:tankstellen/features/consent/presentation/widgets/privacy_control_rows.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/privacy/privacy_choices_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../../fakes/fake_hive_storage.dart';
import '../../../../../../helpers/never_truncates.dart';
import '../../../../../../helpers/pump_app.dart';

/// #3909 (Epic #3907) — "Your choices": one list, consents then privacy
/// controls, same row shape, consent footer; nothing truncates.
void main() {
  late FakeHiveStorage storage;

  setUp(() {
    storage = FakeHiveStorage();
    AppConstants.tileProxyDisabledByUser = false;
  });
  tearDown(() => AppConstants.tileProxyDisabledByUser = false);

  Future<AppLocalizations> pump(WidgetTester tester,
      {Locale locale = const Locale('en')}) async {
    await tester.binding.setSurfaceSize(const Size(600, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(
      tester,
      const PrivacyChoicesScreen(),
      locale: locale,
      overrides: [hiveStorageProvider.overrideWithValue(storage)],
    );
    return AppLocalizations.of(
        tester.element(find.byType(PrivacyChoicesScreen)));
  }

  testWidgets('one list: five consents, then the two controls, then the '
      'consent record footer + policy link', (tester) async {
    final l = await pump(tester);
    expect(find.byType(ConsentSwitchRows), findsOneWidget);
    expect(find.byType(PrivacyControlRows), findsOneWidget);
    expect(find.byType(ConsentRecordFooter), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(5));
    expect(find.byKey(const Key('privacyTileProxySwitch')), findsOneWidget);
    expect(find.byKey(const Key('privacyRemoteLogosSwitch')), findsOneWidget);
    expect(find.text(l.gdprSettingsHint), findsOneWidget);

    // Order: consents above controls above the footer.
    expect(
      tester.getTopLeft(find.byType(ConsentSwitchRows)).dy,
      lessThan(tester.getTopLeft(find.byType(PrivacyControlRows)).dy),
    );
    expect(
      tester.getTopLeft(find.byType(PrivacyControlRows)).dy,
      lessThan(tester.getTopLeft(find.byType(ConsentRecordFooter)).dy),
    );
    expect(find.byKey(const Key('consentRecordFooter')), findsOneWidget);
    expect(find.byKey(const Key('consentPolicyLink')), findsOneWidget);
    expect(find.text(l.consentNotRecorded), findsOneWidget);
    // The former "Show details" toggle and controls header are gone.
    expect(find.byKey(const Key('consentSubtitleExpandToggle')), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('the footer shows the recorded date + policy version once '
      'consent was saved (#3866)', (tester) async {
    unawaited(storage.putSetting(
        StorageKeys.consentRecordedAt, '2026-08-30T10:00:00.000Z'));
    unawaited(storage.putSetting(StorageKeys.consentPolicyVersion,
        AppConstants.privacyPolicyVersion));
    await pump(tester);
    final footer = tester
        .widget<Text>(find.byKey(const Key('consentRecordFooter')))
        .data!;
    expect(footer, contains('${AppConstants.privacyPolicyVersion}'));
    expect(footer, contains('30'), reason: 'the recorded day');
  });

  testWidgets('toggling a consent row writes through the consent provider '
      '(the write path is unchanged)', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('consentLocationToggle')));
    await tester.pumpAndSettle();
    expect(storage.getSetting(StorageKeys.consentLocation), isTrue);
    expect(storage.getSetting(StorageKeys.consentErrorReporting), isFalse);
  });

  testWidgets('no row truncates at 320 dp in French (the long-subtitle '
      'locale of the #3907 screenshots)', (tester) async {
    tester.view.physicalSize = const Size(320, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(
      tester,
      const PrivacyChoicesScreen(),
      locale: const Locale('fr'),
      overrides: [hiveStorageProvider.overrideWithValue(storage)],
    );
    expect(tester.takeException(), isNull);
    expectNoTextTruncates(tester,
        within: find.byKey(const Key('privacyChoicesList')));
  });
}
