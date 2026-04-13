import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tolerant golden file comparator that allows small pixel differences
/// caused by cross-platform font rendering (Windows vs Linux CI).
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(super.testFile);

  /// Maximum allowed pixel difference ratio (0.5% = 0.005).
  static const double _tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    try {
      return await super.compare(imageBytes, golden);
    } catch (e) {
      // Flutter 3.29+ throws FlutterError; older versions throw TestFailure.
      // Both stringify to a message like:
      //   'Pixel test failed, 0.15%, 744px diff detected.'
      final match = RegExp(r'(\d+\.\d+)%').firstMatch(e.toString());
      if (match != null) {
        final diffPercent = double.parse(match.group(1)!) / 100;
        if (diffPercent <= _tolerance) {
          debugPrint(
            'Golden diff ${(diffPercent * 100).toStringAsFixed(2)}% '
            'within tolerance ${(_tolerance * 100).toStringAsFixed(1)}% — passing.',
          );
          return true;
        }
      }
      rethrow;
    }
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  goldenFileComparator = TolerantGoldenFileComparator(
    Uri.parse('test/goldens/flutter_test_config.dart'),
  );
  await testMain();
}
