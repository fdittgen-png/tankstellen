import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/app_radius.dart';

void main() {
  group('AppRadius (#591)', () {
    test('scalar values increase monotonically', () {
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.lg, lessThan(AppRadius.xl));
      expect(AppRadius.xl, lessThan(AppRadius.xxl));
    });

    test('BorderRadius helpers wrap the matching scalar values', () {
      expect(
        AppRadius.radiusLg,
        const BorderRadius.all(Radius.circular(AppRadius.lg)),
      );
      expect(
        AppRadius.radiusXl,
        const BorderRadius.all(Radius.circular(AppRadius.xl)),
      );
    });
  });
}
