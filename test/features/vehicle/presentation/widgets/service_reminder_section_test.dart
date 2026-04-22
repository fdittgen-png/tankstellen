import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/vehicle/data/repositories/service_reminder_repository.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/service_reminder_section.dart';
import 'package:tankstellen/features/vehicle/providers/service_reminder_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Render tests for [ServiceReminderSection] (#584). Focuses on the
/// empty-state UI because the preset chips are the only UI the user
/// interacts with on a fresh vehicle. Tap behaviour (preset → stored
/// reminder) is covered in
/// `service_reminder_providers_test.dart`, and the rendering of
/// existing reminder rows is covered by `service_reminder_row_test.dart`
/// — keeping this file narrow avoids the Material ripple stall that
/// hits widget tests when a chip's `onPressed` mutates a
/// `Riverpod` notifier mid-frame on Windows.
void main() {
  late Directory tempDir;
  late Box<String> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reminder_widget_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(HiveBoxes.serviceReminders);
    await box.clear();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> pump(
    WidgetTester tester,
    String vehicleId, {
    double? currentOdometerKm,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serviceReminderRepositoryProvider
              .overrideWithValue(ServiceReminderRepository(box)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ServiceReminderSection(
                vehicleId: vehicleId,
                currentOdometerKm: currentOdometerKm,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the three preset chips with their interval labels',
      (tester) async {
    await pump(tester, 'v-1');

    expect(find.text('Oil (15,000 km)'), findsOneWidget);
    expect(find.text('Tires (20,000 km)'), findsOneWidget);
    expect(find.text('Inspection (30,000 km)'), findsOneWidget);
  });

  testWidgets('shows the empty-state message when no reminders exist',
      (tester) async {
    await pump(tester, 'v-1');
    expect(
      find.textContaining('No reminders yet'),
      findsOneWidget,
    );
  });

  testWidgets('shows the add-reminder button', (tester) async {
    await pump(tester, 'v-1');
    expect(find.text('Add reminder'), findsOneWidget);
  });

  testWidgets('renders section title', (tester) async {
    await pump(tester, 'v-1');
    expect(find.text('Service reminders'), findsOneWidget);
  });

  testWidgets('preset chips are ActionChips with an onPressed callback',
      (tester) async {
    await pump(tester, 'v-1');

    // Asserting the chip is interactive guarantees the preset picker
    // is actually wired up without triggering a full tap gesture.
    final oil = tester.widget<ActionChip>(
      find.widgetWithText(ActionChip, 'Oil (15,000 km)'),
    );
    final tires = tester.widget<ActionChip>(
      find.widgetWithText(ActionChip, 'Tires (20,000 km)'),
    );
    final inspection = tester.widget<ActionChip>(
      find.widgetWithText(ActionChip, 'Inspection (30,000 km)'),
    );
    expect(oil.onPressed, isNotNull);
    expect(tires.onPressed, isNotNull);
    expect(inspection.onPressed, isNotNull);
  });
}
