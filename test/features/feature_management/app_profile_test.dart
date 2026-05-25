import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/app_profile.dart';
import 'package:tankstellen/features/feature_management/domain/conso_mode.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

/// Pure-domain coverage for the [AppProfile] bundles and the detection
/// helper (#1517). No Hive, no Riverpod — these guard the contract that
/// drives both the wizard's first page and the Settings selector.
void main() {
  group('appProfileBundles', () {
    test('basic includes the price / discovery flags + sync foundation',
        () {
      final basic = appProfileBundles[AppProfile.basic]!;
      expect(basic, contains(Feature.showFuel));
      expect(basic, contains(Feature.showElectric));
      expect(basic, contains(Feature.priceAlerts));
      expect(basic, contains(Feature.priceHistory));
      expect(basic, contains(Feature.routePlanning));
      expect(basic, contains(Feature.evCharging));
      // Cross-device sync is part of every preset, including Basic —
      // users running search-only workflows still benefit from
      // favorites + price-history sync across phones.
      expect(basic, contains(Feature.tankSync));
      expect(basic, contains(Feature.baselineSync));
      // Basic must NOT include the consumption / OBD2 / loyalty stack.
      expect(basic, isNot(contains(Feature.manualConsumption)));
      expect(basic, isNot(contains(Feature.obd2TripRecording)));
      expect(basic, isNot(contains(Feature.gamification)));
      expect(basic, isNot(contains(Feature.loyaltyCards)));
      expect(basic, isNot(contains(Feature.consumptionAnalytics)));
    });

    test('medium adds manualConsumption + showConsumptionTab to basic, no OBD2 stack', () {
      final basic = appProfileBundles[AppProfile.basic]!;
      final medium = appProfileBundles[AppProfile.medium]!;
      // Medium is a superset of Basic.
      for (final f in basic) {
        expect(medium, contains(f),
            reason: 'medium must include every basic flag');
      }
      // Medium adds manualConsumption + the surface flag for the Conso
      // settings section (#1568 — without showConsumptionTab the
      // isConsumptionTabReachable gate short-circuits and Medium users
      // can't reach the vehicle-add affordance).
      expect(medium, contains(Feature.manualConsumption));
      expect(medium, contains(Feature.showConsumptionTab));
      // #2025 — Medium now includes the trajet recording surface but
      // routes through the GPS-only path. The presence of
      // `obd2TripRecording` enables the Trajets tab + Start CTA; the
      // ABSENCE of `obd2Optional` tells the start flow to call
      // `startGpsOnly()` instead of the adapter picker.
      expect(medium, contains(Feature.obd2TripRecording));
      expect(medium, contains(Feature.consumptionAnalytics));
      expect(medium, contains(Feature.gpsTripPath));
      expect(medium, isNot(contains(Feature.obd2Optional)));
      // Auto-record / gamification / loyalty stay Full-tier — they
      // assume a paired OBD2 dongle.
      expect(medium, isNot(contains(Feature.autoRecord)));
      expect(medium, isNot(contains(Feature.gamification)));
      expect(medium, isNot(contains(Feature.loyaltyCards)));
    });

    test('full includes the OBD2 stack + loyalty + ergonomic opt-ins '
        'on top of medium', () {
      final medium = appProfileBundles[AppProfile.medium]!;
      final full = appProfileBundles[AppProfile.full]!;
      for (final f in medium) {
        expect(full, contains(f),
            reason: 'full must include every medium flag');
      }
      // Full adds OBD2 + loyalty + ergonomic opt-ins.
      expect(full, contains(Feature.obd2TripRecording));
      expect(full, contains(Feature.autoRecord));
      expect(full, contains(Feature.gamification));
      expect(full, contains(Feature.consumptionAnalytics));
      expect(full, contains(Feature.showConsumptionTab));
      expect(full, contains(Feature.loyaltyCards));
      expect(full, contains(Feature.hapticEcoCoach));
      expect(full, contains(Feature.glideCoach));
      expect(full, contains(Feature.gpsTripPath));
      // #2025 — Full requires an OBD2 dongle to start a trip
      // (`obd2Optional` ON ⇒ adapter picker, no GPS-only fallback).
      expect(full, contains(Feature.obd2Optional));
      // Full does NOT mean "every flag on" — `tflitePricePrediction`
      // stays off until the user opts in (off-band model artifact).
      expect(full, isNot(contains(Feature.tflitePricePrediction)));
    });

    test('custom has an empty bundle (it is a sentinel, not a preset)', () {
      expect(appProfileBundles[AppProfile.custom], isEmpty);
    });

    test('every profile is declared in the bundles map', () {
      for (final p in AppProfile.values) {
        expect(appProfileBundles.containsKey(p), isTrue,
            reason: 'AppProfile.${p.name} missing from appProfileBundles');
      }
    });
  });

  group('detectProfileFromFlags', () {
    test('returns basic for the exact basic bundle', () {
      expect(
        detectProfileFromFlags(appProfileBundles[AppProfile.basic]!),
        AppProfile.basic,
      );
    });

    test('returns medium for the exact medium bundle', () {
      expect(
        detectProfileFromFlags(appProfileBundles[AppProfile.medium]!),
        AppProfile.medium,
      );
    });

    test('returns full for the exact full bundle', () {
      expect(
        detectProfileFromFlags(appProfileBundles[AppProfile.full]!),
        AppProfile.full,
      );
    });

    test('returns custom when a single extra flag is enabled on top of basic',
        () {
      final flags = {
        ...appProfileBundles[AppProfile.basic]!,
        // `tflitePricePrediction` is in NO preset bundle (off-band
        // model artifact) — adding it to Basic drifts the user off
        // the canonical Basic flag set.
        Feature.tflitePricePrediction,
      };
      expect(detectProfileFromFlags(flags), AppProfile.custom);
    });

    test('returns custom when a flag is missing from a bundle', () {
      final flags = {...appProfileBundles[AppProfile.medium]!}
        ..remove(Feature.priceAlerts);
      expect(detectProfileFromFlags(flags), AppProfile.custom);
    });

    test('returns custom for an empty flag set', () {
      expect(detectProfileFromFlags(<Feature>{}), AppProfile.custom);
    });

    test('returns custom for a flag set that is a strict superset of full', () {
      final flags = {
        ...appProfileBundles[AppProfile.full]!,
        // `tflitePricePrediction` lands in no preset bundle, so adding
        // it to Full drifts the user off the canonical Full flag set.
        Feature.tflitePricePrediction,
      };
      expect(detectProfileFromFlags(flags), AppProfile.custom);
    });
  });

  // #1574 — Lock the profile bundles to clean ConsoMode values so a
  // future bundle edit that drifts (e.g. enables obd2TripRecording on
  // Medium, or strips manualConsumption from Full) trips a clear test
  // instead of presenting a half-broken Conso surface to users.
  group('profile bundles map to clean ConsoMode values', () {
    test('basic ⇒ ConsoMode.off (no Conso surface at all)', () {
      expect(
        consoModeFromFlags(appProfileBundles[AppProfile.basic]!),
        ConsoMode.off,
      );
    });

    test(
        'medium ⇒ ConsoMode.fuelAndTrips (manual fill-ups + GPS-only trajets)',
        () {
      // #2025 — Medium now exposes the Trajets tab too; the trip-start
      // path uses the GPS-only branch (no OBD2 required). ConsoMode
      // still flips to fuelAndTrips because `obd2TripRecording` is in
      // the bundle — that's the surface gate, not the data-source gate.
      expect(
        consoModeFromFlags(appProfileBundles[AppProfile.medium]!),
        ConsoMode.fuelAndTrips,
      );
    });

    test('full ⇒ ConsoMode.fuelAndTrips (full Conso + OBD2 required)', () {
      expect(
        consoModeFromFlags(appProfileBundles[AppProfile.full]!),
        ConsoMode.fuelAndTrips,
      );
    });
  });

  // #1574 — Structural invariants over every preset bundle: the Conso
  // flag set must be self-consistent so the runtime never has to deal
  // with "trips on but no fill-ups" or "Trajets opt-ins without OBD2".
  group('profile bundles satisfy Conso surface invariants', () {
    test('no bundle has obd2TripRecording without manualConsumption + '
        'showConsumptionTab', () {
      for (final entry in appProfileBundles.entries) {
        final bundle = entry.value;
        if (bundle.contains(Feature.obd2TripRecording)) {
          expect(bundle, contains(Feature.manualConsumption),
              reason:
                  '${entry.key.name}: obd2TripRecording implies manualConsumption');
          expect(bundle, contains(Feature.showConsumptionTab),
              reason:
                  '${entry.key.name}: obd2TripRecording implies showConsumptionTab');
        }
      }
    });

    test('no bundle has Trajets-tier opt-ins (autoRecord, gpsTripPath, '
        'hapticEcoCoach, glideCoach) without obd2TripRecording', () {
      const trajetsTierFlags = {
        Feature.autoRecord,
        Feature.gpsTripPath,
        Feature.hapticEcoCoach,
        Feature.glideCoach,
      };
      for (final entry in appProfileBundles.entries) {
        final bundle = entry.value;
        for (final flag in trajetsTierFlags) {
          if (bundle.contains(flag)) {
            expect(bundle, contains(Feature.obd2TripRecording),
                reason:
                    '${entry.key.name}: ${flag.name} requires obd2TripRecording');
          }
        }
      }
    });
  });
}
