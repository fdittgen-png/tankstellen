import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_distance_source.dart';

void main() {
  group('trip distance source constants', () {
    // These constants are persisted on TripSummary.distanceSource and
    // compared via `==` by downstream consumers (eco-analytics,
    // fill-up flow, trip_recording_controller). A silent rename would
    // skew historical data — the string values are load-bearing.

    test('kDistanceSourceReal == "real"', () {
      expect(kDistanceSourceReal, 'real');
    });

    test('kDistanceSourceVirtual == "virtual"', () {
      expect(kDistanceSourceVirtual, 'virtual');
    });

    test('the two source tags are distinct', () {
      expect(kDistanceSourceReal, isNot(equals(kDistanceSourceVirtual)));
    });

    test('kVirtualOdometerSampleCap == 60000 (~3.3h @ 5 Hz)', () {
      expect(kVirtualOdometerSampleCap, 60000);
    });
  });
}
