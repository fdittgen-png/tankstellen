import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/calibration_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Captures every callback emitted by the [CalibrationSection] under
/// test so the assertions can pin both the value and the field that
/// fired the update.
class _CapturedCalls {
  double? lastDisplacement;
  double? lastVe;
  double? lastAfr;
  double? lastDensity;
  bool resetLearnerFired = false;
  bool displacementFired = false;
  bool veFired = false;
  bool afrFired = false;
  bool densityFired = false;
}

Widget _harness(VehicleProfile profile, _CapturedCalls calls) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: CalibrationSection(
          profile: profile,
          onDisplacementChanged: (v) {
            calls.lastDisplacement = v;
            calls.displacementFired = true;
          },
          onVolumetricEfficiencyChanged: (v) {
            calls.lastVe = v;
            calls.veFired = true;
          },
          onAfrChanged: (v) {
            calls.lastAfr = v;
            calls.afrFired = true;
          },
          onFuelDensityChanged: (v) {
            calls.lastDensity = v;
            calls.densityFired = true;
          },
          onResetLearner: () => calls.resetLearnerFired = true,
        ),
      ),
    ),
  );
}

void main() {
  group('CalibrationSection (#1397)', () {
    testWidgets(
        'collapsed by default — fields are not in the tree until '
        'the tile is expanded', (tester) async {
      const profile = VehicleProfile(id: 'v', name: 'Duster');
      await tester.pumpWidget(_harness(profile, _CapturedCalls()));
      await tester.pump();

      expect(find.text('Advanced calibration'), findsOneWidget);
      // ExpansionTile is collapsed → its children (the four labels)
      // are not painted.
      expect(find.text('Engine displacement (cc)'), findsNothing);
    });

    testWidgets(
        'expand reveals four labelled fields with their localized helper '
        'text', (tester) async {
      const profile = VehicleProfile(id: 'v', name: 'Duster');
      await tester.pumpWidget(_harness(profile, _CapturedCalls()));
      await tester.pump();

      await tester.tap(find.text('Advanced calibration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Engine displacement (cc)'), findsOneWidget);
      expect(find.text('Volumetric efficiency (η_v)'), findsOneWidget);
      expect(find.text('Air-to-fuel ratio (AFR)'), findsOneWidget);
      expect(find.text('Fuel density (g/L)'), findsOneWidget);
    });

    testWidgets(
        'helper text labels each field with the resolved value source '
        '— manual displacement → "(manual)", default VE → "(default)"',
        (tester) async {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster',
        manualEngineDisplacementCcOverride: 1700,
      );
      await tester.pumpWidget(_harness(profile, _CapturedCalls()));
      await tester.pump();
      await tester.tap(find.text('Advanced calibration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The displacement field carries the (manual) helper.
      expect(find.text('(manual)'), findsOneWidget);
      // VE / AFR / fuel density all default → multiple "(default)"
      // helpers visible at once.
      expect(find.text('(default)'), findsWidgets);
    });

    testWidgets(
        'helper text shows "(detected from VIN)" when displacement '
        'comes from a VIN decode and no manual override is set',
        (tester) async {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster',
        // Vehicle field unset, but the VIN reader populated detected*.
        detectedEngineDisplacementCc: 1461,
      );
      await tester.pumpWidget(_harness(profile, _CapturedCalls()));
      await tester.pump();
      await tester.tap(find.text('Advanced calibration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('(detected from VIN)'), findsOneWidget);
    });

    testWidgets(
        'reset button on a manually-overridden field calls the '
        'callback with null', (tester) async {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster',
        manualVolumetricEfficiencyOverride: 0.92,
      );
      final calls = _CapturedCalls();
      await tester.pumpWidget(_harness(profile, calls));
      await tester.pump();
      await tester.tap(find.text('Advanced calibration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find the restart_alt icon next to the η_v field. The label
      // anchors which row we click.
      final veField = find.ancestor(
        of: find.text('Volumetric efficiency (η_v)'),
        matching: find.byType(TextFormField),
      );
      expect(veField, findsOneWidget);
      final resetIcon = find.descendant(
        of: veField,
        matching: find.byIcon(Icons.restart_alt),
      );
      expect(resetIcon, findsOneWidget);
      await tester.tap(resetIcon);
      await tester.pump();

      expect(calls.veFired, isTrue);
      expect(calls.lastVe, isNull,
          reason: 'reset must clear the manual override');
    });

    testWidgets(
        'live readout — samples == 0 → "no plein-complet yet"',
        (tester) async {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster',
        // volumetricEfficiencySamples defaults to 0
      );
      await tester.pumpWidget(_harness(profile, _CapturedCalls()));
      await tester.pump();
      await tester.tap(find.text('Advanced calibration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('no plein-complet'), findsOneWidget);
    });

    testWidgets(
        'live readout — samples > 0 → "calibrated, N samples"',
        (tester) async {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster',
        volumetricEfficiency: 0.87,
        volumetricEfficiencySamples: 4,
      );
      await tester.pumpWidget(_harness(profile, _CapturedCalls()));
      await tester.pump();
      await tester.tap(find.text('Advanced calibration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('0.87'), findsWidgets);
      expect(find.textContaining('4'), findsWidgets);
      expect(find.textContaining('calibrated'), findsOneWidget);
    });

    testWidgets('Reset learner button fires the onResetLearner callback',
        (tester) async {
      const profile = VehicleProfile(
        id: 'v',
        name: 'Duster',
        volumetricEfficiency: 0.87,
        volumetricEfficiencySamples: 4,
      );
      final calls = _CapturedCalls();
      await tester.pumpWidget(_harness(profile, calls));
      await tester.pump();
      await tester.tap(find.text('Advanced calibration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reset learner'));
      await tester.pump();
      expect(calls.resetLearnerFired, isTrue);
    });
  });

  group('resolveCalibrationSource priority (#1397)', () {
    test('manual wins even when detected and catalog also set', () {
      expect(
        resolveCalibrationSource(
          manualSet: true,
          detectedSet: true,
          catalogResolved: true,
        ),
        CalibrationValueSource.manual,
      );
    });

    test('detected wins when manual is unset', () {
      expect(
        resolveCalibrationSource(
          manualSet: false,
          detectedSet: true,
          catalogResolved: true,
        ),
        CalibrationValueSource.detected,
      );
    });

    test('catalog wins when manual + detected both unset', () {
      expect(
        resolveCalibrationSource(
          manualSet: false,
          detectedSet: false,
          catalogResolved: true,
        ),
        CalibrationValueSource.catalog,
      );
    });

    test('default when no source is set', () {
      expect(
        resolveCalibrationSource(
          manualSet: false,
          detectedSet: false,
          catalogResolved: false,
        ),
        CalibrationValueSource.defaultConstant,
      );
    });
  });
}
