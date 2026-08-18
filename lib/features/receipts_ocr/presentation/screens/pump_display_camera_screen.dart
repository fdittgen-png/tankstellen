// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/ocr/ocr_geometry.dart';
import '../../data/ocr/pump_ocr_config.dart';
import '../widgets/pump_alignment_overlay.dart';
import '../widgets/pump_camera_message.dart';
import '../widgets/pump_live_feedback_bar.dart';
import '../widgets/pump_shutter_button.dart';
import '../../../../core/logging/error_logger.dart';

/// Full-screen in-app camera for capturing a pump display (#1868, #2276,
/// #2477).
///
/// Shows a live [CameraPreview] overlaid by [PumpAlignmentOverlay]:
/// an orientation-aware framing guide with per-field labelled slots so
/// the user lines each number up in its named slot before capturing.
///
/// Pump displays are wide (the three numbers sit side by side), so a
/// portrait shot lands the digits sideways and small — too small for the
/// per-field masks to align. The screen therefore **forces landscape**
/// (#2477): it pins [SystemChrome.setPreferredOrientations] to the two
/// landscape orientations on entry, locks the capture orientation to
/// [DeviceOrientation.landscapeRight] so the baked JPEG matches the held
/// device, and restores the app's full orientation set on dispose. While
/// the device is still portrait (mid-rotation) the live feedback bar
/// shows the highest-priority rotate prompt and the shutter is disabled.
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
    // #2477 — force landscape so the wide pump display fills the frame
    // with large, upright digits. Restored in dispose + every early-return.
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
    WidgetsBinding.instance.addObserver(this);
    unawaited(_setUpCamera());
  }

  @override
  void dispose() {
    // Never leave the rest of the app landscape-locked (#2477).
    _restoreOrientations();
    WidgetsBinding.instance.removeObserver(this);
    _stopStream();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  /// Restores the app's full orientation set after a forced-landscape
  /// session. Safe to call more than once and from any teardown path.
  void _restoreOrientations() {
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _stopStream();
      unawaited(ctrl.dispose());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_setUpCamera());
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
      if (!mounted) {
        // Widget gone mid-init — dispose() already restored orientation.
        await ctrl.dispose();
        return;
      }
      // #2477 — bake the JPEG in landscape so it matches the held device.
      // Guarded: degrade gracefully if the platform doesn't support it.
      try {
        await ctrl.lockCaptureOrientation(DeviceOrientation.landscapeRight);
      } on CameraException catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
          'where': 'PumpDisplayCameraScreen: lockCaptureOrientation'
        }));
      }
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
      unawaited(ctrl.startImageStream(_onCameraFrame));
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

  Widget _body(BuildContext context, AppLocalizations l10n) {
    if (_permissionDenied) {
      return PumpCameraMessage(
        icon: Icons.no_photography_outlined,
        text: l10n.pumpCameraPermissionDenied,
      );
    }
    if (_failed) {
      return PumpCameraMessage(
        icon: Icons.error_outline,
        text: l10n.pumpCameraError,
        onRetry: _setUpCamera,
        retryLabel: l10n.retry,
      );
    }
    final ctrl = _controller;
    if (_initializing || ctrl == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    // #2477 — the orientation lock asks for landscape, but the device can
    // still be physically portrait mid-rotation. Gate the shutter on the
    // live media orientation so a portrait shot can never be taken.
    return OrientationBuilder(
      builder: (context, orientation) {
        final isPortrait = orientation == Orientation.portrait;
        return _preview(context, l10n, ctrl, isPortrait: isPortrait);
      },
    );
  }

  Widget _preview(
    BuildContext context,
    AppLocalizations l10n,
    CameraController ctrl, {
    required bool isPortrait,
  }) {
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
            tooltip: l10n.cancel,
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
                ? (l10n.pumpCameraOrientationVertical)
                : (l10n.pumpCameraOrientationHorizontal),
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
              isPortrait: isPortrait,
              isCapturing: _capturing,
            ),
          ),
        ),
        // Shutter button — disabled while portrait so no sideways /
        // small-digit shot can be taken (#2477).
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: PumpShutterButton(
              isCapturing: _capturing,
              isPortrait: isPortrait,
              onCapture: _capture,
            ),
          ),
        ),
      ],
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
