import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/csv_exporter.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('ConsumptionCsvExporter', () {
    test('empty list returns header row only', () {
      final csv = ConsumptionCsvExporter.toCsv([]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 1);
      expect(lines.first,
          'Date,Station,Fuel Type,Liters,Price per Liter,Total Cost,Odometer (km),CO2 (kg),Notes');
    });

    test('headers match the spec from issue #583', () {
      expect(ConsumptionCsvExporter.headers, [
        'Date',
        'Station',
        'Fuel Type',
        'Liters',
        'Price per Liter',
        'Total Cost',
        'Odometer (km)',
        'CO2 (kg)',
        'Notes',
      ]);
    });

    test('single fill-up renders all fields', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 15, 10, 30, 0),
        liters: 45.12,
        totalCost: 78.45,
        odometerKm: 12345.6,
        fuelType: FuelType.diesel,
        stationName: 'Total Castelnau',
      );

      final csv = ConsumptionCsvExporter.toCsv([fillUp]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 2);

      final data = lines[1];
      expect(data, contains('2026-04-15 10:30:00'));
      expect(data, contains('Total Castelnau'));
      expect(data, contains('diesel'));
      expect(data, contains('45.120'));
      expect(data, contains('78.45'));
      expect(data, contains('12345.6'));
    });

    test('decimal formatting uses period (Excel/LibreOffice compatible)', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 1, 1),
        liters: 42.5,
        totalCost: 65.25,
        odometerKm: 10000,
        fuelType: FuelType.e10,
      );

      final csv = ConsumptionCsvExporter.toCsv([fillUp]);
      expect(csv.contains(','), isTrue);
      expect(csv.contains('42.500'), isTrue,
          reason: 'Liters formatted with 3 decimals and period separator');
      expect(csv.contains('65.25'), isTrue,
          reason: 'Total cost with 2 decimals');
    });

    test('rows are sorted oldest-first', () {
      final newer = FillUp(
        id: '1',
        date: DateTime.utc(2026, 4, 10),
        liters: 40,
        totalCost: 60,
        odometerKm: 100,
        fuelType: FuelType.e10,
      );
      final older = FillUp(
        id: '2',
        date: DateTime.utc(2026, 1, 1),
        liters: 40,
        totalCost: 60,
        odometerKm: 50,
        fuelType: FuelType.e10,
      );

      final csv = ConsumptionCsvExporter.toCsv([newer, older]);
      final lines = csv.trim().split('\n');
      expect(lines[1], contains('2026-01-01'));
      expect(lines[2], contains('2026-04-10'));
    });

    test('commas in station name are quoted per RFC 4180', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 1, 1),
        liters: 40,
        totalCost: 60,
        odometerKm: 100,
        fuelType: FuelType.e10,
        stationName: 'Total, Station A',
      );

      final csv = ConsumptionCsvExporter.toCsv([fillUp]);
      expect(csv, contains('"Total, Station A"'));
    });

    test('double quotes in fields are escaped by doubling', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 1, 1),
        liters: 40,
        totalCost: 60,
        odometerKm: 100,
        fuelType: FuelType.e10,
        stationName: 'Bob\'s "Super" Gas',
      );

      final csv = ConsumptionCsvExporter.toCsv([fillUp]);
      expect(csv, contains('"Bob\'s ""Super"" Gas"'));
    });

    test('newlines in notes are quoted', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 1, 1),
        liters: 40,
        totalCost: 60,
        odometerKm: 100,
        fuelType: FuelType.e10,
        notes: 'line1\nline2',
      );

      final csv = ConsumptionCsvExporter.toCsv([fillUp]);
      expect(csv, contains('"line1\nline2"'));
    });

    test('missing optional fields render as empty', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 1, 1, 12),
        liters: 40,
        totalCost: 60,
        odometerKm: 100,
        fuelType: FuelType.e10,
      );

      final csv = ConsumptionCsvExporter.toCsv([fillUp]);
      final lines = csv.trim().split('\n');
      // station and notes empty → two empty fields in the row
      final fields = lines[1].split(',');
      expect(fields.length, ConsumptionCsvExporter.headers.length);
      expect(fields[1], ''); // Station
      expect(fields.last, ''); // Notes
    });

    test('CO2 column uses 2 decimals', () {
      final fillUp = FillUp(
        id: '1',
        date: DateTime.utc(2026, 1, 1),
        liters: 50,
        totalCost: 80,
        odometerKm: 100,
        fuelType: FuelType.diesel, // has CO2 factor
      );

      final csv = ConsumptionCsvExporter.toCsv([fillUp]);
      final fields = csv.trim().split('\n')[1].split(',');
      // 8th column (index 7) is CO2
      final co2 = fields[7];
      expect(RegExp(r'^\d+\.\d{2}$').hasMatch(co2), isTrue,
          reason: 'CO2 field should have exactly 2 decimals: got "$co2"');
    });
  });
}
