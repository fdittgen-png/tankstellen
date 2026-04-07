import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/edge_to_edge.dart';

void main() {
  group('EdgeToEdge', () {
    group('overlayStyle', () {
      test('status bar is transparent', () {
        expect(EdgeToEdge.overlayStyle.statusBarColor, Colors.transparent);
      });

      test('navigation bar is transparent', () {
        expect(
          EdgeToEdge.overlayStyle.systemNavigationBarColor,
          Colors.transparent,
        );
      });

      test('navigation bar contrast enforcement is disabled', () {
        expect(
          EdgeToEdge.overlayStyle.systemNavigationBarContrastEnforced,
          false,
        );
      });
    });

    group('enable', () {
      testWidgets('sets edge-to-edge system UI mode', (tester) async {
        final log = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            log.add(call);
            return null;
          },
        );

        EdgeToEdge.enable();
        await tester.pump();

        // Verify setEnabledSystemUIMode was called with edgeToEdge
        final modeCall = log.firstWhere(
          (c) => c.method == 'SystemChrome.setEnabledSystemUIMode',
          orElse: () => throw StateError(
            'setEnabledSystemUIMode not called. Calls: ${log.map((c) => c.method).toList()}',
          ),
        );
        expect(modeCall.arguments, 'SystemUiMode.edgeToEdge');

        // Verify setSystemUIOverlayStyle was called
        final styleCall = log.firstWhere(
          (c) => c.method == 'SystemChrome.setSystemUIOverlayStyle',
          orElse: () => throw StateError(
            'setSystemUIOverlayStyle not called. Calls: ${log.map((c) => c.method).toList()}',
          ),
        );
        final args = styleCall.arguments as Map;
        // Transparent = 0x00000000
        expect(args['statusBarColor'], 0);
        expect(args['systemNavigationBarColor'], 0);
        expect(args['systemNavigationBarContrastEnforced'], false);

        // Clean up
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
    });
  });
}
