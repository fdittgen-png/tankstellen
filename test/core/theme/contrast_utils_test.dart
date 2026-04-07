import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/contrast_utils.dart';

void main() {
  group('ContrastUtils', () {
    group('relativeLuminance', () {
      test('black has luminance 0', () {
        expect(ContrastUtils.relativeLuminance(Colors.black), closeTo(0.0, 0.001));
      });

      test('white has luminance 1', () {
        expect(ContrastUtils.relativeLuminance(Colors.white), closeTo(1.0, 0.001));
      });

      test('pure red has correct luminance', () {
        // 0.2126 * linearize(1.0) = 0.2126
        expect(
          ContrastUtils.relativeLuminance(const Color(0xFFFF0000)),
          closeTo(0.2126, 0.001),
        );
      });

      test('mid-grey has intermediate luminance', () {
        final lum = ContrastUtils.relativeLuminance(const Color(0xFF808080));
        expect(lum, greaterThan(0.1));
        expect(lum, lessThan(0.5));
      });
    });

    group('contrastRatio', () {
      test('black on white is 21:1', () {
        expect(
          ContrastUtils.contrastRatio(Colors.black, Colors.white),
          closeTo(21.0, 0.1),
        );
      });

      test('white on black is 21:1', () {
        expect(
          ContrastUtils.contrastRatio(Colors.white, Colors.black),
          closeTo(21.0, 0.1),
        );
      });

      test('same color returns 1:1', () {
        expect(
          ContrastUtils.contrastRatio(Colors.blue, Colors.blue),
          closeTo(1.0, 0.001),
        );
      });

      test('grey on white has moderate contrast', () {
        final ratio = ContrastUtils.contrastRatio(Colors.grey, Colors.white);
        expect(ratio, greaterThan(1.0));
        expect(ratio, lessThan(21.0));
      });
    });

    group('meetsAA', () {
      test('black on white meets AA', () {
        expect(ContrastUtils.meetsAA(Colors.black, Colors.white), isTrue);
      });

      test('white on white does not meet AA', () {
        expect(ContrastUtils.meetsAA(Colors.white, Colors.white), isFalse);
      });

      test('light grey on white does not meet AA', () {
        // Colors.grey.shade400 on white — known to fail
        expect(ContrastUtils.meetsAA(Colors.grey.shade400, Colors.white), isFalse);
      });
    });

    group('meetsAALarge', () {
      test('black on white meets AA large', () {
        expect(ContrastUtils.meetsAALarge(Colors.black, Colors.white), isTrue);
      });

      test('threshold is 3.0 for large text', () {
        expect(ContrastUtils.kMinContrastLarge, equals(3.0));
      });
    });
  });
}
