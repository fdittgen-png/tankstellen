// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_request.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/fuel_and_tank_screen.dart';

import '../../../../fakes/fake_storage_repository.dart';
import '../fuel_and_tank_test_support.dart';

/// #4278 — the Fuel & Tank surface over SYNTHETIC scenarios, the real
/// decision and the real view model. Every assertion names a formatted
/// VALUE, not just a label (the #4256 lesson). Numbers render in the
/// formatter's default fr_FR locale, copy in English.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, List<Object> overrides) =>
      pumpSurface(tester, const FuelAndTankBody(vehicleId: kVehicleId),
          overrides: overrides);

  group('tank mix', () {
    testWidgets('a partly known mix shows minimums and the unknown share',
        (tester) async {
      await pump(tester, fuelAndTankOverrides());
      expect(find.byKey(const Key('fuel_and_tank_mix_focal')), findsOneWidget);
      expect(find.text('≥ 62 %'), findsOneWidget);
      expect(find.text('≥ 62 % E85 Bioethanol · ≥ 30 % Super E10 · 8 % unknown'),
          findsOneWidget);
      expect(find.text('Between 20,0 L and 30,0 L in the tank'), findsOneWidget);
      expect(find.textContaining('The shares are guaranteed minimums'),
          findsOneWidget);
      expect(find.byKey(const Key('fuel_and_tank_mix_segment_unknown')),
          findsOneWidget);
      expect(find.text('Mix unknown'), findsNothing);
    });

    testWidgets('an exact mix drops the ≥ and the unknown share',
        (tester) async {
      await pump(
          tester,
          fuelAndTankOverrides(
              tank: tankOf({FuelGrade.e85: 0.75, FuelGrade.e10: 0.25},
                  min: 40, max: 40)));
      expect(find.text('75 % E85 Bioethanol · 25 % Super E10'), findsOneWidget);
      expect(find.text('75 %'), findsOneWidget);
      expect(find.text('40,0 L in the tank'), findsOneWidget);
      expect(find.textContaining('% unknown'), findsNothing);
      expect(find.byKey(const Key('fuel_and_tank_mix_segment_unknown')),
          findsNothing);
    });

    testWidgets('an unattributable tank is the unknown state, no number',
        (tester) async {
      await pump(tester, fuelAndTankOverrides(tank: unknownTank()));
      expect(find.byKey(const Key('fuel_and_tank_mix_unknown')), findsOneWidget);
      expect(find.text('Mix unknown'), findsOneWidget);
      expect(find.textContaining('A fill-up to a full tank'), findsOneWidget);
      expect(find.byKey(const Key('fuel_and_tank_mix_focal')), findsNothing);
      expect(find.text('100 % unknown'), findsNothing);
      // With nothing known about the volume the next fill cannot be sized.
      expect(
          find.byKey(const Key('fuel_and_tank_reason_fillVolumeUnknown')),
          findsOneWidget);
    });
  });

  group('compatibility', () {
    testWidgets('a flex-fuel car lists its approvals', (tester) async {
      await pump(tester, fuelAndTankOverrides());
      for (final g in [FuelGrade.e5, FuelGrade.e10, FuelGrade.e98, FuelGrade.e85]) {
        expect(find.byKey(ValueKey('fuel_and_tank_compat_${g.key}')),
            findsOneWidget);
      }
      expect(find.text('Fit, but not confirmed for this vehicle'), findsNothing);
    });

    testWidgets('an E10 car: E85 fits but is not confirmed', (tester) async {
      await pump(tester, fuelAndTankOverrides(vehicle: e10Car));
      expect(find.text('Approved in your vehicle settings'), findsOneWidget);
      expect(find.text('Fit, but not confirmed for this vehicle'),
          findsOneWidget);
      final e85 = find.byKey(const ValueKey('fuel_and_tank_compat_e85'));
      expect(tester.widget<Text>(e85).data, 'E85 Bioethanol');
    });

    // #4324 — the persisted declaration reaches the surface.
    testWidgets('an E10 car declared E85-approved lists E85 as approved',
        (tester) async {
      await pump(
          tester,
          fuelAndTankOverrides(
              vehicle: e10Car.copyWith(
                  approvedFuelGrades: const ['e5', 'e10', 'e98', 'e85'])));
      expect(find.text('Fit, but not confirmed for this vehicle'), findsNothing);
      final e85 = find.byKey(const ValueKey('fuel_and_tank_compat_e85'));
      expect(tester.widget<Text>(e85).data, 'E85 Bioethanol');
      expect(find.text('Fill E85 Bioethanol next'), findsOneWidget);
    });
  });

  group('behaviour — vehicle-specific, evidence-labelled', () {
    testWidgets('E10 against E85 with values, provenance and samples',
        (tester) async {
      await pump(tester, fuelAndTankOverrides());
      expect(find.text('Your car'), findsOneWidget);
      expect(
          find.text('Super E10 uses 23 % less than E85 Bioethanol'),
          findsOneWidget);
      expect(find.textContaining('Adjusted for driving conditions.'),
          findsOneWidget);
      // Full-to-full windows: measured, two samples, medium confidence.
      expect(find.text('6,1 L/100 km'), findsOneWidget);
      expect(find.text('7,9 L/100 km'), findsOneWidget);
      expect(find.text('0,087 €/km'), findsOneWidget);
      expect(find.text('820 km'), findsOneWidget);
      expect(find.text('111 g/km'), findsOneWidget);
      expect(find.text('Measured · 2 samples · medium confidence'),
          findsWidgets);
      expect(find.text('Estimated · 2 samples · low confidence'), findsNothing);
      // E5 and E98 are approved but never driven.
      expect(find.text('Not driven on this fuel yet'), findsNWidgets(2));
    });

    testWidgets('estimated trips are labelled estimated and uncontrolled',
        (tester) async {
      await pump(
          tester,
          fuelAndTankOverrides(
              vehicle: e10Car, profile: estimatedProfile()));
      // Consumption, and the range computed from it.
      expect(find.text('Estimated · 10 samples · low confidence'),
          findsNWidgets(2));
      expect(find.text('Measured · 10 samples · low confidence'), findsNothing);
      expect(find.byKey(const ValueKey('fuel_and_tank_uncontrolled_pure:e10')),
          findsOneWidget);
      expect(find.text('6,0 L/100 km'), findsOneWidget);
    });

    testWidgets('insufficient evidence says so and shows no number',
        (tester) async {
      await pump(
          tester, fuelAndTankOverrides(vehicle: e10Car, profile: thinProfile()));
      expect(find.text('Not enough evidence yet · 3 samples'), findsOneWidget);
      expect(find.textContaining('L/100 km'), findsNothing);
      expect(find.text('Drive on two different fuels to compare them.'),
          findsOneWidget);
    });

    testWidgets('the details disclose basis, interval and model versions',
        (tester) async {
      await pump(tester, fuelAndTankOverrides());
      expect(find.text('Behaviour model v1 · blend model v1'), findsNothing);
      await expandAll(tester);
      expect(find.text('Behaviour model v1 · blend model v1'), findsOneWidget);
      expect(
          find.text('Consumption · From full-tank to full-tank fill-ups · '
              '95 % range 4,8 L/100 km – 7,4 L/100 km'),
          findsOneWidget);
    });

    testWidgets('general facts are a separate, labelled panel',
        (tester) async {
      await pump(tester, fuelAndTankOverrides());
      expect(
          find.text('General information · From the fuel standards — not '
              'measured on your car.'),
          findsOneWidget);
      expect(
          find.text('Super E10: at least 90 % petrol; up to 10 % can be '
              'ethanol.'),
          findsOneWidget);
      expect(
          find.text('E85 Bioethanol: at least 50 % ethanol; the rest varies '
              'with the season.'),
          findsOneWidget);
      expect(find.textContaining('names the octane rating'), findsOneWidget);
    });
  });

  group('next fill — every outcome', () {
    testWidgets('recommend: the fuel, resulting mix, trade-off, break-even',
        (tester) async {
      await pump(tester, fuelAndTankOverrides());
      expect(find.text('Fill E85 Bioethanol next'), findsOneWidget);
      expect(find.text('Decision made with medium confidence'), findsOneWidget);
      expect(
          find.text('Cheapest prices for 2 fuels among your favourite stations'),
          findsOneWidget);
      expect(
          find.text('Tank after this fill: ≥ 77 % E85 Bioethanol · '
              '≥ 15 % Super E10 · 8 % unknown'),
          findsOneWidget);
      expect(find.text('0,037 €/km cheaper than Super E10'), findsOneWidget);
      expect(
          find.text('Break-even: E85 Bioethanol at 1,589 €/L costs the same '
              'per km as Super E10'),
          findsOneWidget);
      expect(
          find.text('2 fills of E85 Bioethanol bring the tank to at least '
              '86 %.'),
          findsOneWidget);
      await expandAll(tester);
      expect(find.byKey(const ValueKey('fuel_and_tank_candidate_e85')),
          findsOneWidget);
      expect(find.text('Pump price 1,100 €/L · Filling 20,0 L'), findsOneWidget);
      expect(find.text('0,082 €/km'), findsOneWidget);
    });

    testWidgets('no material advantage', (tester) async {
      await pump(tester, fuelAndTankOverrides(offerList: offers(e85: 1.60)));
      expect(find.text('No fuel is clearly better right now'), findsOneWidget);
      expect(find.text('The difference is too small to be worth switching.'),
          findsOneWidget);
      // #4324 — "too small" quotes the decision's own threshold.
      expect(
          find.text('A fuel is only suggested when it is at least 2 % better.'),
          findsOneWidget);
      expect(find.text('Fill E85 Bioethanol next'), findsNothing);
      expect(find.text('Fill Super E10 next'), findsNothing);
    });

    testWidgets('insufficient evidence: uncertainty dominates',
        (tester) async {
      await pump(tester, fuelAndTankOverrides(offerList: offers(e85: 1.545)));
      expect(find.text('Not enough evidence to recommend a fuel yet'),
          findsOneWidget);
      expect(
          find.text(
              'The difference is smaller than the uncertainty in your data.'),
          findsOneWidget);
      expect(find.byKey(const Key('fuel_and_tank_resulting_mix')), findsNothing);
    });

    testWidgets('trade-off: cheaper against cleaner, with cost per kg',
        (tester) async {
      await pump(
          tester,
          fuelAndTankOverrides(
            tank: tankOf({FuelGrade.e85: 1}, min: 0, max: 0),
            profile: flexProfile(windows: false),
            offerList: offers(e85: 1.60),
            objective: FillObjective.balancedCostCo2e,
          ));
      expect(find.text('A trade-off: one fuel is cheaper, another emits less'),
          findsOneWidget);
      // E10 ≈ 5,99 L × 1,80 vs E85 ≈ 7,78 L × 1,60; factors 2,27 / 1,40.
      expect(find.text('0,017 €/km cheaper than E85 Bioethanol'),
          findsOneWidget);
      expect(find.text('27 g CO2e/km more than E85 Bioethanol'),
          findsOneWidget);
      expect(find.text('E85 Bioethanol avoids CO2e at 0,62 € per kg'),
          findsOneWidget);
    });

    // #4324 — a share under the target counted as reached says so.
    testWidgets('already at target within the tolerance quotes both figures',
        (tester) async {
      await pump(
          tester,
          fuelAndTankOverrides(
              tank: tankOf({FuelGrade.e85: 0.82, FuelGrade.e10: 0.18},
                  min: 30, max: 30)));
      expect(find.text('Fill E85 Bioethanol next'), findsOneWidget);
      expect(
          find.text('The tank already holds at least 82 % E85 Bioethanol.'),
          findsOneWidget);
      expect(
          find.text('Counted as reached within 5 points of the 85 % target.'),
          findsOneWidget);
    });

    testWidgets('a target actually reached adds no tolerance line',
        (tester) async {
      await pump(tester, fuelAndTankOverrides());
      expect(find.text('2 fills of E85 Bioethanol bring the tank to at least '
          '86 %.'), findsOneWidget);
      expect(find.byKey(const Key('fuel_and_tank_convergence_tolerance')),
          findsNothing);
    });

    // #4324 — prices from the last search name their source; the detour is
    // priced into the decision.
    testWidgets('nearby-search offers say where the prices come from',
        (tester) async {
      const station = RefuelCandidate(stationId: 'near', oneWayKm: 3);
      await pump(
          tester,
          fuelAndTankOverrides(
              tank: tankOf({FuelGrade.e85: 1}, min: 30, max: 30),
              offerList: [
            FuelOffer(
                grade: FuelGrade.e10, pricePerLitre: 1.80, station: station),
            FuelOffer(
                grade: FuelGrade.e85, pricePerLitre: 1.10, station: station),
          ]));
      expect(
          find.text('Cheapest prices for 2 fuels among the stations of your '
              'last search, detour included'),
          findsOneWidget);
      expect(
          find.text('Cheapest prices for 2 fuels among your favourite stations'),
          findsNothing);
      // The station's distance reached RefuelEconomics: the detour is
      // priced into each candidate (a favourite could never say this).
      await expandAll(tester);
      expect(find.text('The detour to the station is priced in.'),
          findsWidgets);
      expect(find.text("The detour to the station isn't priced in."),
          findsNothing);
    });

    testWidgets('no compatible fuel: the unapproved one is left out',
        (tester) async {
      await pump(
          tester,
          fuelAndTankOverrides(
              vehicle: e10Car, offerList: offers(e10: null, e85: 1.10)));
      expect(find.text('No priced fuel is confirmed for this vehicle'),
          findsOneWidget);
      await expandAll(tester);
      expect(
          find.text('E85 Bioethanol — Not confirmed as approved in your '
              'vehicle settings.'),
          findsOneWidget);
    });

    testWidgets('compatibility unknown', (tester) async {
      await pump(tester, fuelAndTankOverrides(vehicle: bareCar));
      expect(find.text('Approved fuels unknown — no recommendation'),
          findsOneWidget);
      expect(find.textContaining('This vehicle has no fuel set'),
          findsOneWidget);
      expect(find.text('No price comparison possible'), findsNothing);
    });

    testWidgets('no prices: says why no comparison is possible',
        (tester) async {
      await pump(tester, fuelAndTankOverrides(offerList: const []));
      expect(find.text('No price comparison possible'), findsOneWidget);
      expect(find.text('No priced fuel is confirmed for this vehicle'),
          findsNothing);
    });

    testWidgets('selecting an objective persists it', (tester) async {
      final storage = FakeStorageRepository();
      await pump(tester, fuelAndTankOverrides(storage: storage));
      final chip = find.byKey(
          const ValueKey('fuel_and_tank_objective_lowestConsumption'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(storage.getSetting(StorageKeys.fillObjective), 'lowestConsumption');
      expect(
          tester
              .widget<RadioGroup<FillObjective>>(
                  find.byType(RadioGroup<FillObjective>))
              .groupValue,
          FillObjective.lowestConsumption);
    });
  });
}
