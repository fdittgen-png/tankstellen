// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/services/station_open_state.dart';

/// #4179 — one resolution of "is this station open?", and the two
/// opposite defaults it replaced.
void main() {
  DataValue<bool> resolve(String? id, {bool? published, double? lat, double? lng}) =>
      resolveStationOpenState(
          stationId: id, lat: lat, lng: lng, published: published);

  test('a provider that publishes hours, and did, is MEASURED', () {
    expect(resolve('de-abc', published: true), const Measured(true));
    expect(resolve('de-abc', published: false), const Measured(false));
  });

  test('a provider that publishes hours but not for this station', () {
    expect(
        resolve('de-abc'),
        const DataValue<bool>.unknown(
            reason: DataUnknownReason.notPublishedForThisItem),
        reason: 'DE has a schedule for most stations and none for some; '
            'that is a fact about the ROW');
  });

  test('a provider that publishes no hours at all cannot be overridden', () {
    // SI publishes hours as free text — displayable, not evaluable — so
    // its capability says openingHours: false. A row claiming `true`
    // does not change what the provider supports.
    expect(
        resolve('si-abc', published: true),
        const DataValue<bool>.unknown(
            reason: DataUnknownReason.notPublishedByProvider),
        reason: 'a fact about the PROVIDER outranks a stray row value');
  });

  test('an unregistered country is unknown, not assumed', () {
    expect(
        resolve('zz-abc', published: true),
        const DataValue<bool>.unknown(
            reason: DataUnknownReason.notPublishedByProvider));
  });

  test('coordinates are the fallback when the id carries no prefix', () {
    // Berlin. An id with no country prefix still resolves to DE.
    expect(resolve('12345', published: true, lat: 52.52, lng: 13.405),
        const Measured(true));
  });

  test('no id and no coordinates is unknown rather than a guess', () {
    expect(resolve(null, published: true).isKnown, isFalse);
  });

  group('the two defaults this replaced', () {
    test('neither true nor false survives an unknown', () {
      // The bug: nearest_widget_data_builder read `?? true` and
      // home_widget_service read `?? false`, so the same station was
      // open or closed depending on which widget was on the home screen.
      final unknown = resolve('si-abc');
      expect(unknown.valueOrNull, isNull);
      expect(unknown.isKnown, isFalse);
      expect(unknown.map((open) => !open).valueOrNull, isNull,
          reason: 'map must not be able to launder it into a bool either');
    });
  });
}
