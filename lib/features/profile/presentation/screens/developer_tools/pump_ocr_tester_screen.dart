// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show instantiateImageCodec;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/country/country_config.dart';
import '../../../../../core/widgets/page_scaffold.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../receipts_ocr/api.dart';
import '../../../../feature_management/application/feature_flags_provider.dart';
import '../../../../feature_management/domain/feature.dart';
import 'pump_ocr_tester_export.dart';

// The presentational widgets live in a part so this file stays under the
// 400-line norm; the screen + its view widgets are one unit.
part 'pump_ocr_tester_widgets.dart';

/// Gated developer OCR tester (#2518, Epic #2516 Child 2).
///
/// Runs the REAL receipt OCR pipeline on a captured or picked image
/// with a live [OcrTraceRecorder] wired through, then renders the full
/// reasoning chain: a [OcrBlockOverlayPainter] over the source image in an
/// [InteractiveViewer], the per-stage [OcrTraceStepsPanel], and a local
/// export (copy-as-JSON + image+JSON package via [OcrTesterExport]).
///
/// Mirrors [Obd2HealthScreen]: pushed only from the gated Developer-tools
/// screen, and self-guards on [Feature.debugMode] so a stale deep-link is
/// inert. Production is byte-for-byte unchanged — the recorder is only
/// constructed here, in dev mode.
class PumpOcrTesterScreen extends ConsumerStatefulWidget {
  /// Test seam: injected scan service (real ML Kit cannot run under
  /// `flutter test`). Production leaves it null and builds the default.
  final ReceiptScanService? scanService;

  /// Test seam: injected image picker for the gallery / receipt-camera
  /// source so a widget test can feed a fixture path without a channel.
  final ImagePicker? picker;

  const PumpOcrTesterScreen({super.key, this.scanService, this.picker});

  @override
  ConsumerState<PumpOcrTesterScreen> createState() =>
      _PumpOcrTesterScreenState();
}

class _PumpOcrTesterScreenState extends ConsumerState<PumpOcrTesterScreen> {
  String? _country;
  String? _imagePath;
  bool _running = false;
  OcrTracePackage? _package;
  Size? _imageSize;
  // #2821 — the EXIF-baked image bytes for the preview, so the displayed
  // pixels, the measured [_imageSize], and the ML Kit block overlay (which
  // ran on the baked upright copy) all share one coordinate space.
  Uint8List? _bakedImageBytes;
  int? _selectedBlock;

  late final ReceiptScanService _service =
      widget.scanService ?? ReceiptScanService();
  late final ImagePicker _picker = widget.picker ?? ImagePicker();

  /// Library-internal rebuild seam so the source/run/export methods, which
  /// live in the `pump_ocr_tester_widgets.dart` part (to keep this file
  /// under the 400-line norm), can request a rebuild without tripping the
  /// `invalid_use_of_protected_member` lint on `setState` from the part.
  void _rebuild(VoidCallback fn) => setState(fn);

  @override
  void dispose() {
    if (widget.scanService == null) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final debugOn = ref
        .watch(enabledFeaturesProvider)
        .contains(Feature.debugMode);
    final title = l.ocrTesterTitle;

    if (!debugOn) {
      // Defensive: a stale deep-link must never expose dev tools.
      return PageScaffold(title: title, body: const SizedBox.shrink());
    }

    final theme = Theme.of(context);
    return PageScaffold(
      title: title,
      body: ListView(
        children: [
          Text(
            l.ocrTesterExplain,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _countryDropdown(l),
          const SizedBox(height: 12),
          _sourceRow(l),
          const SizedBox(height: 8),
          _runButton(l),
          const SizedBox(height: 16),
          if (_running)
            _RunningRow(label: l.ocrTesterRunning)
          else if (_package != null)
            ..._results(context, l, _package!)
          else
            Text(l.ocrTesterNoImage, style: theme.textTheme.bodyMedium),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Widget _countryDropdown(AppLocalizations l) {
    return DropdownButtonFormField<String?>(
      key: const Key('ocr_tester_country'),
      initialValue: _country,
      decoration: InputDecoration(
        labelText: l.ocrTesterCountry,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(l.ocrTesterCountryNone),
        ),
        for (final c in Countries.all)
          DropdownMenuItem<String?>(
            value: c.code,
            // Country name is a proper noun (data), not translatable UI.
            child: Text('${c.flag} ${c.name}'), // i18n-ignore: country data
          ),
      ],
      onChanged: (v) => setState(() => _country = v),
    );
  }

  Widget _sourceRow(AppLocalizations l) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('ocr_tester_capture'),
            onPressed: _running ? null : _capture,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l.ocrTesterCapture),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('ocr_tester_pick'),
            onPressed: _running ? null : _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(l.ocrTesterPickImage),
          ),
        ),
      ],
    );
  }

  Widget _runButton(AppLocalizations l) {
    return FilledButton.icon(
      key: const Key('ocr_tester_run'),
      onPressed: (_running || _imagePath == null) ? null : _run,
      icon: const Icon(Icons.play_arrow_outlined),
      label: Text(l.ocrTesterRun),
    );
  }

  List<Widget> _results(
    BuildContext context,
    AppLocalizations l,
    OcrTracePackage package,
  ) {
    return [
      SectionHeader(
        leadingIcon: Icons.grid_on_outlined,
        title: l.ocrTesterOverlaySection,
        padding: EdgeInsets.zero,
      ),
      const SizedBox(height: 8),
      if (_bakedImageBytes != null && _imageSize != null)
        _OverlayView(
          imageBytes: _bakedImageBytes!,
          imageSize: _imageSize!,
          package: package,
          selectedIndex: _selectedBlock,
          onTapBlock: (i) => setState(() => _selectedBlock = i),
        ),
      const _OverlayLegend(),
      const SizedBox(height: 16),
      SectionHeader(
        leadingIcon: Icons.list_alt_outlined,
        title: l.ocrTesterStepsSection,
        padding: EdgeInsets.zero,
      ),
      const SizedBox(height: 8),
      OcrTraceStepsPanel(package: package),
      const SizedBox(height: 16),
      _exportRow(l, package),
    ];
  }

  Widget _exportRow(AppLocalizations l, OcrTracePackage package) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('ocr_tester_copy_json'),
            onPressed: () => _copyAsJson(package),
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(l.ocrTesterCopyJson),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('ocr_tester_export'),
            onPressed: () => _exportPackage(package),
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(l.ocrTesterExportPackage),
          ),
        ),
      ],
    );
  }

}
