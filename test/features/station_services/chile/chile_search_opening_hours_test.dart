// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2780 (Epic #2776 D4) — Chile is a polled-API source: a cache-hit search
// rehydrates the list through the codec. This guards the full path the CI
// adapter-unit test skipped: the REAL CNE search parse must populate the
// structured Station.openingHours AND it must survive the search-list codec
// round-trip (serializeStationList -> deserializeStationList), or a tapped CL
// station renders empty hours on the dominant repeat path.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/chile/chile_response_parser.dart';

void main() {
  Map<String, dynamic> cneRow(String horario) => <String, dynamic>{
        'codigo': '12345',
        'distribuidor': <String, dynamic>{'nombre': 'Copec'},
        'nombre_fantasia': 'Copec Centro',
        'direccion_calle': 'Av. Libertador',
        'direccion_numero': '100',
        'nombre_comuna': 'Santiago',
        'ubicacion': <String, dynamic>{'latitud': -33.45, 'longitud': -70.66},
        'precios': <String, dynamic>{'gasolina_93': 1290.0, 'diesel': 1150.0},
        'horario_atencion': horario,
      };

  test('CL search parse populates structured hours + survives the codec (#2780)',
      () {
    final stations = parseChileStationsResponse(
      <String, dynamic>{
        'data': [cneRow('24_horas')]
      },
      fromLat: -33.45,
      fromLng: -70.66,
    );
    final s = stations.single;
    expect(s.openingHours, isNotNull,
        reason: 'the REAL CNE search parse must populate structured hours');

    final restored =
        deserializeStationList(serializeStationList([s]))!.single;
    expect(restored.openingHours, isNotNull,
        reason: 'structured hours must survive the cache round-trip (#2777)');
    expect(restored.openingHours!.availability,
        isNot(OpeningHoursAvailability.notProvided));
    // 24/7 should resolve to an open-24h schedule, not collapse to no-data.
    expect(
      restored.openingHours!.days.any((d) => d.state == DayState.open24h),
      isTrue,
    );
  });
}
