import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/report_type.dart';
import '../../providers/report_form_provider.dart';

/// Builds the "What's wrong?" header plus one radio per report type.
///
/// Returns a flat list of widgets (header + RadioListTile children) so
/// the caller's scrollable parent (usually a ListView) sees each radio
/// as a direct lazy child — wrapping them in a Column caused
/// scroll-extent math to misbehave on tall lists (#571 regression).
///
/// **Call site requirement**: the caller must wrap this list (or the
/// whole scrollable body) in a [RadioGroup<ReportType>] ancestor that
/// owns `groupValue` + `onChanged`. Per-tile `groupValue` / `onChanged`
/// were deprecated in Flutter 3.32 (#710). Tiles read the ancestor via
/// [RadioGroup.maybeOf] — wrapping the scrollable itself keeps the
/// ancestor in scope for every lazy RadioListTile regardless of
/// viewport position.
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
  // Sanity: the provider is watched on the screen that hosts the
  // RadioGroup, so re-reads here are cheap.
  ref.watch(reportFormControllerProvider);

  return [
    Text(
      l10n?.whatsWrong ?? "What's wrong?",
      style: theme.textTheme.titleMedium,
    ),
    const SizedBox(height: 12),
    for (final type in visibleTypes)
      RadioListTile<ReportType>(
        value: type,
        title: Text(type.displayName(l10n)),
        enabled: type.routesToGitHub || hasAnyBackend,
      ),
  ];
}
