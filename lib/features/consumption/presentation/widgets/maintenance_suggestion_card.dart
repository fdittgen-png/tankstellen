import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/maintenance_suggestion.dart';
import '../../providers/maintenance_provider.dart';

/// Predictive-maintenance suggestion card (#1124).
///
/// Renders one [MaintenanceSuggestion] above the Trips list with a
/// localised title + body, plus a pair of actions:
///
///   * **Dismiss** — silences the card for 24 h. Useful when the user
///     wants to think about it but doesn't want a 30-day blackout.
///   * **Snooze 30 days** — silences the card for the standard
///     [MaintenanceSnoozeRepository.defaultSnoozeDuration] (30 days).
///
/// The card wraps its visible content in a single
/// `Semantics(container: true, label: ..., child: ExcludeSemantics(...))`
/// so TalkBack reads it as one coherent announcement —
/// "Maintenance suggestion: Idle RPM has crept up by 9 percent over
/// your last 12 trips" — instead of a stream of isolated chip texts
/// (matches the accessibility convention codified in CLAUDE.md
/// "group-label chip wraps").
class MaintenanceSuggestionCard extends ConsumerWidget {
  final MaintenanceSuggestion suggestion;

  const MaintenanceSuggestionCard({
    super.key,
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final percent = suggestion.observedDelta.round().toString();
    final tripCount = suggestion.sampleTripCount;

    final title = _titleFor(l, suggestion.signal);
    final body = _bodyFor(l, suggestion.signal, percent, tripCount);
    // Compose the merged Semantics label from the user-visible copy
    // so TalkBack announces the same words a sighted user reads —
    // assistive text MUST track the visible text, otherwise screen-
    // reader users hear something different from what they could
    // ask a sighted partner about.
    final mergedLabel = '$title. $body';

    final dismissLabel =
        l?.maintenanceActionDismiss ?? 'Dismiss';
    final snoozeLabel =
        l?.maintenanceActionSnooze ?? 'Snooze 30 days';

    return Semantics(
      container: true,
      label: mergedLabel,
      child: ExcludeSemantics(
        child: Card(
          key: ValueKey('maintenance-${suggestion.signal.name}'),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 12),
                      child: Icon(
                        Icons.build_circle_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Buttons. TextButtons are >= 48 dp tall by default in
                // Material 3, satisfying androidTapTargetGuideline
                // without needing a custom min-size constraint.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: ValueKey(
                          'maintenance-${suggestion.signal.name}-dismiss'),
                      onPressed: () => ref
                          .read(
                              maintenanceSuggestionsControllerProvider.notifier)
                          .dismissForToday(suggestion.signal),
                      child: Text(dismissLabel),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      key: ValueKey(
                          'maintenance-${suggestion.signal.name}-snooze'),
                      onPressed: () => ref
                          .read(
                              maintenanceSuggestionsControllerProvider.notifier)
                          .snoozeForDefault(suggestion.signal),
                      child: Text(snoozeLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(AppLocalizations? l, MaintenanceSignal signal) {
    switch (signal) {
      case MaintenanceSignal.idleRpmCreep:
        return l?.maintenanceSignalIdleRpmCreepTitle ??
            'Idle RPM creep detected';
      case MaintenanceSignal.mafDeviation:
        return l?.maintenanceSignalMafDeviationTitle ??
            'Possible intake restriction';
    }
  }

  String _bodyFor(
    AppLocalizations? l,
    MaintenanceSignal signal,
    String percent,
    int tripCount,
  ) {
    switch (signal) {
      case MaintenanceSignal.idleRpmCreep:
        return l?.maintenanceSignalIdleRpmCreepBody(percent, tripCount) ??
            'Idle RPM has crept up by $percent% over your last $tripCount '
                'trips. Possible early sign of a clogged air filter or '
                'sensor drift.';
      case MaintenanceSignal.mafDeviation:
        return l?.maintenanceSignalMafDeviationBody(percent, tripCount) ??
            'Cruise fuel rate has dropped by $percent% over your last '
                '$tripCount trips. Possible sign of a clogged air filter '
                'or restricted intake — worth a check-up.';
    }
  }
}

/// List wrapper used by the consumption / trips tab to render every
/// active suggestion as a column of cards. Renders nothing when the
/// suggestions list is empty so callers can drop it into their build
/// tree unconditionally.
class MaintenanceSuggestionList extends ConsumerWidget {
  const MaintenanceSuggestionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(maintenanceSuggestionsProvider);
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('maintenance_suggestion_list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in suggestions)
          MaintenanceSuggestionCard(
            key: ValueKey('maintenance-card-${s.signal.name}'),
            suggestion: s,
          ),
      ],
    );
  }
}
