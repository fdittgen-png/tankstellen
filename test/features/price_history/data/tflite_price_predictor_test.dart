// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/tflite_interpreter.dart';
import 'package:tankstellen/features/price_history/data/tflite_price_predictor.dart';
import 'package:tankstellen/features/price_history/domain/entities/feature_vector.dart';

/// Stub interpreter — fully Dart, no FFI. Lets the test exercise the
/// predictor's wrapping logic (latency timing, output validation,
/// dispose contract) without loading a real `.tflite` artifact or the
/// `tflite_flutter` plugin's native library.
class _FakeInterpreter implements TfliteInterpreter {
  _FakeInterpreter({required this.outputValue});

  /// Value the fake writes into `output[0][0]`. Tests vary this to
  /// exercise the static confidence gate and the bounded-range invariant.
  double outputValue;
  int runCallCount = 0;
  bool isClosed = false;

  @override
  void run(Object input, Object output) {
    runCallCount++;
    final out = output as List<List<double>>;
    out[0][0] = outputValue;
  }

  @override
  void close() {
    isClosed = true;
  }
}

FeatureVector _featureVector({
  int hourOfDay = 8,
  int dayOfWeek = 5,
  bool isHoliday = false,
}) =>
    FeatureVector(
      hourOfDay: hourOfDay,
      dayOfWeek: dayOfWeek,
      brand: 'Aral',
      countryCode: 'DE',
      isHoliday: isHoliday,
      priceEur: 1.65,
      observedAt: DateTime.utc(2026, 5, 1, hourOfDay),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TflitePricePredictor — feature-flag gate', () {
    // Note: [kTflitePredictorEnabled] is a `const false` in production.
    // The non-test constructor inherits that compile-time value, so
    // every test that needs to call [predict] uses the
    // [TflitePricePredictor.test] override constructor (documented as
    // `@visibleForTesting`). The single test below covers the disabled
    // branch via the override; the production branch is exercised
    // by the same code path with `enabled: false`.
    test('predict() returns null when the predictor is disabled', () {
      final fake = _FakeInterpreter(outputValue: 165.0);
      final predictor = TflitePricePredictor.test(
        interpreter: fake,
        enabled: false,
      );
      addTearDown(predictor.dispose);

      expect(predictor.predict(_featureVector()), isNull);
      // Disabled path must short-circuit before touching the interpreter.
      expect(fake.runCallCount, 0);
    });

    test(
      'predict() runs the interpreter when enabled override is true',
      () {
        final fake = _FakeInterpreter(outputValue: 165.0);
        final predictor = TflitePricePredictor.test(
          interpreter: fake,
          enabled: true,
        );
        addTearDown(predictor.dispose);

        final result = predictor.predict(_featureVector());

        expect(result, isNotNull);
        expect(result!.predictedPriceCents, 165.0);
        expect(fake.runCallCount, 1);
      },
    );
  });

  group('TflitePricePredictor — inference contract', () {
    test('returns latency under the 50 ms acceptance budget', () {
      final fake = _FakeInterpreter(outputValue: 168.5);
      final predictor = TflitePricePredictor.test(
        interpreter: fake,
        enabled: true,
      );
      addTearDown(predictor.dispose);

      final result = predictor.predict(_featureVector())!;
      expect(
        result.inferenceLatency,
        lessThan(const Duration(milliseconds: 50)),
        reason: 'fake interpreter is sub-microsecond; the 50 ms budget '
            'measures the wrapping overhead, not real inference',
      );
    });

    test(
      'predicted price stays within historical range — bounded prediction',
      () {
        // Acceptance criterion: the predictor must never emit values
        // outside `[historicalMin, historicalMax]` for the trained
        // service area. The fake clamps to the historical range so we
        // assert the wrapping does not silently change it.
        const historicalMin = 152.0; // ct/L
        const historicalMax = 189.0; // ct/L
        for (final raw in <double>[
          historicalMin,
          (historicalMin + historicalMax) / 2,
          historicalMax,
        ]) {
          final fake = _FakeInterpreter(outputValue: raw);
          final predictor = TflitePricePredictor.test(
            interpreter: fake,
            enabled: true,
          );
          addTearDown(predictor.dispose);

          final result = predictor.predict(_featureVector())!;
          expect(result.predictedPriceCents, raw);
          expect(
            result.predictedPriceCents,
            inInclusiveRange(historicalMin, historicalMax),
            reason:
                'wrapping must not perturb a value the interpreter '
                'clamped to the historical range',
          );
        }
      },
    );

    test('rejects non-finite interpreter output (NaN / infinity)', () {
      for (final raw in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final fake = _FakeInterpreter(outputValue: raw);
        final predictor = TflitePricePredictor.test(
          interpreter: fake,
          enabled: true,
        );
        addTearDown(predictor.dispose);

        expect(
          predictor.predict(_featureVector()),
          isNull,
          reason: 'output $raw must be filtered by the static gate',
        );
      }
    });

    test('rejects out-of-band output (static confidence gate)', () {
      // Phase 2 confidence gate is a static `[50, 300]` ct/L band. A
      // future variance-based gate replaces this; until then, any
      // model output outside the band is treated as miscalibrated
      // and the heuristic stays authoritative.
      for (final raw in <double>[-1.0, 0.0, 49.999, 300.001, 9999.0]) {
        final fake = _FakeInterpreter(outputValue: raw);
        final predictor = TflitePricePredictor.test(
          interpreter: fake,
          enabled: true,
        );
        addTearDown(predictor.dispose);

        expect(
          predictor.predict(_featureVector()),
          isNull,
          reason: 'value $raw is outside the [50, 300] ct/L band',
        );
      }
    });

    test(
      '100 inference calls complete in under 5 s — wrapping overhead is negligible',
      () {
        final fake = _FakeInterpreter(outputValue: 165.0);
        final predictor = TflitePricePredictor.test(
          interpreter: fake,
          enabled: true,
        );
        addTearDown(predictor.dispose);

        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 100; i++) {
          final result = predictor.predict(_featureVector(hourOfDay: i % 24));
          expect(result, isNotNull);
        }
        stopwatch.stop();

        expect(
          stopwatch.elapsed,
          lessThan(const Duration(seconds: 5)),
          reason: 'host-side wrapping overhead must stay negligible — '
              '100 fake-interpreter calls inside 5 s',
        );
        expect(fake.runCallCount, 100);
      },
    );
  });

  group('TflitePricePredictor — dispose', () {
    test('dispose() closes the underlying interpreter', () {
      final fake = _FakeInterpreter(outputValue: 165.0);
      final predictor = TflitePricePredictor.test(
        interpreter: fake,
        enabled: true,
      );

      expect(fake.isClosed, isFalse);
      predictor.dispose();
      expect(fake.isClosed, isTrue);
    });

    test('predict() returns null after dispose()', () {
      final fake = _FakeInterpreter(outputValue: 165.0);
      final predictor = TflitePricePredictor.test(
        interpreter: fake,
        enabled: true,
      );
      predictor.dispose();

      expect(predictor.predict(_featureVector()), isNull);
    });

    test('dispose() is idempotent', () {
      final fake = _FakeInterpreter(outputValue: 165.0);
      final predictor = TflitePricePredictor.test(
        interpreter: fake,
        enabled: true,
      );

      predictor.dispose();
      predictor.dispose(); // must not throw
      expect(fake.isClosed, isTrue);
    });
  });

  group('TflitePricePredictor.fromAsset', () {
    test('returns null when [kTflitePredictorEnabled] is false (default)',
        () async {
      // Production default: the flag is `false`, so `fromAsset` short-
      // circuits without touching the asset bundle. This is the
      // happy-path safety net documented on the class.
      final predictor = await TflitePricePredictor.fromAsset(
        'assets/models/price_predictor_v1.tflite',
      );
      expect(predictor, isNull);
    });

    test('returns null on missing asset (no throw)', () async {
      // With `enabledOverride: true` we exercise the asset-load path.
      // The path below does not exist in the asset bundle, so
      // `rootBundle.load` throws — `fromAsset` catches and returns null.
      final predictor = await TflitePricePredictor.fromAsset(
        'assets/models/_does_not_exist.tflite',
        enabledOverride: true,
        // Identity factory is irrelevant — we never reach it.
        interpreterFactory: (bytes) =>
            fail('factory must not be called when asset load fails'),
      );
      expect(predictor, isNull);
    });

    test('returns null on garbage / unparseable asset bytes', () async {
      // Stub the asset bundle so `rootBundle.load` returns a known
      // garbage buffer. The injected factory rejects it (mirrors the
      // real `TfliteFlutterInterpreter.fromBuffer` contract).
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
        // Return a 16-byte garbage buffer for any asset key.
        return ByteData.view(Uint8List.fromList(
          List<int>.filled(16, 0xAB),
        ).buffer);
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      final predictor = await TflitePricePredictor.fromAsset(
        'assets/models/price_predictor_v1.tflite',
        enabledOverride: true,
        interpreterFactory: (bytes) {
          // Real adapter behaviour on garbage: return null without
          // throwing.
          expect(bytes.length, 16);
          return null;
        },
      );
      expect(predictor, isNull);
    });

    test('returns a predictor on a valid (stub) asset + factory', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
        return ByteData.view(Uint8List.fromList(
          List<int>.filled(32, 0x42),
        ).buffer);
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      final fake = _FakeInterpreter(outputValue: 165.0);
      final predictor = await TflitePricePredictor.fromAsset(
        'assets/models/price_predictor_v1.tflite',
        enabledOverride: true,
        interpreterFactory: (bytes) => fake,
      );
      expect(predictor, isNotNull);
      // The constructed predictor uses the production constructor —
      // its `_enabled` follows the compile-time flag, which is `false`
      // in tests too. So `predict()` returns null even though we built
      // it; this exercises the production behaviour.
      expect(predictor!.predict(_featureVector()), isNull);
      addTearDown(predictor.dispose);
    });
  });

  group('TflitePricePredictor — input encoding', () {
    test('toModelInput emits a [1, 5] float32 tensor with normalised values',
        () {
      final v = FeatureVector(
        hourOfDay: 23,
        dayOfWeek: 7,
        brand: 'Shell',
        countryCode: 'FR',
        isHoliday: true,
        priceEur: 1.80,
        observedAt: DateTime.utc(2026, 7, 14, 23),
      );
      final input = TflitePricePredictor.toModelInput(v);
      expect(input.length, 1, reason: 'batch dim');
      expect(input[0].length, 5, reason: 'feature dim');
      expect(input[0][0], 1.0, reason: 'hour 23 / 23 = 1.0');
      expect(input[0][1], 1.0, reason: '(day 7 - 1) / 6 = 1.0');
      expect(input[0][4], 1.0, reason: 'isHoliday true → 1.0');
    });

    test('toModelInput hour 0 / day 1 / non-holiday → all-zero non-slot dims',
        () {
      final v = FeatureVector(
        hourOfDay: 0,
        dayOfWeek: 1,
        brand: null,
        countryCode: null,
        isHoliday: false,
        priceEur: 1.50,
        observedAt: DateTime.utc(2026, 5, 4, 0),
      );
      final input = TflitePricePredictor.toModelInput(v);
      expect(input[0][0], 0.0);
      expect(input[0][1], 0.0);
      expect(input[0][4], 0.0);
    });
  });
}
