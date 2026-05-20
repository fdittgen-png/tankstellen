import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_header.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('StationBrandHeader', () {
    testWidgets(
        'renders real brand as headline and street + postal/place as '
        'subtitle (#1996 — body Address section was dropped, so the '
        'header carries the full address)', (tester) async {
      await pumpApp(
        tester,
        const StationBrandHeader(station: testStation),
      );

      // Real brand renders as headline (STAR); the subtitle now also
      // carries postal code + place so the user keeps the city info
      // even though the dedicated body Address block is gone.
      expect(find.text('STAR'), findsOneWidget);
      expect(find.textContaining('Hauptstr.'), findsAtLeast(1));
      expect(find.textContaining('Berlin'), findsAtLeast(1),
          reason: 'place must still surface in the subtitle');
    });

    testWidgets('shows "Independent station" subtitle for independent sentinel',
        (tester) async {
      const independent = Station(
        id: 's-indep',
        name: 'Independent',
        brand: BrandRegistry.independentLabel,
        street: 'Some Street',
        houseNumber: '1',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.40,
        dist: 1.0,
        isOpen: true,
      );

      await pumpApp(
        tester,
        const StationBrandHeader(station: independent),
      );

      // Independent stations fall back to street as headline and expose
      // the localised "Independent station" subtitle.
      expect(find.text('Some Street'), findsOneWidget);
      expect(find.text('Independent station'), findsOneWidget);
    });
  });
}
