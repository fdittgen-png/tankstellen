import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';

/// Full-screen QR code scanner for scanning TankSync credentials and
/// payment QR codes from the station-detail screen.
///
/// Adds the UX pieces called out in #721: a torch (flash) toggle in
/// the app bar so the user can scan in low light, and a guidance
/// caption at the bottom that explains what the camera is looking
/// for. Permission prompt + timeout handling are separate follow-ups
/// on the same issue.
class QrScannerScreen extends StatefulWidget {
  /// Optional caption shown as an overlay hint. Defaults to a generic
  /// "Point the camera at a QR code" message. Callers that reuse this
  /// screen for more specific flows (payment, TankSync link) pass
  /// their own message.
  final String? guidance;

  /// Injectable controller for widget tests — production callers leave
  /// this null and the screen owns its own controller.
  final MobileScannerController? controllerOverride;

  const QrScannerScreen({
    super.key,
    this.guidance,
    this.controllerOverride,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _scanned = false;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controllerOverride != null) {
      _controller = widget.controllerOverride!;
    } else {
      _controller = MobileScannerController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.syncWizardScanQrCode ?? 'Scan QR Code'),
        actions: [
          QrScannerTorchButton(
            state: _controller,
            onToggle: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              final value = barcode?.rawValue;
              if (value != null) {
                _scanned = true;
                Navigator.pop(context, value);
              }
            },
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
      ),
    );
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
