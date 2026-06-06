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
}
