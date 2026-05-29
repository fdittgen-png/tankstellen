// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/ocr/ocr_geometry.dart';
import '../../data/ocr/pump_ocr_config.dart';
import '../widgets/pump_alignment_overlay.dart';
import '../widgets/pump_live_feedback_bar.dart';
import '../../../../core/logging/error_logger.dart';

/// Full-screen in-app camera for capturing a pump display (#1868, #2276).
///
/// Shows a live [CameraPreview] overlaid by [PumpAlignmentOverlay]:
/// an orientation-aware framing guide with per-field labelled slots so
/// the user lines each number up in its named slot before capturing.
///
/// The user can toggle H↔V orientation with the toolbar button; the
/// overlay redraws and the ROI changes accordingly so OCR always crops
/// exactly what the user framed.
///
/// Live glare detection samples each camera image stream frame and
/// updates [PumpLiveFeedbackBar] without running full OCR — a cheap
/// luminance-fraction check over the framed ROI.
///
/// Pops with a [PumpCaptureResult] (path + normalized ROI) or `null`.
///
/// [initialOrientation] and [fieldSpec] come from the active brand
/// template (looked up by the caller before pushing this route) so
/// the overlay knows the correct aspect and slot positions up front.
class PumpDisplayCameraScreen extends StatefulWidget {
  final OcrDisplayOrientation initialOrientation;
  final OcrPumpFieldSpec? fieldSpec;

  const PumpDisplayCameraScreen({
    super.key,
    this.initialOrientation = OcrDisplayOrientation.horizontal,
    this.fieldSpec,
  });

  @override
  State<PumpDisplayCameraScreen> createState() =>
      _PumpDisplayCameraScreenState();
}

