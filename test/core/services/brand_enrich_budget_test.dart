// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/brand_enrich_budget.dart';
import 'package:tankstellen/core/services/impl/osm_brand_enricher.dart';

import '../../fakes/fake_hive_storage.dart';

/// #3326 — `enrichWithinBudget` must never gate the caller longer than the
/// budget, and must never throw (a brand-enrichment failure can't break search).
Station _station(String id, {String brand = ''}) => Station(
      id: id,
      name: 'S$id',
      brand: brand,
      street: 'x',
      postCode: '00000',
      place: 'p',
      lat: 48.0,
      lng: 2.0,
      isOpen: true,
    );

class _SlowEnricher extends OsmBrandEnricher {
  _SlowEnricher() : super(FakeHiveStorage());
  @override
  Future<List<Station>> enrich(List<Station> s, {CancelToken? cancelToken}) async {
    await Future<void>.delayed(const Duration(seconds: 5));
    return s.map((e) => e.copyWith(brand: 'LATE')).toList();
  }
}

class _ThrowingEnricher extends OsmBrandEnricher {
  _ThrowingEnricher() : super(FakeHiveStorage());
  @override
  Future<List<Station>> enrich(List<Station> s, {CancelToken? cancelToken}) async {
    throw Exception('enrichment blew up');
  }
}

class _FastEnricher extends OsmBrandEnricher {
  _FastEnricher() : super(FakeHiveStorage());
  @override
  Future<List<Station>> enrich(List<Station> s, {CancelToken? cancelToken}) async {
    return s.map((e) => e.copyWith(brand: 'Esso')).toList();
  }
}

void main() {
  test('null enricher → returns the stations unchanged', () async {
    final stations = [_station('1')];
    expect(await enrichWithinBudget(null, stations, budget: const Duration(seconds: 1)),
        same(stations));
  });

  test('slow enrichment → returns un-enriched within the budget', () async {
    final stations = [_station('1')];
    final sw = Stopwatch()..start();
    final result = await enrichWithinBudget(_SlowEnricher(), stations,
        budget: const Duration(milliseconds: 10));
    sw.stop();
    expect(result.single.brand, '', reason: 'budget elapsed before enrichment');
    expect(sw.elapsed, lessThan(const Duration(milliseconds: 250)));
  });

  test('fast enrichment within budget → returns enriched', () async {
    final result = await enrichWithinBudget(_FastEnricher(), [_station('1')],
        budget: const Duration(seconds: 2));
    expect(result.single.brand, 'Esso');
  });

  test('a throwing enricher is swallowed — completes with the un-enriched '
      'stations, never throws (#2349)', () async {
    final stations = [_station('1')];
    final call = enrichWithinBudget(_ThrowingEnricher(), stations,
        budget: const Duration(seconds: 1));
    await expectLater(call, completes);
    expect((await call).single.brand, '');
  });
}
