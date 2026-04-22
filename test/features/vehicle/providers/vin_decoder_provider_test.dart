import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/vin_decoder.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';
import 'package:tankstellen/features/vehicle/providers/vin_decoder_provider.dart';

/// Unit tests for [decodedVinProvider] (#812 phase 2).
void main() {
  group('decodedVinProvider', () {
    test('returns null for an empty VIN without calling the decoder', () async {
      final container = ProviderContainer(
        overrides: [
          vinDecoderProvider.overrideWithValue(_ThrowingDecoder()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(decodedVinProvider('').future);
      expect(result, isNull);
    });

    test('delegates to VinDecoder.decode for a non-empty VIN', () async {
      final decoder = _StubDecoder(
        (vin) => VinData(
          vin: vin,
          make: 'Peugeot',
          source: VinDataSource.wmiOffline,
        ),
      );
      final container = ProviderContainer(
        overrides: [vinDecoderProvider.overrideWithValue(decoder)],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(decodedVinProvider('VF38HKFVZ6R123456').future);

      expect(result, isNotNull);
      expect(result!.make, 'Peugeot');
      expect(result.source, VinDataSource.wmiOffline);
      expect(decoder.calls, ['VF38HKFVZ6R123456']);
    });

    test('reads from cache on the second call with the same VIN', () async {
      final decoder = _StubDecoder(
        (vin) => VinData(vin: vin, source: VinDataSource.wmiOffline),
      );
      final container = ProviderContainer(
        overrides: [vinDecoderProvider.overrideWithValue(decoder)],
      );
      addTearDown(container.dispose);

      await container.read(decodedVinProvider('VF36B8HZL8R123456').future);
      await container.read(decodedVinProvider('VF36B8HZL8R123456').future);

      expect(
        decoder.calls,
        ['VF36B8HZL8R123456'],
        reason: 'The second read should hit the keep-alive family cache',
      );
    });
  });
}

class _StubDecoder implements VinDecoder {
  final VinData Function(String) _fn;
  final List<String> calls = [];

  _StubDecoder(this._fn);

  @override
  Future<VinData?> decode(String vin) async {
    calls.add(vin);
    return _fn(vin);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _ThrowingDecoder implements VinDecoder {
  @override
  Future<VinData?> decode(String vin) =>
      throw StateError('decoder should not be called');

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
