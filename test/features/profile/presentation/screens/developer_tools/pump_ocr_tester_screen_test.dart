// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_package.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_serializer.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/ocr_block_overlay_painter.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/ocr_trace_steps_panel.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/pump_ocr_tester_export.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/pump_ocr_tester_screen.dart';

import '../../../../../helpers/pump_app.dart';

/// Structural coverage for the gated OCR tester (#2518, Epic #2516
/// Child 2). No goldens — find-by-key / find-by-text only, and the steps
/// panel + block overlay are rendered from a SEEDED fixture trace so the
/// (ML-Kit-dependent) live pipeline never has to run under `flutter test`.
void main() {
  List<Object> overrides({required bool debugOn}) => [
        enabledFeaturesProvider.overrideWithValue(
          debugOn ? {Feature.debugMode} : <Feature>{},
        ),
      ];

  /// Builds a representative pump trace: ML Kit blocks, a label/numeric
  /// classification, a chosen anchor, a magnitude fallback, the
  /// cross-check that DERIVED the unit price, the gate, and the result.
  OcrTracePackage seededPumpTrace() {
    final trace = OcrTraceRecorder(kind: OcrTraceKind.pump);
    trace.blocks('PRIX 18,59 VOLUME 23,30', const [
      RecognizedTextBlock(
          text: 'PRIX', box: OcrBox(left: 10, top: 10, right: 60, bottom: 30)),
      RecognizedTextBlock(
          text: '18,59',
          box: OcrBox(left: 70, top: 10, right: 140, bottom: 30)),
      RecognizedTextBlock(
          text: 'VOLUME',
          box: OcrBox(left: 10, top: 50, right: 90, bottom: 70)),
      RecognizedTextBlock(
          text: '23,30',
          box: OcrBox(left: 100, top: 50, right: 170, bottom: 70)),
    ]);
    trace.classify('PRIX', 'label', field: 'total', weight: 2);
    trace.classify('18,59', 'numeric', value: 18.59, decimals: 2);
    trace.classify('VOLUME', 'label', field: 'volume', weight: 2);
    trace.classify('23,30', 'numeric', value: 23.30, decimals: 2);
    trace.anchorCandidates(const [
      OcrTraceAnchor(
          labelField: 'total',
          labelText: 'PRIX',
          numericValue: 18.59,
          sqDistance: 100,
          chosen: true),
    ]);
    trace.fallback(
        field: 'volume', value: 23.30, decimals: 2, reason: 'lone 2-dec');
    trace.crossCheck(
        total: 18.59,
        volume: 23.30,
        derivedPath: 'pricePerLitre',
        computed: 0.798);
    trace.confidence(
        hasTotal: true,
        hasVolume: true,
        hasPrice: true,
        isConsistent: true,
        total: 0.9);
    trace.gateCheck(
        checks: const [OcrTraceGateCheck(name: 'totalRange', passed: true)],
        reason: 'consistent',
        accepted: true,
        identityDelta: 0.0);
    trace.result(
        totalCost: 18.59,
        liters: 23.30,
        pricePerLiter: 0.798,
        derived: {'pricePerLitre'},
        confidence: 0.9,
        validated: true,
        validationReason: 'consistent');
    return trace.build();
  }

  group('PumpOcrTesterScreen', () {
    testWidgets('renders nothing when debugMode is OFF (defensive guard)',
        (tester) async {
      await pumpApp(
        tester,
        const PumpOcrTesterScreen(),
        overrides: overrides(debugOn: false),
      );
      expect(find.byKey(const Key('ocr_tester_mode')), findsNothing);
    });

    testWidgets('hosts the mode toggle, source picker + country dropdown',
        (tester) async {
      await pumpApp(
        tester,
        const PumpOcrTesterScreen(),
        overrides: overrides(debugOn: true),
      );
      expect(find.byKey(const Key('ocr_tester_mode')), findsOneWidget);
      expect(find.byKey(const Key('ocr_tester_capture')), findsOneWidget);
      expect(find.byKey(const Key('ocr_tester_pick')), findsOneWidget);
      expect(find.byKey(const Key('ocr_tester_country')), findsOneWidget);
      expect(find.byKey(const Key('ocr_tester_run')), findsOneWidget);
      // Run is disabled until an image is chosen.
      final run = tester.widget<FilledButton>(
          find.byKey(const Key('ocr_tester_run')));
      expect(run.onPressed, isNull);
    });

    testWidgets('Pump|Receipt segmented toggle switches mode',
        (tester) async {
      await pumpApp(
        tester,
        const PumpOcrTesterScreen(),
        overrides: overrides(debugOn: true),
      );
      expect(find.text('Receipt'), findsOneWidget);
      await tester.tap(find.text('Receipt'));
      await tester.pumpAndSettle();
      // Still rendered after the mode flip (no crash, toggle present).
      expect(find.byKey(const Key('ocr_tester_mode')), findsOneWidget);
    });
  });

  // The panel is a plain Column (it lives inside the screen's ListView in
  // production); wrap it in a scroll view for bare-pump tests so its tile
  // stack does not overflow the 800x600 test surface.
  Widget scrollable(Widget child) => SingleChildScrollView(child: child);

  group('OcrTraceStepsPanel (seeded fixture)', () {
    testWidgets('renders one tile per pump stage in order', (tester) async {
      await pumpApp(
          tester, scrollable(OcrTraceStepsPanel(package: seededPumpTrace())));
      for (final stage in const [
        OcrTraceStage.glare,
        OcrTraceStage.mlkit,
        OcrTraceStage.classify,
        OcrTraceStage.anchor,
        OcrTraceStage.crossCheck,
        OcrTraceStage.gate,
        OcrTraceStage.result,
      ]) {
        expect(find.byKey(Key('ocr_step_${stage.name}')), findsOneWidget,
            reason: 'missing stage tile for ${stage.name}');
      }
    });

    testWidgets('shows the fallback banner when a field was recovered',
        (tester) async {
      await pumpApp(
          tester, scrollable(OcrTraceStepsPanel(package: seededPumpTrace())));
      expect(find.byKey(const Key('ocr_steps_fallback_banner')),
          findsOneWidget);
    });

    testWidgets('flags the derived field with a DERIVED chip',
        (tester) async {
      await pumpApp(
          tester, scrollable(OcrTraceStepsPanel(package: seededPumpTrace())));
      // Expand the Result tile to reveal the per-value chips.
      await tester.tap(find.byKey(const Key('ocr_step_result')));
      await tester.pumpAndSettle();
      expect(find.text('DERIVED'), findsWidgets);
      expect(find.text('READ'), findsWidgets);
    });

    testWidgets('receipt fixture renders the receipt-only stages',
        (tester) async {
      final t = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      t.blocks('TOTAL 42,00', const []);
      t.brand('total_energies', 'totalEnergies');
      t.reconcile(read: 42.0, derived: 42.0, delta: 0.0);
      t.result(totalCost: 42.0);
      await pumpApp(tester, scrollable(OcrTraceStepsPanel(package: t.build())));
      expect(find.byKey(const Key('ocr_step_brand')), findsOneWidget);
      expect(find.byKey(const Key('ocr_step_reconcile')), findsOneWidget);
      // Pump-only stages must NOT appear on the receipt path.
      expect(find.byKey(const Key('ocr_step_anchor')), findsNothing);
    });
  });

  group('OcrBlockOverlayPainter (seeded fixture)', () {
    test('maps block boxes into the laid-out size', () {
      final painter = OcrBlockOverlayPainter(
        package: seededPumpTrace(),
        imageSize: const Size(200, 100),
      );
      // Block 0 ("PRIX") at 10..60 / 10..30 in a 200x100 image scales
      // 1:1 into a 200x100 widget rect.
      final rect = painter.blockRectFor(0, const Size(200, 100));
      expect(rect.left, 10);
      expect(rect.right, 60);
      // Scales x2 horizontally into a 400-wide widget.
      final scaled = painter.blockRectFor(0, const Size(400, 100));
      expect(scaled.left, 20);
      expect(scaled.right, 120);
    });

    testWidgets('paints inside a CustomPaint without throwing',
        (tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 200,
          height: 100,
          child: CustomPaint(
            painter: OcrBlockOverlayPainter(
              package: seededPumpTrace(),
              imageSize: const Size(200, 100),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  /// A pump trace with a (fake) captured image attached — promotable to a
  /// fixture (#2519).
  OcrTracePackage seededPumpTraceWithImage() {
    final trace = OcrTraceRecorder(kind: OcrTraceKind.pump);
    trace.input(country: 'FR');
    trace.blocks('PRIX 18,59', const [
      RecognizedTextBlock(
          text: 'PRIX', box: OcrBox(left: 10, top: 10, right: 60, bottom: 30)),
    ]);
    trace.result(totalCost: 18.59, liters: 23.30, pricePerLiter: 0.798);
    trace.image(fileName: 'capture.jpg', base64: base64Encode(const [1, 2, 3]));
    return trace.build();
  }

  group('OcrTesterExport.saveAsFixture (#2519)', () {
    test('builds a slug from country + read values', () {
      expect(OcrTesterExport.fixtureSlug(seededPumpTraceWithImage()),
          'pump_fr_18_59eur_23_30l');
    });

    test('writes a <slug>.jpg + <slug>.ocrpkg.json with expected filled',
        () async {
      final writes = <String, Uint8List>{};
      debugPublicFileExporterOverride =
          ({required bytes, required fileName, required mimeType}) async {
        writes[fileName] = bytes;
        return fileName;
      };
      addTearDown(() => debugPublicFileExporterOverride = null);

      final slug = await OcrTesterExport.saveAsFixture(
          seededPumpTraceWithImage());

      expect(slug, 'pump_fr_18_59eur_23_30l');
      expect(writes.keys, contains('pump_fr_18_59eur_23_30l.jpg'));
      expect(writes.keys, contains('pump_fr_18_59eur_23_30l.ocrpkg.json'));
      final json = utf8.decode(writes['pump_fr_18_59eur_23_30l.ocrpkg.json']!);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['expected'], isNotNull);
      expect((decoded['expected'] as Map)['totalCost'], 18.59);
      expect((decoded['expected'] as Map)['pricePerLiter'], 0.798);
      // The image filename is pinned to the slug so the generator's
      // sibling lookup finds the committed source.
      expect((decoded['image'] as Map)['fileName'],
          'pump_fr_18_59eur_23_30l.jpg');
    });

    test('returns null when the package carries no image', () async {
      final trace = OcrTraceRecorder(kind: OcrTraceKind.pump)
        ..result(totalCost: 1.0);
      expect(await OcrTesterExport.saveAsFixture(trace.build()), isNull);
    });
  });

  group('OcrTesterExport.copyAsJson (#2853)', () {
    /// Captures the `Clipboard.setData` text via the platform-channel mock,
    /// returning a getter so the test reads the latest captured value.
    String? Function() interceptClipboard() {
      TestWidgetsFlutterBinding.ensureInitialized();
      final captured = <String?>[null];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          captured[0] = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      return () => captured[0];
    }

    test('copies the image-elided trace to the clipboard', () async {
      final clipboard = interceptClipboard();
      final pkg = seededPumpTrace();
      expect(await OcrTesterExport.copyAsJson(pkg), isTrue);
      expect(clipboard(), isNotNull);
      expect(clipboard(), contains('"kind": "pump"'));
      // No image on this trace, so it equals the image-elided serialisation.
      expect(clipboard(),
          equals(formatOcrTracePackageJson(pkg, includeImage: false)));
    });

    test('does NOT put the base64 capture image on the clipboard', () async {
      final clipboard = interceptClipboard();
      // A real-shaped ~5 MB base64 capture — what tripped the Binder limit.
      final trace = OcrTraceRecorder(kind: OcrTraceKind.pump)
        ..result(totalCost: 18.59)
        ..image(
          fileName: 'capture.jpg',
          base64: base64Encode(List<int>.filled(4 * 1024 * 1024, 7)),
        );
      final pkg = trace.build();

      expect(await OcrTesterExport.copyAsJson(pkg), isTrue);
      final copied = clipboard();
      expect(copied, isNotNull);
      // The clipboard string omits the base64 bytes and stays tiny.
      expect(copied!.contains(pkg.image!.base64), isFalse);
      expect(utf8.encode(copied).length, lessThan(64 * 1024));
    });
  });
}
