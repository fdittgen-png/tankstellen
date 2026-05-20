import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/providers/consumption_providers.dart';
import '../../domain/monthly_summary.dart';
import '../widgets/charts_tab.dart';

/// Hook for the share-sheet handoff used by [CarbonDashboardScreen]
/// (#2005). Production sends [ShareParams] straight to
/// `SharePlus.instance.share`; widget tests substitute a fake via
/// [debugCarbonShareSinkOverride] to assert the outgoing payload
/// without launching the real OS share sheet.
typedef CarbonShareSink = Future<void> Function(ShareParams params);

/// See [CarbonShareSink].
@visibleForTesting
CarbonShareSink? debugCarbonShareSinkOverride;

Future<void> _defaultCarbonShareSink(ShareParams params) =>
    SharePlus.instance.share(params);

/// Carbon dashboard: monthly charts derived from the existing
/// [fillUpListProvider] — no new storage or providers.
class CarbonDashboardScreen extends ConsumerWidget {
  const CarbonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillUps = ref.watch(fillUpListProvider);
    final l = AppLocalizations.of(context);

    final summaries = MonthlyAggregator.byMonth(fillUps);
    final last12 = MonthlyAggregator.lastN(summaries, 12);
    final totalCo2 = MonthlyAggregator.totalCo2(summaries);
    final totalCost = MonthlyAggregator.totalCost(summaries);

    final hasData = fillUps.isNotEmpty;

    final Widget body = hasData
        ? ChartsTab(
            summaries: last12,
            totalCost: totalCost,
            totalCo2: totalCo2,
          )
        : EmptyState(
            icon: Icons.eco_outlined,
            title: l?.carbonEmptyTitle ?? 'No data yet',
            subtitle: l?.carbonEmptySubtitle ??
                'Log fill-ups to see your carbon dashboard.',
          );

    return PageScaffold(
      title: l?.carbonDashboardTitle ?? 'Carbon dashboard',
      bannerIcon: Icons.eco_outlined,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      // #2005 — share-summary button. Hidden when the user has no
      // fill-ups (the empty-state body covers that case); sharing an
      // empty summary would just be noise. Mirrors the share-sink
      // override pattern already used by the privacy dashboard /
      // full backup exporter so widget tests can assert the outgoing
      // payload without launching the real OS share sheet.
      actions: hasData
          ? <Widget>[
              IconButton(
                key: const Key('carbon-dashboard-share'),
                icon: const Icon(Icons.share_outlined),
                tooltip: l?.tooltipShare ?? 'Share',
                onPressed: () => _shareSummary(
                  l: l,
                  totalCost: totalCost,
                  totalCo2: totalCo2,
                ),
              ),
            ]
          : null,
      bodyPadding: EdgeInsets.zero,
      body: body,
    );
  }

  /// Build a plain-text summary of the carbon dashboard's headline
  /// figures and hand it to the share sink (#2005). The body uses
  /// existing ARB keys (`carbonDashboardTitle`,
  /// `carbonSummaryTotalCost`, `carbonSummaryTotalCo2`) — no new
  /// 24-locale fill is needed.
  Future<void> _shareSummary({
    required AppLocalizations? l,
    required double totalCost,
    required double totalCo2,
  }) async {
    final title = l?.carbonDashboardTitle ?? 'Carbon dashboard';
    final costLabel = l?.carbonSummaryTotalCost ?? 'Total cost';
    final co2Label = l?.carbonSummaryTotalCo2 ?? 'Total CO2';
    // Same formatting as the on-screen `_SummaryRow` (charts_tab.dart):
    // integer cost with the currency suffix, integer kg for CO2.
    // i18n-ignore: language-neutral number/unit format mask.
    final body = '$title\n\n'
        '$costLabel: ${totalCost.toStringAsFixed(0)} ${PriceFormatter.currency}\n'
        '$co2Label: ${totalCo2.toStringAsFixed(0)} kg';
    final sink = debugCarbonShareSinkOverride ?? _defaultCarbonShareSink;
    try {
      await sink(ShareParams(text: body, subject: title));
    } on Object catch (e, st) {
      // Share-sheet wiring failures should never crash the screen.
      // The user can re-tap; the failure ends in the debug console.
      debugPrint('CarbonDashboardScreen: share failed: $e\n$st');
    }
  }
}
