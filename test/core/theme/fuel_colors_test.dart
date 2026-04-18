import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/fuel_colors.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('FuelColors.forType', () {
    test('covers every concrete FuelType variant', () {
      // Exhaustive switch coverage — the sealed FuelType hierarchy means
      // adding a new variant without updating FuelColors would skip the
      // switch arms. This pins every arm against a drift-free list.
      final allTypes = <FuelType>[
        FuelType.e5,
        FuelType.e10,
        FuelType.e98,
        FuelType.diesel,
        FuelType.dieselPremium,
        FuelType.e85,
        FuelType.lpg,
        FuelType.cng,
        FuelType.hydrogen,
        FuelType.electric,
        FuelType.all,
      ];
      for (final type in allTypes) {
        final color = FuelColors.forType(type);
        expect(color, isA<Color>(), reason: '$type should resolve to a Color');
      }
    });

    test('each fuel type maps to a distinct color', () {
      // Chart legibility depends on colors being unique across the palette.
      final palette = <FuelType, Color>{
        FuelType.e5: FuelColors.forType(FuelType.e5),
        FuelType.e10: FuelColors.forType(FuelType.e10),
        FuelType.e98: FuelColors.forType(FuelType.e98),
        FuelType.diesel: FuelColors.forType(FuelType.diesel),
        FuelType.dieselPremium: FuelColors.forType(FuelType.dieselPremium),
        FuelType.e85: FuelColors.forType(FuelType.e85),
        FuelType.lpg: FuelColors.forType(FuelType.lpg),
        FuelType.cng: FuelColors.forType(FuelType.cng),
        FuelType.hydrogen: FuelColors.forType(FuelType.hydrogen),
        FuelType.electric: FuelColors.forType(FuelType.electric),
        FuelType.all: FuelColors.forType(FuelType.all),
      };
      expect(palette.values.toSet().length, palette.length,
          reason: 'Fuel type colors must be pairwise distinct');
    });

    test('diesel is orange, electric is teal (pinned brand signals)', () {
      // These specific mappings surface in marketing screenshots and
      // chart legends — callers should not silently re-tint them.
      expect(FuelColors.forType(FuelType.diesel), const Color(0xFFFF9800));
      expect(FuelColors.forType(FuelType.electric), const Color(0xFF009688));
    });
  });

  group('FuelColors.forTypeLight', () {
    test('returns the same hue with reduced alpha (0.15)', () {
      final base = FuelColors.forType(FuelType.e5);
      final light = FuelColors.forTypeLight(FuelType.e5);
      expect(light.r, base.r);
      expect(light.g, base.g);
      expect(light.b, base.b);
      expect(light.a, closeTo(0.15, 0.001));
    });

    test('works for every fuel type', () {
      for (final type in <FuelType>[
        FuelType.e5,
        FuelType.e10,
        FuelType.diesel,
        FuelType.electric,
        FuelType.all,
      ]) {
        final light = FuelColors.forTypeLight(type);
        expect(light.a, closeTo(0.15, 0.001));
      }
    });
  });
}
