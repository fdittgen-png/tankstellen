// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/lessons/rules/hard_accel_rule.dart';
import '../../data/lessons/rules/high_rpm_rule.dart';
import '../../data/lessons/rules/idling_rule.dart';
import '../../data/lessons/rules/low_gear_rule.dart';
import '../../domain/lessons/driving_lesson.dart';

/// "Top wasteful behaviours" card on the Trip detail screen
/// (#1041 phase 2; registry-driven since #2251).
///
/// Renders the ranked [DrivingLesson]s produced by the
/// `DrivingLessonRegistry` (#2251) as a stack of [ListTile]-style rows.
/// Each row shows:
///   * the lesson's localized [DrivingLesson.title] headline,
///   * the lesson's [DrivingLesson.subtitle] caption (null → no caption,
///     as the low-gear row), and
///   * the lesson's [DrivingLesson.trailing] badge (null → no badge).
///
/// The widget is purely presentational — the registry owns evaluation,
/// ranking, and string resolution; the card trusts the caller's order
/// (lessons arrive ranked by impact, the low-gear lesson first). Renders
/// an empty-state message when [lessons] is empty so the card never
/// silently disappears.
///
/// Before #2251 the card took the legacy `DrivingInsight` cost lines and
/// a `secondsBelowOptimalGear` metric and built the headlines inline.
/// That logic now lives in the lesson rules; the rendered output is
/// unchanged — the same trips surface the same rows.
class DrivingInsightsCard extends StatelessWidget {
  /// Ranked lessons from `DrivingLessonRegistry.evaluate()`. Empty list
  /// → empty-state row.
  final List<DrivingLesson> lessons;

  const DrivingInsightsCard({
    super.key,
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.insightCardTitle ?? 'Top wasteful behaviours',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (lessons.isEmpty)
              _EmptyState(
                message: l?.insightEmptyState ??
                    'No notable inefficiencies — keep it up!',
              )
            else
              for (final lesson in lessons) _LessonTile(lesson: lesson),
          ],
        ),
      ),
    );
  }
}

/// One row in the [DrivingInsightsCard], rendered from a
/// [DrivingLesson]. Title always; subtitle / trailing only when the
/// lesson carries them (the low-gear lesson has neither — matching the
/// legacy gear-coaching row).
class _LessonTile extends StatelessWidget {
  final DrivingLesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = lesson.subtitle;
    final trailing = lesson.trailing;

    return ListTile(
      key: ValueKey('insight_tile_${lesson.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _iconFor(lesson),
        color: _colorFor(lesson.polarity, theme),
      ),
      title: Text(lesson.title),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: trailing == null
          ? null
          : Text(
              trailing,
              style: theme.textTheme.titleSmall?.copyWith(
                color: _colorFor(lesson.polarity, theme),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
    );
  }

  IconData _iconFor(DrivingLesson lesson) {
    switch (lesson.id) {
      case highRpmLessonId:
        return Icons.speed;
      case hardAccelLessonId:
        return Icons.flash_on;
      case idlingLessonId:
        return Icons.hourglass_empty;
      case lowGearLessonId:
        return Icons.swap_vert;
      default:
        // #2791 — a positive lesson with no dedicated icon reads as praise
        // (the eco leaf), not a neutral info glyph.
        return lesson.polarity == LessonPolarity.positive
            ? Icons.eco
            : Icons.info_outline;
    }
  }

  /// #2791 — tile tint by tone: praise green (primary), neutral muted, waste
  /// the error red the card used to hard-code for every lesson.
  Color _colorFor(LessonPolarity polarity, ThemeData theme) {
    switch (polarity) {
      case LessonPolarity.positive:
        return theme.colorScheme.primary;
      case LessonPolarity.info:
        return theme.colorScheme.onSurfaceVariant;
      case LessonPolarity.negative:
        return theme.colorScheme.error;
    }
  }
}

/// Empty-state row used when the registry found nothing above the noise
/// floor. Kept inline rather than reusing `core/widgets/empty_state.dart`
/// because that widget is full-screen and would dominate the trip detail
/// scroll view.
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(
            Icons.thumb_up_alt_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
