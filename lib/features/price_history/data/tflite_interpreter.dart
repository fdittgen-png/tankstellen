import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

/// Thin abstraction over `tflite_flutter`'s [tfl.Interpreter]. Created
/// for #1117 phase 2 so tests can inject a fake without loading the
/// native FFI plugin and without needing a real `.tflite` artifact on
/// disk.
///
/// Production code uses [TfliteFlutterInterpreter] which delegates to
/// the real package. Tests use the in-package `FakeTfliteInterpreter`
/// declared alongside the test file.
///
/// The contract is intentionally tiny — `run(input, output)` and
/// `close()` cover the inference path used by [TflitePricePredictor].
/// Anything richer (multiple inputs/outputs, delegate selection,
/// quantisation metadata) waits until a real model lands and we know
/// what we actually need.
abstract class TfliteInterpreter {
  /// Runs inference. [input] is the populated input tensor (typically
  /// `List<List<double>>` of shape `[1, N]`); [output] is a pre-allocated
  /// container the implementation fills (typically
  /// `List<List<double>>` of shape `[1, 1]`).
  ///
  /// Implementations MUST NOT throw on shape mismatch — they should
  /// `debugPrint` the diagnostic and leave [output] untouched. The
  /// caller treats unchanged output as "no prediction".
  void run(Object input, Object output);

  /// Releases the native interpreter handle. Calling [run] after
  /// [close] is undefined behaviour and the implementation is expected
  /// to either no-op or `debugPrint` and return.
  void close();
}

/// Production adapter that delegates to `tflite_flutter`'s
/// [tfl.Interpreter]. Constructed via [fromBuffer] so the predictor
/// can read the asset bytes itself and own the I/O failure path.
class TfliteFlutterInterpreter implements TfliteInterpreter {
  TfliteFlutterInterpreter._(this._delegate);

  final tfl.Interpreter _delegate;

  /// Builds an interpreter from an in-memory `.tflite` byte buffer.
  /// Returns `null` when the bytes do not parse as a valid TFLite
  /// FlatBuffer — under-trigger preference, the caller falls back to
  /// the heuristic predictor.
  static TfliteFlutterInterpreter? fromBuffer(List<int> bytes) {
    try {
      // `Interpreter.fromBuffer` accepts a `Uint8List`; coerce defensively
      // so a plain `List<int>` from `rootBundle.load` still works.
      final buf = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final interpreter = tfl.Interpreter.fromBuffer(buf);
      return TfliteFlutterInterpreter._(interpreter);
    } catch (e, st) {
      debugPrint(
        'TfliteFlutterInterpreter.fromBuffer: failed to parse model bytes: $e\n$st',
      );
      return null;
    }
  }

  @override
  void run(Object input, Object output) {
    try {
      _delegate.run(input, output);
    } catch (e, st) {
      debugPrint('TfliteFlutterInterpreter.run: inference failed: $e\n$st');
    }
  }

  @override
  void close() {
    try {
      _delegate.close();
    } catch (e, st) {
      debugPrint('TfliteFlutterInterpreter.close: $e\n$st');
    }
  }
}
