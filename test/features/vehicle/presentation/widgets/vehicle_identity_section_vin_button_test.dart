import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_identity_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the "Read VIN from car" button (#1162) on
/// [VehicleIdentitySection]. The button is gated by the
/// [VehicleIdentitySection.onReadVinFromCar] callback being non-null
/// — the parent screen passes a callback only when an OBD2 adapter
/// is paired to the profile, so the button must not render otherwise.
void main() {
  group('VehicleIdentitySection — Read VIN from car button (#1162)', () {
    testWidgets(
      'button is hidden when onReadVinFromCar is null '
      '(no paired adapter on the profile)',
      (tester) async {
        await _pump(tester, onReadVinFromCar: null);

        // Negative assertion — we want to be sure the affordance is
        // ABSENT, not just that we forgot to find it.
        expect(find.text('Read VIN from car'), findsNothing);
        expect(find.byTooltip('Read VIN from car'), findsNothing);
      },
    );

    testWidgets(
      'button renders with tooltip + icon when onReadVinFromCar is set',
      (tester) async {
        await _pump(tester, onReadVinFromCar: () {});

        // The text appears twice — once as the OutlinedButton.icon
        // label and once inside the Tooltip overlay's accessibility
        // tree — so we use findsWidgets, then assert tooltip /
        // button presence separately.
        expect(find.text('Read VIN from car'), findsWidgets);
        expect(find.byTooltip('Read VIN from car'), findsOneWidget);
        expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      },
    );

    testWidgets(
      'tapping the button invokes the callback exactly once',
      (tester) async {
        var taps = 0;
        await _pump(tester, onReadVinFromCar: () => taps++);

        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        expect(taps, 1);
      },
    );

    testWidgets(
      'spinner replaces the icon and the button is disabled while '
      'a read is in flight',
      (tester) async {
        var taps = 0;
        await _pump(
          tester,
          onReadVinFromCar: () => taps++,
          readingVinFromCar: true,
        );

        // Spinner replaces the leading icon while reading.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.bluetooth_searching), findsNothing);

        // Disabled OutlinedButton ignores taps. tester.tap() will not
        // throw — but the callback must not fire.
        await tester.tap(
          find.byType(OutlinedButton),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(taps, 0);
      },
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback? onReadVinFromCar,
  bool readingVinFromCar = false,
}) async {
  final nameCtrl = TextEditingController();
  final vinCtrl = TextEditingController();
  final vinFocus = FocusNode();
  addTearDown(() {
    nameCtrl.dispose();
    vinCtrl.dispose();
    vinFocus.dispose();
  });

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Form(
          child: VehicleIdentitySection(
            nameController: nameCtrl,
            vinController: vinCtrl,
            vinFocus: vinFocus,
            accent: Colors.blue,
            decodingVin: false,
            onDecodeVin: () {},
            onShowVinInfo: () {},
            onReadVinFromCar: onReadVinFromCar,
            readingVinFromCar: readingVinFromCar,
          ),
        ),
      ),
    ),
  );
  // Two short pumps in lieu of pumpAndSettle: when the spinner is
  // visible, pumpAndSettle hangs forever on the never-ending
  // CircularProgressIndicator animation.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
