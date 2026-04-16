import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/report_type.dart';
import '../../providers/report_form_provider.dart';

/// Builds the "What's wrong?" header plus one radio per report type.
///
/// Returns a flat list of widgets (header + N radios) rather than a single
/// Column so the caller's scrollable parent (usually a ListView) sees each
/// radio as a direct child. Wrapping them in a Column caused scroll-extent
/// math to misbehave on tall lists (#571 regression in refactor).
///
/// GitHub-routed types (wrongName / wrongAddress) are always selectable;
/// legacy price/status types are disabled when no Tankerkoenig / TankSync
/// backend is available so the user can't submit into the void (#508).
List<Widget> buildReportTypeList(
  BuildContext context,
  WidgetRef ref, {
  required List<ReportType> visibleTypes,
  required bool hasAnyBackend,
}) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context);
  final selectedType = ref.watch(reportFormControllerProvider).selectedType;

  return [
    Text(
      l10n?.whatsWrong ?? "What's wrong?",
      style: theme.textTheme.titleMedium,
    ),
    const SizedBox(height: 12),
    ...visibleTypes.map(
      (type) => RadioListTile<ReportType>(
        value: type,
        groupValue: selectedType,
        title: Text(type.displayName(l10n)),
        onChanged: (type.routesToGitHub || hasAnyBackend)
            ? (v) => ref
                .read(reportFormControllerProvider.notifier)
                .selectType(v)
            : null,
      ),
    ),
  ];
}
