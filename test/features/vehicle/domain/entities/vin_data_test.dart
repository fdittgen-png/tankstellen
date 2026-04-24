import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';

void main() {
  group('VinData.isComplete', () {
    test('returns true when make, model, and displacementL are all set', () {
      const v = VinData(
        vin: 'WVWZZZ1JZXW000001',
        make: 'Volkswagen',
        model: 'Golf',
        displacementL: 1.6,
      );
      expect(v.isComplete, isTrue);
    });

    test('returns false when make is null', () {
      const v = VinData(
        vin: 'WVWZZZ1JZXW000001',
        model: 'Golf',
        displacementL: 1.6,
      );
      expect(v.isComplete, isFalse);
    });

    test('returns false when model is null', () {
      const v = VinData(
        vin: 'WVWZZZ1JZXW000001',
        make: 'Volkswagen',
        displacementL: 1.6,
      );
      expect(v.isComplete, isFalse);
    });

    test('returns false when displacementL is null', () {
      const v = VinData(
        vin: 'WVWZZZ1JZXW000001',
        make: 'Volkswagen',
        model: 'Golf',
      );
      expect(v.isComplete, isFalse);
    });
  });

  group('VinDataSourceJsonConverter.fromJson', () {
    const converter = VinDataSourceJsonConverter();

    test('decodes "vpic" to VinDataSource.vpic', () {
      expect(converter.fromJson('vpic'), VinDataSource.vpic);
    });

    test('decodes "wmiOffline" to VinDataSource.wmiOffline', () {
      expect(converter.fromJson('wmiOffline'), VinDataSource.wmiOffline);
    });

    test('decodes "invalid" to VinDataSource.invalid', () {
      expect(converter.fromJson('invalid'), VinDataSource.invalid);
    });

    test('falls back to invalid on unknown string', () {
      expect(converter.fromJson('definitely-not-a-source'),
          VinDataSource.invalid);
    });

    test('falls back to invalid on empty string', () {
      expect(converter.fromJson(''), VinDataSource.invalid);
    });
  });

  group('VinDataSourceJsonConverter.toJson', () {
    const converter = VinDataSourceJsonConverter();

    test('encodes VinDataSource.vpic to "vpic"', () {
      expect(converter.toJson(VinDataSource.vpic), 'vpic');
    });

    test('encodes VinDataSource.wmiOffline to "wmiOffline"', () {
      expect(converter.toJson(VinDataSource.wmiOffline), 'wmiOffline');
    });

    test('encodes VinDataSource.invalid to "invalid"', () {
      expect(converter.toJson(VinDataSource.invalid), 'invalid');
    });
  });

  group('VinData construction', () {
    test('defaults source to VinDataSource.invalid', () {
      const v = VinData(vin: 'A');
      expect(v.source, VinDataSource.invalid);
      expect(v.vin, 'A');
      expect(v.make, isNull);
      expect(v.model, isNull);
      expect(v.displacementL, isNull);
    });
  });

  group('VinData JSON roundtrip', () {
    test('preserves every field through fromJson/toJson', () {
      const original = VinData(
        vin: '1HGCM82633A004352',
        make: 'Honda',
        model: 'Accord',
        modelYear: 2003,
        displacementL: 2.4,
        cylinderCount: 4,
        fuelTypePrimary: 'Gasoline',
        engineHp: 160,
        gvwrLbs: 4300,
        country: 'United States',
        source: VinDataSource.vpic,
      );

      final json = original.toJson();
      expect(json['vin'], '1HGCM82633A004352');
      expect(json['make'], 'Honda');
      expect(json['model'], 'Accord');
      expect(json['modelYear'], 2003);
      expect(json['displacementL'], 2.4);
      expect(json['cylinderCount'], 4);
      expect(json['fuelTypePrimary'], 'Gasoline');
      expect(json['engineHp'], 160);
      expect(json['gvwrLbs'], 4300);
      expect(json['country'], 'United States');
      // source round-trips through the JsonConverter as the enum name.
      expect(json['source'], 'vpic');

      final restored = VinData.fromJson(json);
      expect(restored, equals(original));
    });

    test('fromJson with unknown source string falls back to invalid', () {
      final json = <String, dynamic>{
        'vin': 'ABCDEFGHIJKLMNOPQ',
        'source': 'sasquatch',
      };
      final restored = VinData.fromJson(json);
      expect(restored.source, VinDataSource.invalid);
      expect(restored.vin, 'ABCDEFGHIJKLMNOPQ');
    });
  });
}
