// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/app_motion.dart';

void main() {
  group('AppMotion (#2972)', () {
    testWidgets('enabled is TRUE when the OS does not request reduced motion',
        (tester) async {
      late bool result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              result = AppMotion.enabled(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, isTrue);
    });

    testWidgets('enabled is FALSE when the OS requests reduced motion',
        (tester) async {
      late bool result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              result = AppMotion.enabled(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result, isFalse);
    });
  });

  group('AppMotion.selection (#3948)', () {
    test('is the 200 ms Material theme-change beat', () {
      expect(AppMotion.selection, const Duration(milliseconds: 200));
    });

    testWidgets('selectionDuration is the beat normally and zero under reduced '
        'motion', (tester) async {
      late Duration normal;
      late Duration reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              normal = AppMotion.selectionDuration(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reduced = AppMotion.selectionDuration(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(normal, AppMotion.selection);
      expect(reduced, Duration.zero);
    });
  });
}
