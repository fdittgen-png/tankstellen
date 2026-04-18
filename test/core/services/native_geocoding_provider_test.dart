import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/native_geocoding_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeGeocodingProvider — metadata', () {
    test('source is nativeGeocoding', () {
      final provider = NativeGeocodingProvider();
      expect(provider.source, ServiceSource.nativeGeocoding);
      expect(provider.source.displayName, 'Device Geocoding');
    });

    test('constructs with default German country name', () {
      final provider = NativeGeocodingProvider();
      expect(provider, isA<NativeGeocodingProvider>());
      expect(provider.source, ServiceSource.nativeGeocoding);
    });

    test('accepts overridden country name', () {
      final provider = NativeGeocodingProvider(countryName: 'France');
      expect(provider.source, ServiceSource.nativeGeocoding);
    });

    test('isAvailable is false on the Windows test host', () {
      // The provider gates all platform calls behind Platform.isAndroid ||
      // Platform.isIOS. On the Windows CI/dev test host both are false, so
      // isAvailable must be false — this pins the desktop short-circuit.
      final provider = NativeGeocodingProvider();
      expect(provider.isAvailable, isFalse);
    });
  });

  group('NativeGeocodingProvider — failure paths', () {
    test('zipCodeToCoordinates wraps platform errors in LocationException',
        () async {
      // Without a registered geocoding plugin, the platform call throws;
      // the provider must translate that into its domain-level
      // LocationException so the fallback chain has a stable contract.
      final provider = NativeGeocodingProvider();
      await expectLater(
        provider.zipCodeToCoordinates('12345'),
        throwsA(isA<LocationException>()),
      );
    });

    test('coordinatesToCountryCode returns null when unavailable', () async {
      // On desktop the !isAvailable guard short-circuits to null so the
      // chain can degrade to the next provider without throwing.
      final provider = NativeGeocodingProvider();
      final code = await provider.coordinatesToCountryCode(48.85, 2.35);
      expect(code, isNull);
    });
  });
}
