import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_lock_overlay.dart';

import '../../../../helpers/pump_app.dart';

/// Wrap the overlay in a Stack — the real driving screen does the
/// same — so Positioned.fill has a laid-out parent.
Widget _host(Widget overlay) {
  return Stack(children: [
    const SizedBox.expand(child: ColoredBox(color: Colors.blue)),
    overlay,
  ]);
}

void main() {
  group('DrivingLockOverlay', () {
    testWidgets('renders the lock icon and tap-to-unlock text',
        (tester) async {
      await pumpApp(
        tester,
        _host(DrivingLockOverlay(onUnlock: () {})),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Tap to unlock'), findsOneWidget);
    });

    testWidgets('text is bold and sized 24', (tester) async {
      await pumpApp(
        tester,
        _host(DrivingLockOverlay(onUnlock: () {})),
      );
      final text = tester.widget<Text>(find.text('Tap to unlock'));
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.style?.fontSize, 24);
      expect(text.style?.color, Colors.white);
    });

    testWidgets('icon is white70 and sized 64 so it reads from afar',
        (tester) async {
      await pumpApp(
        tester,
        _host(DrivingLockOverlay(onUnlock: () {})),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.lock_outline));
      expect(icon.size, 64);
      expect(icon.color, Colors.white70);
    });

    testWidgets('tapping anywhere on the overlay invokes onUnlock',
        (tester) async {
      var unlocked = 0;
      await pumpApp(
        tester,
        _host(DrivingLockOverlay(onUnlock: () => unlocked++)),
      );

      // Tap the center — where the text lives — and also an offset
      // region to confirm the GestureDetector covers the full area.
      await tester.tap(find.text('Tap to unlock'));
      await tester.pump();
      expect(unlocked, 1);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(unlocked, 2);
    });
  });
}