class _PumpDisplayCameraScreenState extends State<PumpDisplayCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _permissionDenied = false;
  bool _failed = false;
  bool _capturing = false;
  bool _isOverGlared = false;
  bool _streamRunning = false;
  late OcrDisplayOrientation _orientation;

  /// Throttle for live glare sampling — only evaluate every 300 ms.
  int _lastSampleMs = 0;

  @override
  void initState() {
    super.initState();
    _orientation = widget.initialOrientation;
    WidgetsBinding.instance.addObserver(this);
    _setUpCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _stopStream();
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setUpCamera();
    }
  }

  void _stopStream() {
    if (!_streamRunning) return;
    _streamRunning = false;
    _controller?.stopImageStream().ignore();
  }

  Future<void> _setUpCamera() async {
    if (!mounted) return;
    setState(() {
      _initializing = true;
      _permissionDenied = false;
      _failed = false;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() { _initializing = false; _failed = true; });
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(back, ResolutionPreset.max,
          enableAudio: false);
      await ctrl.initialize();
      if (!mounted) { await ctrl.dispose(); return; }
      setState(() { _controller = ctrl; _initializing = false; });
      _startFrameSampling(ctrl);
    } on CameraException catch (e, st) {
      if (!mounted) return;
      final denied = e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'CameraAccessRestricted';
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'PumpDisplayCameraScreen: setup'}));
      setState(() {
        _initializing = false;
        _permissionDenied = denied;
        _failed = !denied;
      });
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'PumpDisplayCameraScreen: unavailable'}));
      if (mounted) setState(() { _initializing = false; _failed = true; });
    }
  }

  /// Subscribes to the camera image stream to sample luminance on each
  /// frame. Runs a cheap centre-strip glare check (no full decode overhead)
  /// and updates [_isOverGlared] at most once per ~300 ms to keep UI smooth.
  void _startFrameSampling(CameraController ctrl) {
    if (_streamRunning) return;
    try {
      _streamRunning = true;
      ctrl.startImageStream(_onCameraFrame);
    } catch (_) {
      _streamRunning = false;
    }
  }

  void _onCameraFrame(CameraImage frame) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSampleMs < 300) return;
    _lastSampleMs = now;
    final glared = _checkFrameGlare(frame);
    if (mounted && glared != _isOverGlared) {
      setState(() => _isOverGlared = glared);
    }
  }

  /// Cheap glare estimate: sample the Y-plane (luminance) of a centre
  /// strip of the frame, count near-white pixels. No full image decoding.
  bool _checkFrameGlare(CameraImage frame) {
    try {
      if (frame.planes.isEmpty) return false;
      final plane = frame.planes.first;
      final bytes = plane.bytes;
      final w = frame.width;
      final h = frame.height;
      final stride = plane.bytesPerRow;
      // Sample the centre 20 % of rows.
      final rowStart = (h * 0.4).round();
      final rowEnd = (h * 0.6).round();
      if (stride <= 0 || rowStart >= rowEnd) return false;
      var bright = 0;
      var total = 0;
      for (var row = rowStart; row < rowEnd && row < h; row++) {
        final base = row * stride;
        for (var col = 0; col < w; col++) {
          final idx = base + col;
          if (idx >= bytes.length) break;
          if ((bytes[idx] & 0xFF) >= 240) bright++;
          total++;
        }
      }
      if (total == 0) return false;
      return (bright / total) > GlarePolicy.standard.rejectAbove;
    } catch (_) {
      return false;
    }
  }

  void _toggleOrientation() => setState(() {
        _orientation = _orientation == OcrDisplayOrientation.horizontal
            ? OcrDisplayOrientation.vertical
            : OcrDisplayOrientation.horizontal;
      });

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      // Stop frame sampling during capture so the stream doesn't
      // compete with the sensor capture.
      _stopStream();
      final shot = await ctrl.takePicture();
      final roi = PumpAlignmentOverlay.normalizedRect(
        ctrl.value.aspectRatio,
        _orientation,
      );
      if (mounted) {
        Navigator.of(context)
            .pop(PumpCaptureResult(path: shot.path, roi: roi));
      }
    } on CameraException {
      if (mounted) setState(() { _capturing = false; _failed = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _body(context, l10n)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations? l10n) {
    if (_permissionDenied) {
      return _message(context,
          icon: Icons.no_photography_outlined,
          text: l10n?.pumpCameraPermissionDenied ??
              'Camera access is needed to scan the pump display. '
                  'Enable it in your device settings.');
    }
    if (_failed) {
      return _message(context,
          icon: Icons.error_outline,
          text: l10n?.pumpCameraError ??
              "The camera couldn't start. Try again or enter the values "
                  'by hand.',
          onRetry: _setUpCamera,
          retryLabel: l10n?.retry ?? 'Try again');
    }
    final ctrl = _controller;
    if (_initializing || ctrl == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(ctrl)),
        PumpAlignmentOverlay(
          isOverGlared: _isOverGlared,
          orientation: _orientation,
          fieldSpec: widget.fieldSpec,
        ),
        // Close button — top-left.
        Positioned(
          left: 4,
          top: 4,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: l10n?.cancel ?? 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        // H↔V orientation toggle — top-right.
        Positioned(
          right: 4,
          top: 4,
          child: IconButton(
            icon: Icon(
              _orientation == OcrDisplayOrientation.horizontal
                  ? Icons.stay_primary_landscape_outlined
                  : Icons.stay_primary_portrait_outlined,
              color: Colors.white,
            ),
            tooltip: _orientation == OcrDisplayOrientation.horizontal
                ? (l10n?.pumpCameraOrientationVertical ?? 'Switch to vertical')
                : (l10n?.pumpCameraOrientationHorizontal ??
                    'Switch to horizontal'),
            onPressed: _toggleOrientation,
          ),
        ),
        // Live feedback bar — above the shutter button.
        Positioned(
          left: 0,
          right: 0,
          bottom: 96,
          child: Center(
            child: PumpLiveFeedbackBar(
              isOverGlared: _isOverGlared,
              isCapturing: _capturing,
            ),
          ),
        ),
        // Shutter button.
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: FilledButton.icon(
              onPressed: _capturing ? null : _capture,
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n?.pumpCameraCapture ?? 'Capture'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String text,
    Future<void> Function()? onRetry,
    String? retryLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRetry != null) ...[
                  OutlinedButton(
                    onPressed: () => onRetry(),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white),
                    child: Text(retryLabel ?? 'Try again'),
                  ),
                  const SizedBox(width: 12),
                ],
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                      AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What [PumpDisplayCameraScreen] pops on a successful capture (#2275):
/// the captured JPEG's [path] plus the normalized overlay [roi] the user
/// framed, so the OCR pipeline can crop to exactly that region first.
class PumpCaptureResult {
  final String path;
  final OcrNormalizedRect roi;

  const PumpCaptureResult({required this.path, required this.roi});
}
