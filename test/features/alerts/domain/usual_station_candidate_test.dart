// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/domain/usual_station_candidate.dart';

/// #4154 — what the fill-up history SUGGESTS. Offered, never applied.
void main() {
  ({String? stationId, String? stationName}) fill(String? id, [String? name]) =>
      (stationId: id, stationName: name);

  test('the station with the most fill-ups wins, carrying its name', () {
    final c = usualStationCandidate([
      fill('de-a', 'ARAL'),
      fill('de-b', 'Shell'),
      fill('de-a', 'ARAL'),
      fill('de-a'),
      fill('de-b', 'Shell'),
    ]);
    expect(c?.stationId, 'de-a');
    expect(c?.stationName, 'ARAL',
        reason: 'a later row without a name must not erase the name an '
            'earlier one carried');
    expect(c?.fills, 3, reason: 'the evidence the user confirms against');
  });

  test('too thin a history suggests NOTHING', () {
    expect(usualStationCandidate([fill('de-a'), fill('de-a')]), isNull,
        reason: 'two could be a holiday; $kUsualStationMinFills is a habit');
    expect(usualStationCandidate(const []), isNull);
  });

  test('a lower floor is honoured when the caller sets one', () {
    expect(
        usualStationCandidate([fill('de-a'), fill('de-a')], minFills: 2)
            ?.stationId,
        'de-a');
  });

  test('fill-ups with no station are ignored, not counted as one station',
      () {
    expect(
        usualStationCandidate([
          fill(null),
          fill(''),
          fill(null),
          fill('de-a'),
          fill('de-a'),
          fill('de-a'),
        ])?.stationId,
        'de-a');
  });

  test('a tie resolves the same way every time', () {
    final rows = [
      fill('de-b'),
      fill('de-b'),
      fill('de-b'),
      fill('de-a'),
      fill('de-a'),
      fill('de-a'),
    ];
    final first = usualStationCandidate(rows)!.stationId;
    expect(first, 'de-a', reason: 'lowest id breaks the tie');
    expect(usualStationCandidate(rows.reversed.toList())!.stationId, first,
        reason: 'a suggestion that moves with input order is noise');
  });
}
