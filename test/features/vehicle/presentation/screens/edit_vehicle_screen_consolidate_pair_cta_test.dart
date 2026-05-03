import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Integration tests for #1400: the auto-record card's passive
/// "Pair an adapter in the section below" link must scroll the host
/// `ListView` to the canonical OBD2 adapter card and pulse its
/// border. Pre-#1400 the auto-record card carried a duplicate
/// orange-tinted "Pair an adapter" CTA that opened the picker —
/// users had two CTAs side by side that did the same thing. After
/// #1400 there is exactly ONE pair entry point: the OBD2 adapter
/// card's "Pair adapter" button. The auto-record card just points
/// users at it.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp
        .createTemp('edit_vehicle_consolidate_pair_cta_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await Hive.openBox<String>(HiveBoxes.obd2Baselines);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('EditVehicleScreen — consolidate pair CTA (#1400)', () {
    testWidgets(
      'auto-record card renders the passive link and the OBD2 card '
      'still renders the canonical pair button (single source of truth)',
      (tester) async {
        // Tall canvas so multiple cards fit without overflow during
        // the test pump.
        tester.view.physicalSize = const Size(900, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(const VehicleProfile(
          id: 'v1',
          name: 'Car',
          autoRecord: true,
        ));

        await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

        // Sanity — the auto-record card is on screen and surfaces the
        // passive link, NOT the deprecated CTA.
        await tester.dragUntilVisible(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          find.byType(ListView),
          const Offset(0, -200),
        );
        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('autoRecordStatusPairAdapterCta')),
          findsNothing,
          reason:
              '#1400 — the duplicate orange-tinted CTA on the auto-record '
              'card must be gone',
        );

        // The OBD2 adapter card still owns the canonical pair button.
        await tester.dragUntilVisible(
          find.byKey(const Key('vehicleAdapterPair')),
          find.byType(ListView),
          const Offset(0, -200),
        );
        expect(find.byKey(const Key('vehicleAdapterPair')), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the auto-record link scrolls the host ListView so the '
      'OBD2 card lands inside the viewport (#1400)',
      (tester) async {
        // Phone-sized canvas (taller than wide) so the cards genuinely
        // live on different pages of the ListView. The OBD2 card is
        // ABOVE the auto-record link in the layout (extras section
        // spreads first), so to exercise the scroll we have to land
        // the OBD2 card OFF-screen above the viewport — only then does
        // `Scrollable.ensureVisible` have meaningful work to do. Width
        // 600 keeps the drivetrain dropdowns inside their flex bounds.
        tester.view.physicalSize = const Size(600, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(const VehicleProfile(
          id: 'v1',
          name: 'Car',
          autoRecord: true,
        ));

        await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

        // The auto-record link sits below the fold by default. Drag
        // the ListView until it's mounted in the tree, then anchor it
        // to the BOTTOM of the viewport so the OBD2 card (which is
        // above) sits above the top edge — that's the only configuration
        // where `Scrollable.ensureVisible` has meaningful work to do.
        await tester.dragUntilVisible(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          find.byType(ListView),
          const Offset(0, -200),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final linkCtx = tester.element(
          find.byKey(const Key('autoRecordPairAdapterLink')),
        );
        await Scrollable.ensureVisible(
          linkCtx,
          alignment: 1.0,
          duration: Duration.zero,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Snapshot the scroll offset BEFORE the tap so we can prove
        // the tap moved the viewport.
        ScrollPosition position() {
          final state = tester
              .state<ScrollableState>(find.byType(Scrollable).first);
          return state.position;
        }

        final beforeOffset = position().pixels;

        await tester.tap(
          find.byKey(const Key('autoRecordPairAdapterLink')),
        );
        // Pump enough frames for the 400 ms ensureVisible scroll plus
        // the 1 s forward+reverse highlight cycle (500 ms each).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        final afterOffset = position().pixels;

        // The OBD2 card lives ABOVE the link in the layout, so the
        // ensureVisible call scrolls UP — i.e. the offset DECREASES.
        // We don't pin a specific delta because the exact pixel jump
        // depends on text-metric layout, but the offset MUST have
        // moved.
        expect(
          afterOffset,
          lessThan(beforeOffset),
          reason:
              'Tapping the auto-record link must scroll up so the OBD2 '
              'card (which lives above the link) lands inside the '
              'viewport',
        );
      },
    );

    testWidgets(
      'tapping the link does not crash if the OBD2 card was already '
      'visible (#1400)',
      (tester) async {
        // Ultra-tall canvas — every card renders in-viewport at once,
        // so the scroll is a no-op. The tap must still complete
        // without throwing.
        tester.view.physicalSize = const Size(900, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = VehicleProfileRepository(_FakeSettings());
        await repo.save(const VehicleProfile(
          id: 'v1',
          name: 'Car',
          autoRecord: true,
        ));

        await _pumpEditScreen(tester, repo: repo, vehicleId: 'v1');

        // Both link and pair button visible without scrolling.
        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('vehicleAdapterPair')), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('autoRecordPairAdapterLink')),
        );
        // Pump the highlight cycle to completion so the controller
        // doesn't leak a pending future into the test.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        // No exceptions surfaced (the test would already have failed
        // on a thrown exception). Belt-and-suspender: still find the
        // tree intact.
        expect(
          find.byKey(const Key('autoRecordPairAdapterLink')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('vehicleAdapterPair')), findsOneWidget);
      },
    );
  });
}

Future<void> _pumpEditScreen(
  WidgetTester tester, {
  required VehicleProfileRepository repo,
  required String vehicleId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditVehicleScreen(vehicleId: vehicleId),
      ),
    ),
  );
  // Bounded pump — the screen has a postFrameCallback that hydrates
  // the form controllers from the provider. Two pumps after the
  // initial paint is enough; a pumpAndSettle would block on any
  // background animation in the children (none here, but cheap to
  // be safe).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
