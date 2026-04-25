import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/permissions/camera_permissions.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-screen QR code scanner for scanning TankSync credentials and
/// payment QR codes from the station-detail screen.
///
/// #721 hardens the scanner against the failure modes the bare
/// `MobileScanner` has no opinion on:
/// * Camera permission denied → a settings CTA instead of a silent
///   black surface.
/// * 30 s without a decode → a retry prompt so the user isn't stuck
///   holding a dead camera over a blurry code.
/// * Haptic nudge on decode so users know the scan landed before
///   the navigation animation fires.
class QrScannerScreen extends StatefulWidget {
  /// Optional caption shown as an overlay hint. Defaults to a generic
  /// "Point the camera at a QR code" message. Callers that reuse this
  /// screen for more specific flows (payment, TankSync link) pass
  /// their own message.
  final String? guidance;

  /// Injectable controller for widget tests — production callers leave
  /// this null and the screen owns its own controller.
  final MobileScannerController? controllerOverride;

  /// Injectable permission facade — production uses the real plugin,
  /// tests pass a fake returning the state they want to verify.
  /// Null in production defaults to [PluginCameraPermissions] (can't
  /// be a const default because `openAppSettings` isn't const).
  final CameraPermissions? permissions;

  /// How long to wait for a decode before showing the retry prompt.
  /// Exposed so tests can use a short duration.
  final Duration scanTimeout;

  const QrScannerScreen({
    super.key,
    this.guidance,
    this.controllerOverride,
    this.permissions,
    this.scanTimeout = const Duration(seconds: 30),
  });

  CameraPermissions get _permissions =>
      permissions ?? const PluginCameraPermissions();

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

enum _ScannerPhase { probing, scanning, denied, permanentlyDenied, timeout }

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _scanned = false;
  bool _ownsController = false;
  _ScannerPhase _phase = _ScannerPhase.probing;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    if (widget.controllerOverride != null) {
      _controller = widget.controllerOverride!;
    } else {
      _controller = MobileScannerController();
      _ownsController = true;
    }
    _probePermission();
  }

  Future<void> _probePermission() async {
    final state = await widget._permissions.current();
    if (!mounted) return;
    switch (state) {
      case CameraPermissionState.granted:
        _enterScanning();
      case CameraPermissionState.denied:
        final requested = await widget._permissions.request();
        if (!mounted) return;
        if (requested == CameraPermissionState.granted) {
          _enterScanning();
        } else if (requested == CameraPermissionState.permanentlyDenied) {
          setState(() => _phase = _ScannerPhase.permanentlyDenied);
        } else {
          setState(() => _phase = _ScannerPhase.denied);
        }
      case CameraPermissionState.permanentlyDenied:
        setState(() => _phase = _ScannerPhase.permanentlyDenied);
    }
  }

  void _enterScanning() {
    setState(() => _phase = _ScannerPhase.scanning);
    _startTimeout();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(widget.scanTimeout, () {
      if (!mounted) return;
      setState(() => _phase = _ScannerPhase.timeout);
    });
  }

  void _retry() {
    _scanned = false;
    _enterScanning();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n?.syncWizardScanQrCode ?? 'Scan QR Code',
      bodyPadding: EdgeInsets.zero,
      actions: _phase == _ScannerPhase.scanning
          ? [
              QrScannerTorchButton(
                state: _controller,
                onToggle: _controller.toggleTorch,
              ),
            ]
          : null,
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations? l10n) {
    switch (_phase) {
      case _ScannerPhase.probing:
        return const Center(child: CircularProgressIndicator());
      case _ScannerPhase.denied:
        return _PermissionDenied(
          key: const Key('qrScannerDenied'),
          message: l10n?.qrScannerPermissionDenied ??
              'Camera access is needed to scan QR codes.',
          buttonLabel: l10n?.qrScannerRetryPermission ?? 'Try again',
          onPressed: _probePermission,
        );
      case _ScannerPhase.permanentlyDenied:
        return _PermissionDenied(
          key: const Key('qrScannerPermanentlyDenied'),
          message: l10n?.qrScannerPermissionPermanentlyDenied ??
              'Camera access was denied. Open settings to grant it.',
          buttonLabel: l10n?.qrScannerOpenSettings ?? 'Open settings',
          onPressed: widget._permissions.openSettings,
        );
      case _ScannerPhase.timeout:
        return _ScanTimeoutPrompt(
          message: l10n?.qrScannerTimeout ??
              'No QR code detected. Move closer or try again.',
          buttonLabel: l10n?.qrScannerRetry ?? 'Try again',
          onPressed: _retry,
        );
      case _ScannerPhase.scanning:
        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            const _ScanFrameOverlay(),
            Align(
              alignment: Alignment.bottomCenter,
              child: _GuidanceCaption(
                text: widget.guidance ??
                    l10n?.qrScannerGuidance ??
                    'Point the camera at a QR code',
              ),
            ),
          ],
        );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null) return;
    _scanned = true;
    _timeoutTimer?.cancel();
    // Medium impact — noticeable but not startling. Gives the user
    // a tactile "yes, we got it" before the navigation animation.
    HapticFeedback.mediumImpact();
    Navigator.pop(context, value);
  }
}

/// Torch toggle button extracted so it can be widget-tested against a
/// plain `ValueListenable<MobileScannerState>` without having to pump
/// a full `MobileScanner` — which insists on a real controller with
/// an `autoStart` getter that our test fakes cannot satisfy.
class QrScannerTorchButton extends StatelessWidget {
  final ValueListenable<MobileScannerState> state;
  final Future<void> Function() onToggle;

  const QrScannerTorchButton({
    super.key,
    required this.state,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: state,
      builder: (context, value, _) {
        final torch = value.torchState;
        if (torch == TorchState.unavailable) return const SizedBox.shrink();
        final on = torch == TorchState.on;
        return IconButton(
          key: const Key('qrScannerTorchToggle'),
          icon: Icon(on ? Icons.flash_on : Icons.flash_off),
          tooltip: on
              ? (l10n?.torchOff ?? 'Turn flash off')
              : (l10n?.torchOn ?? 'Turn flash on'),
          onPressed: onToggle,
        );
      },
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  const _PermissionDenied({
    super.key,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('qrScannerDeniedAction'),
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanTimeoutPrompt extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _ScanTimeoutPrompt({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off_outlined, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('qrScannerTimeoutRetry'),
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dimmed backdrop with a square cut-out in the middle. Gives the
/// user a clear target so they stop holding the camera 2 cm from the
/// code.
class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FramePainter(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Color color;
  _FramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const frameRatio = 0.65;
    final side = size.shortestSide * frameRatio;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Dimmed backdrop — scrim everywhere except the scan window.
    final scrim = Paint()..color = Colors.black54;
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);

    // Accent border around the window.
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.color != color;
}

class _GuidanceCaption extends StatelessWidget {
  final String text;
  const _GuidanceCaption({required this.text});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
