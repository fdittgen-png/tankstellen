// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/obd2_trip_features.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';

void main() {
  test(
    '107-style sparse trims export actual values and capture denominator',
    () {
      final samples = List.generate(
        1075,
        (i) => TripSample(
          timestamp: DateTime.utc(2026, 11, 1).add(Duration(seconds: i)),
          speedKmh: 58,
          rpm: 2137,
          coolantTempC: 84,
          mapKpa: 35,
          iatC: 25,
          timingAdvanceDeg: 12,
          stft: i < 223 ? 3.125 : null,
          ltft: i < 223 ? 10.15625 : null,
          fuelRateLPerHour: i < 272 ? 4.5 : null,
          fuelSource: i < 272 ? 'speedDensity' : null,
        ),
      );
      final json = Obd2TripFeatures.fromSamples(samples)!.toJson();
      expect(json['fuelSource'], 'estimated');
      final health = json['healthSignals'] as Map;
      expect(health['stftBank1Pct'], containsPair('count', 223));
      expect(health['stftBank1Pct'], containsPair('coverage', 0.207));
      expect(health['ltftBank1Pct'], containsPair('mean', 10.156));
      final warm = health['warmPairedFuelTrim'] as Map;
      expect(warm['totalPct'], containsPair('mean', 13.281));
      expect(health['measuredLambda'], containsPair('mean', null));
      expect(health['intakeAirTempC'], containsPair('mean', 25.0));
    },
  );

  test('cold/unpaired trims do not fabricate a warm paired correction', () {
    final health = Obd2TripFeatures.fromSamples([
      TripSample(
        timestamp: DateTime.utc(2026),
        speedKmh: 0,
        rpm: 800,
        coolantTempC: 30,
        stft: 25,
        ltft: 25,
      ),
      TripSample(
        timestamp: DateTime.utc(2026, 1, 2),
        speedKmh: 30,
        rpm: 1800,
        coolantTempC: 84,
        stft: 10,
      ),
    ])!.healthSignals;
    expect(
      (health['warmPairedFuelTrim'] as Map)['totalPct'],
      containsPair('count', 0),
    );
  });

  test('direct, derived, mixed and unknown legacy fuel stay distinct', () {
    TripSample sample(String? tag) => TripSample(
      timestamp: DateTime.utc(2026),
      speedKmh: 50,
      rpm: 2000,
      fuelRateLPerHour: 4,
      fuelSource: tag,
    );
    expect(
      Obd2TripFeatures.fromSamples([sample('pid5E')])!.fuelSource,
      Obd2FuelSource.measured,
    );
    expect(
      Obd2TripFeatures.fromSamples([sample('maf')])!.fuelSource,
      Obd2FuelSource.estimated,
    );
    expect(
      Obd2TripFeatures.fromSamples([
        sample('pid5E'),
        sample('maf'),
      ])!.fuelSource,
      Obd2FuelSource.mixed,
    );
    expect(
      Obd2TripFeatures.fromSamples([sample(null)])!.fuelSource,
      Obd2FuelSource.unknown,
    );
  });
}
