import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_override_registry.dart';

/// A minimal [AssetBundle] that serves one asset from memory. Used to
/// exercise [ReceiptOverrideRegistry.load] without depending on
/// `rootBundle` (which is only wired up in real Flutter app contexts).
class _InMemoryBundle extends CachingAssetBundle {
  _InMemoryBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) {
      throw FlutterError('asset $key not in test bundle');
    }
    final bytes = Uint8List.fromList(value.codeUnits);
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _assets[key];
    if (value == null) {
      throw FlutterError('asset $key not in test bundle');
    }
    return value;
  }
}

void main() {
  group('ReceiptOverrideRegistry', () {
    test('fromJsonString — valid map populates entries', () {
      const json = '''
      {
        "station-123": {
          "liters": {"pattern": "VOL_FIXED\\\\s*(\\\\d+[.,]\\\\d+)", "group": 1},
          "totalCost": {"pattern": "TTL\\\\s*(\\\\d+[.,]\\\\d+)", "group": 1}
        }
      }
      ''';

      final registry = ReceiptOverrideRegistry.fromJsonString(json);

      expect(registry.entryCount, 1);
      final spec = registry.lookup('station-123');
      expect(spec, isNotNull);
      expect(spec!.liters, isNotNull);
      expect(spec.totalCost, isNotNull);
      expect(spec.pricePerLiter, isNull);
    });

    test('lookup — returns null for unknown stationId', () {
      final registry = ReceiptOverrideRegistry.fromJsonString('{}');
      expect(registry.lookup('no-such-station'), isNull);
    });

    test('lookup — returns null for empty spec', () {
      // All fields null → effectively no override. Should be treated as
      // "no override registered" so callers don't waste a branch on it.
      const json = '{"empty-station": {}}';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      expect(registry.lookup('empty-station'), isNull);
    });

    test('malformed top-level JSON — falls back to empty', () {
      final registry = ReceiptOverrideRegistry.fromJsonString('this is not json');
      expect(registry.entryCount, 0);
      expect(registry.lookup('anything'), isNull);
    });

    test('top-level is array — falls back to empty (must be object)', () {
      final registry =
          ReceiptOverrideRegistry.fromJsonString('[{"foo": "bar"}]');
      expect(registry.entryCount, 0);
    });

    test('malformed field entry — other fields still survive', () {
      // `liters` is nonsense; `totalCost` is fine. The spec should be
      // registered with only totalCost populated — no crash.
      const json = '''
      {
        "station-partial": {
          "liters": "not-an-object",
          "totalCost": {"pattern": "TTL\\\\s*(\\\\d+[.,]\\\\d+)", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      final spec = registry.lookup('station-partial');
      expect(spec, isNotNull);
      expect(spec!.liters, isNull);
      expect(spec.totalCost, isNotNull);
    });

    test('invalid regex pattern — field is dropped', () {
      // Unclosed group: `(` without `)` → RegExp throws at compile time.
      const json = '''
      {
        "station-badregex": {
          "liters": {"pattern": "(\\\\d+", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      // The only field was invalid → spec is empty → lookup returns null.
      expect(registry.lookup('station-badregex'), isNull);
    });

    test('non-string key — entry is skipped', () {
      // JSON only allows string keys at the top level, so this is
      // really a sanity check on the runtime guard; construct the map
      // directly via fromJsonString with a numeric-looking key still
      // gets decoded as a string, so we verify the happy path here.
      const json = '{"42": {"liters": {"pattern": "(\\\\d+)", "group": 1}}}';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      expect(registry.lookup('42'), isNotNull);
    });

    test('load() — reads from asset bundle', () async {
      const json = '''
      {
        "station-from-asset": {
          "totalCost": {"pattern": "TTL\\\\s*(\\\\d+)", "group": 1}
        }
      }
      ''';
      final bundle = _InMemoryBundle({'test/overrides.json': json});
      final registry = ReceiptOverrideRegistry(
        assetPath: 'test/overrides.json',
        bundle: bundle,
      );

      await registry.load();

      expect(registry.lookup('station-from-asset'), isNotNull);
    });

    test('load() — missing asset falls back without crashing', () async {
      final bundle = _InMemoryBundle(const {});
      final registry = ReceiptOverrideRegistry(
        assetPath: 'missing.json',
        bundle: bundle,
      );

      await registry.load();

      expect(registry.entryCount, 0);
      expect(registry.lookup('anything'), isNull);
    });

    test('load() — malformed JSON falls back without crashing', () async {
      final bundle = _InMemoryBundle({'bad.json': '{{{ not json'});
      final registry = ReceiptOverrideRegistry(
        assetPath: 'bad.json',
        bundle: bundle,
      );

      await registry.load();

      expect(registry.entryCount, 0);
    });

    test('load() — is idempotent (second call is a no-op)', () async {
      const json = '{"s": {"liters": {"pattern": "(\\\\d+)", "group": 1}}}';
      final bundle = _InMemoryBundle({'o.json': json});
      final registry =
          ReceiptOverrideRegistry(assetPath: 'o.json', bundle: bundle);

      await registry.load();
      await registry.load();

      expect(registry.entryCount, 1);
    });
  });

  group('OverrideFieldSpec', () {
    test('extract — captures the nominated group', () {
      final spec = OverrideFieldSpec.fromJson(const <String, Object>{
        'pattern': r'LITRES\s+(\d+[.,]\d+)',
        'group': 1,
      });
      expect(spec, isNotNull);
      expect(spec!.extract('LITRES 42,35'), '42,35');
    });

    test('extract — returns null when regex does not match', () {
      final spec = OverrideFieldSpec.fromJson(const <String, Object>{
        'pattern': r'LITRES\s+(\d+[.,]\d+)',
        'group': 1,
      });
      expect(spec!.extract('totally unrelated text'), isNull);
    });

    test('fromJson — rejects missing group', () {
      final spec = OverrideFieldSpec.fromJson(const <String, Object>{
        'pattern': 'x',
      });
      expect(spec, isNull);
    });

    test('fromJson — rejects empty pattern', () {
      final spec = OverrideFieldSpec.fromJson(const <String, Object>{
        'pattern': '',
        'group': 1,
      });
      expect(spec, isNull);
    });
  });
}
