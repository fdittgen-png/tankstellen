import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_capability.dart';
import 'package:tankstellen/features/consumption/providers/obd2_capability_provider.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/obd2_capability_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Widget buildHarness({
    required Obd2AdapterCapability? capability,
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: [
        currentObd2CapabilityProvider.overrideWith((_) => capability),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const Scaffold(body: Obd2CapabilitySection()),
      ),
    );
  }

  group('Obd2CapabilitySection (#1401 phase 6)', () {
    testWidgets(
        'renders nothing when capability is null — no card on the '
        'screen for users without a connected adapter', (tester) async {
      await tester.pumpWidget(buildHarness(capability: null));
      await tester.pumpAndSettle();
      // The widget collapses to SizedBox.shrink — neither the title
      // nor the upgrade hint should appear anywhere.
      expect(find.text('Adapter capabilities'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders the Standard label + USB icon for the '
        'standardOnly tier', (tester) async {
      await tester.pumpWidget(
        buildHarness(capability: Obd2AdapterCapability.standardOnly),
      );
      await tester.pumpAndSettle();
      expect(find.text('Adapter capabilities'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.byIcon(Icons.usb), findsOneWidget);
    });

    testWidgets('renders the OEM PIDs label + tune icon for the '
        'oemPidsCapable tier and hides the upgrade hint',
        (tester) async {
      await tester.pumpWidget(
        buildHarness(capability: Obd2AdapterCapability.oemPidsCapable),
      );
      await tester.pumpAndSettle();
      expect(find.text('OEM PIDs'), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(
        find.textContaining('OBDLink'),
        findsNothing,
        reason: 'OEM-PID adapters already unlock the supported flow; '
            'no upgrade hint should show.',
      );
    });

    testWidgets('renders the Full CAN label + bolt icon for the '
        'passiveCanCapable tier', (tester) async {
      await tester.pumpWidget(
        buildHarness(capability: Obd2AdapterCapability.passiveCanCapable),
      );
      await tester.pumpAndSettle();
      expect(find.text('Full CAN'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(
        find.textContaining('OBDLink'),
        findsNothing,
        reason: 'Full-CAN adapters are top tier; no upgrade hint.',
      );
    });

    testWidgets(
        'renders the OBDLink upgrade hint ONLY on the standardOnly tier',
        (tester) async {
      await tester.pumpWidget(
        buildHarness(capability: Obd2AdapterCapability.standardOnly),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('OBDLink'), findsOneWidget);
      expect(find.textContaining('STN chip'), findsOneWidget);
    });

    testWidgets('localizes the section title and tier label in French — '
        'no English fallback on French devices', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          capability: Obd2AdapterCapability.standardOnly,
          locale: const Locale('fr'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Capacités de l'adaptateur"), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(
        find.textContaining('Peugeot/Citroën'),
        findsOneWidget,
        reason:
            'French upgrade hint must mention Peugeot/Citroën with cedilla.',
      );
    });

    testWidgets('localizes the OEM PIDs and Full CAN tier labels in '
        'German', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          capability: Obd2AdapterCapability.oemPidsCapable,
          locale: const Locale('de'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Adapter-Fähigkeiten'), findsOneWidget);
      expect(find.text('OEM-PIDs'), findsOneWidget);
    });
  });
}
