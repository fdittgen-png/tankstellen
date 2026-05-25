// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/pump_display_reticle.dart';

/// Full-screen in-app camera for capturing a pump display (#1868).
///
/// `image_picker` delegates to the OS camera app, which cannot host an
/// overlay. This screen shows a live [CameraPreview] with a framing
/// [PumpDisplayReticle] so the user fills the frame with just the
/// three-number display — cutting the metrology stickers, pump logos
/// and card-reader text the OCR parser would otherwise have to strip.
///
/// Pops with the captured JPEG's file path, or `null` when the user
/// cancels or the camera is unavailable. The caller feeds the path
/// into `ReceiptScanService.parsePumpDisplayImage`.
class PumpDisplayCameraScreen extends StatefulWidget {
  const PumpDisplayCameraScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUpCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    // Release the camera while backgrounded; re-acquire on resume —
    // the canonical camera-plugin lifecycle, without which the preview
    // freezes after the app returns from the background.
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setUpCamera();
    }
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
        if (mounted) {
          setState(() {
            _initializing = false;
            _failed = true;
          });
        }
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (e, st) {
      if (!mounted) return;
      final denied = e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'CameraAccessRestricted';
      debugPrint('PumpDisplayCameraScreen: camera setup failed: $e\n$st');
      setState(() {
        _initializing = false;
        _permissionDenied = denied;
        _failed = !denied;
      });
    } catch (e, st) {
      debugPrint('PumpDisplayCameraScreen: camera unavailable: $e\n$st');
      if (mounted) {
        setState(() {
          _initializing = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final shot = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(shot.path);
    } on CameraException {
      if (mounted) {
        setState(() {
          _capturing = false;
          _failed = true;
        });
      }
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
      return _message(
        context,
        icon: Icons.no_photography_outlined,
        text: l10n?.pumpCameraPermissionDenied ??
            'Camera access is needed to scan the pump display. '
                'Enable it in your device settings.',
      );
    }
    if (_failed) {
      return _message(
        context,
        icon: Icons.error_outline,
        text: l10n?.pumpCameraError ??
            "The camera couldn't start. Try again or enter the values "
                'by hand.',
        onRetry: _setUpCamera,
        retryLabel: l10n?.retry ?? 'Try again',
      );
    }
    final controller = _controller;
    if (_initializing || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(controller)),
        const PumpDisplayReticle(),
        Positioned(
          left: 4,
          top: 4,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: l10n?.cancel ?? 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 96,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n?.pumpCameraHint ??
                    'Line up the three pump-display numbers inside '
                        'the frame',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
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
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRetry != null) ...[
                  OutlinedButton(
                    onPressed: () => onRetry(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(retryLabel ?? 'Try again'),
                  ),
                  const SizedBox(width: 12),
                ],
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppLocalizations.of(context)?.cancel ?? 'Cancel',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
