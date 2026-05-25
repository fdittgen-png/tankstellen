// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/tflite_interpreter.dart';

/// In-package fake for [TfliteInterpreter] (epic #1612, child #1631).
///
/// Lets [TfliteInterpreter] consumers be unit-tested without the native
/// `tflite_flutter` FFI plugin or a real `.tflite` artifact. It mirrors
/// the abstract contract: [run] must not throw on a shape mismatch — it
/// leaves `output` untouched — and [run] after [close] is a no-op.
class FakeTfliteInterpreter implements TfliteInterpreter {
  FakeTfliteInterpreter({this.prediction = 1.0, this.simulateShapeMismatch = false});

  /// Value written into `output[0][0]` on a successful [run].
  final double prediction;

  /// When true, [run] behaves like a shape mismatch: it does not write
  /// to `output` (the caller treats unchanged output as "no prediction").
  final bool simulateShapeMismatch;

  int runCalls = 0;
  bool closed = false;

  @override
  void run(Object input, Object output) {
    runCalls++;
    if (closed) {
      // Contract: run-after-close is a no-op.
      debugPrint('FakeTfliteInterpreter.run: called after close — ignored');
      return;
    }
    if (simulateShapeMismatch) return;
    if (output is List && output.isNotEmpty && output.first is List) {
      (output.first as List)[0] = prediction;
    }
  }

  @override
  void close() => closed = true;
}

void main() {
  group('TfliteFlutterInterpreter.fromBuffer — buffer corruption', () {
    test('returns null for an empty byte buffer', () {
      expect(TfliteFlutterInterpreter.fromBuffer(const []), isNull);
    });

    test('returns null for garbage bytes that are not a TFLite FlatBuffer',
        () {
      final garbage = List<int>.generate(64, (i) => (i * 7) % 256);
      expect(TfliteFlutterInterpreter.fromBuffer(garbage), isNull);
    });

    test('returns null rather than throwing — under-trigger fallback', () {
      // The predictor falls back to the heuristic when this is null, so
      // fromBuffer must swallow every parse failure.
      expect(
        () => TfliteFlutterInterpreter.fromBuffer(const [1, 2, 3]),
        returnsNormally,
      );
    });
  });

  group('FakeTfliteInterpreter — contract conformance', () {
    test('run writes the prediction into a well-shaped output tensor', () {
      final interpreter = FakeTfliteInterpreter(prediction: 1.42);
      final output = [
        [0.0],
      ];
      interpreter.run([
        [1.0, 2.0],
      ], output);
      expect(output.first.first, 1.42);
      expect(interpreter.runCalls, 1);
    });

    test('run leaves output untouched on a simulated shape mismatch', () {
      final interpreter = FakeTfliteInterpreter(simulateShapeMismatch: true);
      final output = [
        [0.0],
      ];
      interpreter.run([
        [1.0],
      ], output);
      expect(
        output.first.first,
        0.0,
        reason: 'a shape mismatch must not throw and must not write output',
      );
    });

    test('run after close is a no-op and does not write output', () {
      final interpreter = FakeTfliteInterpreter(prediction: 9.9);
      interpreter.close();
      final output = [
        [0.0],
      ];
      interpreter.run([
        [1.0],
      ], output);
      expect(interpreter.closed, isTrue);
      expect(output.first.first, 0.0);
    });

    test('close is idempotent', () {
      final interpreter = FakeTfliteInterpreter();
      interpreter.close();
      expect(interpreter.close, returnsNormally);
      expect(interpreter.closed, isTrue);
    });
  });
}
