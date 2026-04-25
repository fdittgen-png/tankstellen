import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_station_sheet.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../../helpers/pump_app.dart';

/// Test fake for UrlLauncherPlatform that records every launchUrl call
/// without touching the real platform channel. Reading `launchedUrls` after
/// a tap lets us assert the geo: URI the sheet built without depending on
/// emulator-only intent resolution.
///
/// Mixes in [MockPlatformInterfaceMixin] so [UrlLauncherPlatform.instance]'s
/// verify-token guard accepts the assignment in test builds.
class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> launchedUrls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }
}

const _drivingStation = Station(
  id: 'sheet-test-shell',
  name: 'Shell Tankstelle',
  brand: 'Shell',
  street: 'Hauptstr.',
  houseNumber: '12',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.405,
  dist: 1.5,
  e5: 1.859,
  e10: 1.799,
  diesel: 1.659,
  isOpen: true,
);

const _stationNoPrice = Station(
  id: 'sheet-test-noprice',
  name: 'No Price Station',
  brand: 'Aral',
  street: 'Schmalweg',
  postCode: '10117',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.405,
  dist: 0.5,
  isOpen: true,
);

void main() {
  setUpAll(() {
    // The driving sheet builds prices and distances via the active country
    // formatters. Pin a known country so assertions can compare against
    // PriceFormatter / UnitFormatter outputs deterministically.
    PriceFormatter.setCountry('DE');
  });

  group('DrivingStationSheet', () {
    testWidgets('renders the brand as the headline', (tester) async {
      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: _drivingStation,
          fuelType: FuelType.e10,
        ),
      );

      expect(find.text('Shell'), findsOneWidget);
    });

    testWidgets('renders the formatted price for the requested fuel type',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: _drivingStation,
          fuelType: FuelType.e10,
        ),
      );

      // Match what PriceFormatter actually produces under DE locale so the
      // assertion is robust to comma-vs-dot decimal separators.
      expect(find.text(PriceFormatter.formatPrice(1.799)), findsOneWidget);
    });

    testWidgets('different fuel types pull different prices', (tester) async {
      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: _drivingStation,
          fuelType: FuelType.diesel,
        ),
      );

      expect(find.text(PriceFormatter.formatPrice(1.659)), findsOneWidget);
      // E10 price must NOT be visible when the user asked for diesel — this
      // is what guards against a regression where the sheet shows the wrong
      // pump's number.
      expect(find.text(PriceFormatter.formatPrice(1.799)), findsNothing);
    });

    testWidgets('renders "--" fallback when the station has no price for fuel',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: _stationNoPrice,
          fuelType: FuelType.e10,
        ),
      );

      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('renders the formatted distance', (tester) async {
      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: _drivingStation,
          fuelType: FuelType.e10,
        ),
      );

      expect(find.text(UnitFormatter.formatDistance(1.5)), findsOneWidget);
    });

    testWidgets('Navigate button is present and meets the 72dp tap target',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: _drivingStation,
          fuelType: FuelType.e10,
        ),
      );

      // The button itself sits inside a fixed-height SizedBox; assert the
      // 72dp design contract (the safety story of driving mode rests on
      // this — anything smaller fails Android tap-target guidelines for
      // glove-on-wheel use).
      final sized = tester.widgetList<SizedBox>(find.byType(SizedBox)).firstWhere(
            (w) => w.height == 72,
            orElse: () => throw TestFailure(
              'No 72dp-tall SizedBox wrapping the Navigate button',
            ),
          );
      expect(sized.height, 72);
      expect(sized.width, double.infinity);

      // The button must be tappable without throwing — even when no real
      // url_launcher platform is registered we expect the press to be
      // accepted (we install a fake further down to assert URI shape).
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsOneWidget);

      // Whole-suite tap-target audit lives in
      // test/accessibility/icon_button_tooltip_coverage_test.dart; this
      // single-widget assertion catches a regression that would change
      // the SizedBox height before the suite-level scan picks it up.
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Navigate launches a geo: URI for the station',
        (tester) async {
      final fake = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fake;

      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: _drivingStation,
          fuelType: FuelType.e10,
        ),
      );

      // Navigate button uses an icon; tapping the FilledButton itself
      // exercises the same _launchNavigation path the real UI runs.
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(fake.launchedUrls, isNotEmpty);
      final launched = fake.launchedUrls.single;
      expect(launched, startsWith('geo:'));
      expect(launched, contains('52.52'));
      expect(launched, contains('13.405'));
      // The brand becomes the label encoded into the geo: URI's `q=` arg.
      expect(launched, contains(Uri.encodeComponent('Shell')));
    });
  });
}
