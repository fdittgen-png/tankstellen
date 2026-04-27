import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/features/consumption/data/trip_share_renderer.dart';

/// #1189 — coverage for [shareTripAsImage].
///
/// Wraps a tiny coloured box in a [RepaintBoundary], invokes the
/// renderer with a fake share sink + temp directory, and asserts that:
///   * the renderer wrote a non-empty PNG file under the supplied
///     directory using the requested filename stem,
///   * the [ShareParams] handed to the sink carries that file as a
///     single [XFile] with the supplied subject text,
///   * a missing boundary key surfaces a [StateError] (no silent
///     swallow — UI integration owns the snackbar surface).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trip_share_renderer_');
    debugTemporaryDirectoryOverride = () async => tempDir;
  });

  tearDown(() {
    debugShareSinkOverride = null;
    debugTemporaryDirectoryOverride = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'renders the boundary subtree to a PNG and hands it to the share sink',
    (tester) async {
      final boundaryKey = GlobalKey();
      ShareParams? captured;
      debugShareSinkOverride = (params) async {
        captured = params;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: Container(
                key: const Key('share_target'),
                width: 64,
                height: 64,
                color: const Color(0xFF1976D2),
                alignment: Alignment.center,
                child: const Text(
                  'Trip',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ),
            ),
          ),
        ),
      );

      // [RenderRepaintBoundary.toImage] needs the real async clock /
      // rendering pipeline — the fake-async pump used by widget tests
      // never resolves the engine-side rasterisation. `runAsync` lets
      // the engine resolve the GPU work that produces the PNG bytes.
      await tester.runAsync(() async {
        await shareTripAsImage(
          boundaryKey: boundaryKey,
          subject: 'Tankstellen — trip on April 22, 2026',
          fileNameStem: 'tankstellen_trip_test',
          // Tiny pixel ratio keeps the test surface fast — the encoder
          // path is the same regardless of multiplier so the magic
          // header assertion below still proves PNG output.
          pixelRatio: 1.0,
        );
      });

      expect(captured, isNotNull, reason: 'share sink was not invoked');
      expect(captured!.subject, 'Tankstellen — trip on April 22, 2026');
      expect(captured!.text, 'Tankstellen — trip on April 22, 2026');
      expect(captured!.files, isNotNull);
      expect(captured!.files!.length, 1);
      final shared = captured!.files!.single;
      expect(shared.path.endsWith('tankstellen_trip_test.png'), isTrue,
          reason: 'expected PNG path under temp dir, got ${shared.path}');
      final file = File(shared.path);
      expect(file.existsSync(), isTrue);
      final bytes = file.readAsBytesSync();
      expect(bytes, isNotEmpty);
      // PNG magic header — `89 50 4E 47`.
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    },
  );

  testWidgets(
    'throws StateError when the boundary key has no current context',
    (tester) async {
      final orphanKey = GlobalKey();
      debugShareSinkOverride = (_) async =>
          fail('share sink must not be invoked when the key is unmounted');

      await tester.pumpWidget(const SizedBox.shrink());

      await expectLater(
        () => shareTripAsImage(
          boundaryKey: orphanKey,
          subject: 'subject',
          fileNameStem: 'no_boundary',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  testWidgets(
    'throws StateError when the keyed widget is not a RepaintBoundary',
    (tester) async {
      final wrongKey = GlobalKey();
      debugShareSinkOverride = (_) async =>
          fail('share sink must not be invoked when the key targets a Container');

      await tester.pumpWidget(
        MaterialApp(
          home: ColoredBox(
            key: wrongKey,
            color: const Color(0xFF000000),
            child: const SizedBox(width: 8, height: 8),
          ),
        ),
      );

      await expectLater(
        () => shareTripAsImage(
          boundaryKey: wrongKey,
          subject: 'subject',
          fileNameStem: 'wrong_target',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
