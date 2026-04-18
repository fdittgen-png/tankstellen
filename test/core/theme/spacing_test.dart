import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/spacing.dart';

void main() {
  group('Spacing — scale', () {
    test('values form a strictly increasing ladder', () {
      // The whole point of a scale is that consumers can reach for "one
      // step up" without memorising the numbers. Pin the ordering so
      // future renames can't silently flatten the scale.
      final ladder = [
        Spacing.xs,
        Spacing.sm,
        Spacing.md,
        Spacing.lg,
        Spacing.xl,
        Spacing.xxl,
        Spacing.xxxl,
      ];
      for (var i = 1; i < ladder.length; i++) {
        expect(ladder[i], greaterThan(ladder[i - 1]),
            reason: 'Ladder broke at index $i: ${ladder[i - 1]} → ${ladder[i]}');
      }
    });

    test('xs is 2.0 and xxxl is 32.0 (pinned endpoints)', () {
      expect(Spacing.xs, 2.0);
      expect(Spacing.xxxl, 32.0);
    });
  });

  group('Spacing — padding patterns', () {
    test('screenPadding uses xl on all sides', () {
      expect(Spacing.screenPadding, const EdgeInsets.all(Spacing.xl));
    });

    test('cardMargin has horizontal=md, vertical=xs', () {
      expect(
        Spacing.cardMargin,
        const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
      );
    });

    test('listItemPadding has horizontal=lg, vertical=md', () {
      expect(
        Spacing.listItemPadding,
        const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
      );
    });

    test('chipPadding has horizontal=lg, vertical=sm', () {
      expect(
        Spacing.chipPadding,
        const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
      );
    });

    test('sectionGap and cardGap are both SizedBoxes of height md', () {
      expect(Spacing.sectionGap.height, Spacing.md);
      expect(Spacing.cardGap.height, Spacing.md);
    });
  });
}
