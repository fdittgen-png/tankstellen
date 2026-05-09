import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/app_profile.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

/// Pure-domain coverage for the [AppProfile] bundles and the detection
/// helper (#1517). No Hive, no Riverpod — these guard the contract that
/// drives both the wizard's first page and the Settings selector.
void main() {
  group('appProfileBundles', () {
    test('basic only includes the price/discovery flags', () {
      final basic = appProfileBundles[AppProfile.basic]!;
      expect(basic, contains(Feature.showFuel));
      expect(basic, contains(Feature.showElectric));
      expect(basic, contains(Feature.priceAlerts));
      expect(basic, contains(Feature.priceHistory));
      expect(basic, contains(Feature.routePlanning));
      expect(basic, contains(Feature.evCharging));
      // Basic must NOT include the consumption / OBD2 / loyalty stack.
      expect(basic, isNot(contains(Feature.manualConsumption)));
      expect(basic, isNot(contains(Feature.obd2TripRecording)));
      expect(basic, isNot(contains(Feature.gamification)));
      expect(basic, isNot(contains(Feature.loyaltyCards)));
      expect(basic, isNot(contains(Feature.consumptionAnalytics)));
    });

    test('medium adds manualConsumption to basic, no OBD2 stack', () {
      final basic = appProfileBundles[AppProfile.basic]!;
      final medium = appProfileBundles[AppProfile.medium]!;
      // Medium is a superset of Basic.
      for (final f in basic) {
        expect(medium, contains(f),
            reason: 'medium must include every basic flag');
      }
      // Medium adds manualConsumption.
      expect(medium, contains(Feature.manualConsumption));
      // Medium STILL excludes the OBD2 stack — that is the Full tier.
      expect(medium, isNot(contains(Feature.obd2TripRecording)));
      expect(medium, isNot(contains(Feature.autoRecord)));
      expect(medium, isNot(contains(Feature.gamification)));
      expect(medium, isNot(contains(Feature.consumptionAnalytics)));
      expect(medium, isNot(contains(Feature.loyaltyCards)));
    });

    test('full includes the OBD2 stack and loyalty on top of medium', () {
      final medium = appProfileBundles[AppProfile.medium]!;
      final full = appProfileBundles[AppProfile.full]!;
      for (final f in medium) {
        expect(full, contains(f),
            reason: 'full must include every medium flag');
      }
      // Full adds OBD2 + loyalty.
      expect(full, contains(Feature.obd2TripRecording));
      expect(full, contains(Feature.autoRecord));
      expect(full, contains(Feature.gamification));
      expect(full, contains(Feature.consumptionAnalytics));
      expect(full, contains(Feature.showConsumptionTab));
      expect(full, contains(Feature.loyaltyCards));
      // Full does NOT mean "every flag on" — opt-in extras stay off.
      expect(full, isNot(contains(Feature.hapticEcoCoach)));
      expect(full, isNot(contains(Feature.glideCoach)));
      expect(full, isNot(contains(Feature.gpsTripPath)));
      expect(full, isNot(contains(Feature.tankSync)));
      expect(full, isNot(contains(Feature.baselineSync)));
      expect(full, isNot(contains(Feature.unifiedSearchResults)));
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
        Feature.tankSync, // Not in any preset bundle.
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
        Feature.tankSync,
        Feature.glideCoach,
      };
      expect(detectProfileFromFlags(flags), AppProfile.custom);
    });
  });
}
