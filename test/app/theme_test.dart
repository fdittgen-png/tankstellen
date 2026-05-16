import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/theme.dart';

void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('has light brightness', () {
      expect(theme.brightness, Brightness.light);
    });

    test('primary colour lands in the green family (#1757 forest green)', () {
      final p = theme.colorScheme.primary;
      expect(p.g, greaterThan(p.r));
      expect(p.g, greaterThan(p.b));
    });
  });

  group('AppTheme.dark', () {
    final theme = AppTheme.dark();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('has dark brightness', () {
      expect(theme.brightness, Brightness.dark);
    });

    test('dark primary is also in the green family', () {
      final p = theme.colorScheme.primary;
      expect(p.g, greaterThan(p.r));
      expect(p.g, greaterThan(p.b));
    });
  });

  test('light and dark have distinct brightness values', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
  });
}
