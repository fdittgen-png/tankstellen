import 'package:flutter/material.dart';

/// Permission-denied prompt shown when the camera permission is denied
/// or permanently denied. Provides a CTA to retry or open settings,
/// depending on which state the screen is in.
class QrPermissionDenied extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  const QrPermissionDenied({
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

/// Timeout prompt shown after the configured scan timeout elapses
/// without a successful decode. Lets the user retry without leaving
/// the screen.
class QrScanTimeoutPrompt extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const QrScanTimeoutPrompt({
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
class QrScanFrameOverlay extends StatelessWidget {
  const QrScanFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: QrFramePainter(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// Custom painter that draws a scrim with a centred rounded-rectangle
/// cut-out plus an accent border around the cut-out. Used by
/// [QrScanFrameOverlay] but exposed publicly so widget tests can pump
/// it in isolation.
class QrFramePainter extends CustomPainter {
  final Color color;
  QrFramePainter({required this.color});

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
  bool shouldRepaint(covariant QrFramePainter old) => old.color != color;
}
