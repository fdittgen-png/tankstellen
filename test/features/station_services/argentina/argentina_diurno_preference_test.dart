// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3196 (AR) — prefer tipohorario=Diurno rows in the merge. The open-data
// CSV publishes separate Diurno (daytime) and Nocturno rows per product;
// the first-wins merge used to keep whichever row the CSV listed first.
// The AR endpoint is network-blocked from this environment, so the payload
// is the existing synthetic CSV shape minimally extended with a
// nocturno-BEFORE-diurno ordering (col 11 = tipohorario, mirroring the real
// datos.energia.gob.ar column layout the parser already indexes).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/station_services/argentina/argentina_station_service.dart';

class _CsvAdapter implements HttpClientAdapter {
  _CsvAdapter(this.body);
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, 200, headers: {
        Headers.contentTypeHeader: ['text/csv'],
      });

  @override
  void close({bool force = false}) {}
}

// Real column layout: …,empresa(3),direccion(4),localidad(5),provincia(6),
// …,producto(9),idtipohorario(10),tipohorario(11),precio(12),
// fecha_vigencia(13),…,bandera(15),latitud(16),longitud(17),…
const _header =
    'indice_tiempo,idempresa,cuit,empresa,direccion,localidad,provincia,'
    'region,idproducto,producto,idtipohorario,tipohorario,precio,'
    'fecha_vigencia,idempresabandera,empresabandera,latitud,longitud,geojson';

String _row({
  required String producto,
  required String tipoHorario,
  required double precio,
}) =>
    '2026-06,1,30-1,YPF,AV. RIVADAVIA 5000,CABALLITO,Buenos Aires,Centro,'
    '2,$producto,1,$tipoHorario,$precio,2026-06-01T00:00:00,1,YPF,'
    '-34.6200,-58.4300,geo';

void main() {
  test(
      'a Nocturno row listed BEFORE the Diurno row does not win the merge '
      '(#3196)', () async {
    final csv = [
      _header,
      // Nocturno first — the ordering that used to poison the merge.
      _row(
          producto: 'Nafta (súper) entre 92 y 95 Ron',
          tipoHorario: 'Nocturno',
          precio: 900.0),
      _row(
          producto: 'Nafta (súper) entre 92 y 95 Ron',
          tipoHorario: 'Diurno',
          precio: 850.0),
      _row(producto: 'Gas Oil Grado 2', tipoHorario: 'Nocturno', precio: 880.0),
      _row(producto: 'Gas Oil Grado 2', tipoHorario: 'Diurno', precio: 830.0),
    ].join('\n');

    final dio = Dio(BaseOptions(responseType: ResponseType.plain))
      ..httpClientAdapter = _CsvAdapter(csv);
    final service = ArgentinaStationService.withDio(dio);
    final result = await service.searchStations(
      const SearchParams(lat: -34.62, lng: -58.43, radiusKm: 10),
    );

    expect(result.data, hasLength(1));
    final s = result.data.single;
    expect(s.e5, closeTo(850.0, 0.01),
        reason: 'the Diurno (daytime) pump price must win the merge');
    expect(s.diesel, closeTo(830.0, 0.01));
  });

  test('a diurno-only product still merges normally', () async {
    final csv = [
      _header,
      _row(
          producto: 'Nafta (premium) de más de 95 Ron',
          tipoHorario: 'Diurno',
          precio: 990.0),
    ].join('\n');

    final dio = Dio(BaseOptions(responseType: ResponseType.plain))
      ..httpClientAdapter = _CsvAdapter(csv);
    final service = ArgentinaStationService.withDio(dio);
    final result = await service.searchStations(
      const SearchParams(lat: -34.62, lng: -58.43, radiusKm: 10),
    );

    expect(result.data, hasLength(1));
    expect(result.data.single.e98, closeTo(990.0, 0.01));
  });
}
