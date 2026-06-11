// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Presentational widgets for the OCR-tester screen (#2518): the running
// spinner, the InteractiveViewer block-overlay view, and the colour
// legend. Part of `pump_ocr_tester_screen.dart` so it shares that
// library's imports and both files stay under the 400-line norm.
part of 'pump_ocr_tester_screen.dart';

/// In-progress spinner row.
class _RunningRow extends StatelessWidget {
  final String label;

  const _RunningRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

/// The source image + classified-block overlay inside an InteractiveViewer.
class _OverlayView extends StatelessWidget {
  /// #2821 — the EXIF-baked image bytes (NOT the raw file): rendered via
  /// [Image.memory] so the displayed pixels match [imageSize] and the block
  /// overlay, which all live in baked-pixel space.
  final Uint8List imageBytes;
  final Size imageSize;
  final OcrTracePackage package;
  final int? selectedIndex;
  final ValueChanged<int?> onTapBlock;

  const _OverlayView({
    required this.imageBytes,
    required this.imageSize,
    required this.package,
    required this.selectedIndex,
    required this.onTapBlock,
  });

  @override
  Widget build(BuildContext context) {
    final aspect = imageSize.height <= 0
        ? 1.0
        : imageSize.width / imageSize.height;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: InteractiveViewer(
        maxScale: 6,
        child: AspectRatio(
          aspectRatio: aspect <= 0 ? 1.0 : aspect,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  Size(constraints.maxWidth, constraints.maxHeight);
              final painter = OcrBlockOverlayPainter(
                package: package,
                imageSize: imageSize,
                selectedIndex: selectedIndex,
              );
              return GestureDetector(
                onTapDown: (d) =>
                    onTapBlock(_hitTest(painter, d.localPosition, size)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(imageBytes, fit: BoxFit.fill),
                    CustomPaint(
                      key: const Key('ocr_block_overlay'),
                      painter: painter,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  int? _hitTest(OcrBlockOverlayPainter painter, Offset point, Size size) {
    final blocks = package.mlkit?.blocks ?? const [];
    for (var i = 0; i < blocks.length; i++) {
      if (painter.blockRectFor(i, size).contains(point)) return i;
    }
    return null;
  }
}

/// Colour key for the block overlay.
class _OverlayLegend extends StatelessWidget {
  const _OverlayLegend();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          _LegendChip(
              color: OcrBlockOverlayColors.label,
              label: l?.ocrTesterLegendLabel ?? 'Label'),
          _LegendChip(
              color: OcrBlockOverlayColors.numeric,
              label: l?.ocrTesterLegendNumeric ?? 'Numeric'),
          _LegendChip(
              color: OcrBlockOverlayColors.noise,
              label: l?.ocrTesterLegendNoise ?? 'Noise'),
          _LegendChip(
              color: OcrBlockOverlayColors.derived,
              label: l?.ocrTesterLegendDerived ?? 'Derived'),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// The source-selection, run, and export behaviour of the OCR tester,
/// kept in this part as an extension on the private state so the screen
/// file stays under the 400-line norm (#2518).
extension _PumpOcrTesterActions on _PumpOcrTesterScreenState {
  // --- Source selection ----------------------------------------------------

  Future<void> _capture() async {
    if (_mode == _OcrTesterMode.pump) {
      await _capturePump();
    } else {
      await _captureReceipt();
    }
  }

  Future<void> _capturePump() async {
    OcrPumpFieldSpec? fieldSpec;
    var orientation = OcrDisplayOrientation.horizontal;
    final country = _country;
    if (country != null) {
      await _ocrConfig.load();
      final template = _ocrConfig.templateFor(country: country);
      fieldSpec = template?.pumpDisplay;
      orientation = template?.displayOrientation ?? orientation;
    }
    if (!mounted) return;
    final result = await Navigator.of(context).push<PumpCaptureResult>(
      MaterialPageRoute(
        builder: (_) => PumpDisplayCameraScreen(
          initialOrientation: orientation,
          fieldSpec: fieldSpec,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _rebuild(() {
      _imagePath = result.path;
      _roi = result.roi;
      _package = null;
      _bakedImageBytes = null;
    });
  }

  Future<void> _captureReceipt() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (shot == null || !mounted) return;
    _rebuild(() {
      _imagePath = shot.path;
      _roi = null;
      _package = null;
      _bakedImageBytes = null;
    });
  }

  Future<void> _pickImage() async {
    final shot = await _picker.pickImage(source: ImageSource.gallery);
    if (shot == null || !mounted) return;
    _rebuild(() {
      _imagePath = shot.path;
      _roi = null;
      _package = null;
      _bakedImageBytes = null;
    });
  }

  // --- Run -----------------------------------------------------------------

  Future<void> _run() async {
    final path = _imagePath;
    if (path == null) return;
    _rebuild(() {
      _running = true;
      _selectedBlock = null;
    });
    final trace = OcrTraceRecorder(
      kind: _mode == _OcrTesterMode.pump
          ? OcrTraceKind.pump
          : OcrTraceKind.receipt,
    );
    try {
      if (_mode == _OcrTesterMode.pump) {
        await _service.parsePumpDisplayImage(
          path,
          country: _country,
          roi: _roi,
          trace: trace,
        );
      } else {
        // The tester already holds a path, so run the receipt pipeline on
        // the picked image without reopening a camera (#2518).
        await _runReceipt(path, trace);
      }
      await _attachImage(trace, path);
    } catch (e, st) {
      // Dev tool — log the failure for diagnosis, then build whatever was
      // recorded so the partial trace is still inspectable.
      debugPrint('PumpOcrTester: pipeline run failed — $e\n$st');
    }
    if (!mounted) return;
    final decoded = await _decodeBaked(path);
    if (!mounted) return;
    _rebuild(() {
      _package = trace.build();
      _imageSize = decoded?.size;
      _bakedImageBytes = decoded?.bytes;
      _running = false;
    });
  }

  /// Runs the receipt pipeline on the already-picked [path] with [trace]
  /// wired. Uses [ReceiptScanService.parseReceiptImage] so no camera is
  /// reopened (the tester owns the source image).
  Future<void> _runReceipt(String path, OcrTraceRecorder trace) async {
    await _service.parseReceiptImage(
      path,
      country: _country,
      trace: trace,
    );
  }

  /// Reads [path]'s bytes and attaches them base64 to [trace] for export.
  Future<void> _attachImage(OcrTraceRecorder trace, String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      trace.image(
        fileName: 'tankstellen-ocr-${path.split('/').last}',
        base64: base64Encode(bytes),
      );
    } catch (_) {
      // ignore: silent_catch — Image attach is best-effort; the trace JSON is still useful.
    }
  }

  /// #2821 — read the capture, BAKE its EXIF orientation, and measure the
  /// baked pixels. Returns the baked bytes + their size so the preview
  /// ([Image.memory]) and the overlay scale ([imageSize]) share the same
  /// baked space the ML Kit blocks were produced in — otherwise an EXIF tag
  /// makes the preview appear flipped/rotated against the boxes.
  Future<({Uint8List bytes, Size size})?> _decodeBaked(String path) async {
    try {
      final raw = await File(path).readAsBytes();
      final baked = bakeImageOrientation(raw) ?? raw;
      final codec = await instantiateImageCodec(baked);
      final frame = await codec.getNextFrame();
      return (
        bytes: baked,
        size: Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // --- Export --------------------------------------------------------------

  Future<void> _copyAsJson(OcrTracePackage package) async {
    final copied = await OcrTesterExport.copyAsJson(package);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (!copied) {
      // The image-elided trace is still too large for the clipboard (#2853)
      // — route it to the Downloads / share-sheet export instead.
      await _exportPackage(package);
      return;
    }
    SnackBarHelper.showSuccess(
      context,
      l?.ocrTesterCopied ?? 'OCR trace copied to clipboard.',
    );
  }

  Future<void> _exportPackage(OcrTracePackage package) async {
    await OcrTesterExport.exportPackage(package);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l?.ocrTesterExported ?? 'OCR package saved to your Downloads folder.',
    );
  }

  Future<void> _saveAsFixture(OcrTracePackage package) async {
    await OcrTesterExport.saveAsFixture(package);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l?.ocrTesterFixtureSaved ??
          'Fixture saved to your Downloads folder. Move it under '
              'test/fixtures and run tool/promote_ocr_fixture.dart.',
    );
  }
}
