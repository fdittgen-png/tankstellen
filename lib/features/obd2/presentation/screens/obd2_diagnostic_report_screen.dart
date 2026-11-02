// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/obd2_full_diagnostic_provider.dart';
import '../widgets/obd2_report_cards.dart';

/// #4552 (Epic #4547) — the per-system health report of one full
/// diagnostic recording: a summary line, an honest caveat, then one
/// traffic-light card per system (battery & charging, gearbox & drive,
/// engine, fuel & mixture, emissions, fault codes), ordered so the
/// systems with a verdict come first.
class Obd2DiagnosticReportScreen extends ConsumerWidget {
  const Obd2DiagnosticReportScreen({super.key, required this.recording});

  final Obd2DiagnosticRecording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final report = ref.watch(obd2DiagnosticReportProvider(recording.file.path));
    return PageScaffold(
      title: l.obd2ReportTitle,
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(l.obd2ReportFailed)),
        data: (r) => _ReportBody(report: r),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final DiagnosticReport report;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cards = <Obd2ReportSystemCard>[
      _electrical(l),
      _drive(l),
      _engine(l),
      _mixture(l),
      _emissions(l),
      _faults(l),
    ]..sort((a, b) => _rank(a.verdict).compareTo(_rank(b.verdict)));
    return ListView(
      key: const Key('obd2DiagnosticReportList'),
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: Text(
            l.obd2ReportSummary(
              formatWhole(report.duration.inMinutes),
              formatWhole(report.readings),
              formatWhole(report.distinctValues),
            ),
            style: AppText.title(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.md, Spacing.xs, Spacing.md, Spacing.sm),
          child: Text(l.obd2ReportDisclaimer, style: AppText.label(context)),
        ),
        ...cards,
        if (report.unanswered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(
              l.obd2ReportUnanswered(report.unanswered.join(', ')),
              style: AppText.label(context),
            ),
          ),
      ],
    );
  }

  /// Worst first: what needs attention leads the page.
  static int _rank(HealthVerdict v) => switch (v) {
        HealthVerdict.problem => 0,
        HealthVerdict.check => 1,
        HealthVerdict.good => 2,
        HealthVerdict.notReported => 3,
      };

  Obd2ReportSystemCard _electrical(AppLocalizations l) {
    final e = report.electrical;
    final lines = <String>[];
    final avg = e.runningAvgV, min = e.runningMinV;
    if (avg != null && min != null) {
      if (e.dipCount > 0) {
        lines.add(l.obd2ReportElectricalDips(
            formatWhole(e.dipCount), formatOneDecimal(min)));
      }
      lines.add(avg < ElectricalThresholds.chargingLowV
          ? l.obd2ReportElectricalLow(
              formatOneDecimal(avg), formatOneDecimal(min))
          : l.obd2ReportElectricalGood(
              formatOneDecimal(avg), formatOneDecimal(min)));
    }
    final rest = e.restV;
    if (rest != null) lines.add(l.obd2ReportElectricalRest(formatOneDecimal(rest)));
    return Obd2ReportSystemCard(
      key: const Key('obd2ReportElectrical'),
      icon: Icons.battery_charging_full_outlined,
      title: l.obd2ReportElectricalTitle,
      verdict: e.verdict,
      lines: lines,
    );
  }

  Obd2ReportSystemCard _drive(AppLocalizations l) {
    final t = report.transmission;
    final lines = <String>[
      l.analysisTransmissionScope,
      if (t.verdict == HealthVerdict.good) l.obd2ReportDriveGood,
      if (t.episodes.isNotEmpty)
        l.obd2ReportDriveEpisodes(formatWhole(t.episodes.length)),
      if (!t.gearReported)
        l.obd2ReportDriveNoGear,
    ];
    final details = [
      for (final ep in t.episodes)
        (ep.neutral
            ? l.obd2ReportDriveEpisodeNeutral
            : l.obd2ReportDriveEpisode)(
          formatOffset(ep.at),
          formatWhole(ep.speedKmh),
          formatWhole(ep.rpm),
          formatVolts(l, ep.voltageV),
        ),
    ];
    return Obd2ReportSystemCard(
      key: const Key('obd2ReportDrive'),
      icon: Icons.settings_outlined,
      title: l.obd2ReportDriveTitle,
      verdict: t.verdict,
      lines: lines,
      details: details,
    );
  }

  Obd2ReportSystemCard _engine(AppLocalizations l) {
    final e = report.engine;
    final max = e.coolantMaxC;
    final lines = <String>[
      if (max != null)
        switch (e.verdict) {
          HealthVerdict.problem => l.obd2ReportEngineHot(formatWhole(max)),
          HealthVerdict.check => l.obd2ReportEngineCold(
              formatWhole(max), formatWhole(e.runningMinutes)),
          _ => l.obd2ReportEngineGood(formatWhole(max)),
        },
    ];
    return Obd2ReportSystemCard(
      key: const Key('obd2ReportEngine'),
      icon: Icons.thermostat_outlined,
      title: l.obd2ReportEngineTitle,
      verdict: e.verdict,
      lines: lines,
    );
  }

  Obd2ReportSystemCard _mixture(AppLocalizations l) {
    final m = report.mixture;
    final trim = m.avgTrimPct;
    final lines = <String>[
      if (trim != null)
        m.verdict == HealthVerdict.good
            ? l.obd2ReportMixtureGood(formatSigned(trim))
            : trim < 0
                ? l.obd2ReportMixtureRich(formatSigned(trim))
                : l.obd2ReportMixtureLean(formatSigned(trim)),
    ];
    return Obd2ReportSystemCard(
      key: const Key('obd2ReportMixture'),
      icon: Icons.local_gas_station_outlined,
      title: l.obd2ReportMixtureTitle,
      verdict: m.verdict,
      lines: lines,
    );
  }

  Obd2ReportSystemCard _emissions(AppLocalizations l) {
    final e = report.emissions;
    final cat = e.catalystMaxC;
    final lines = <String>[
      if (cat != null)
        e.verdict == HealthVerdict.problem
            ? l.obd2ReportCatalystHot(formatWhole(cat))
            : l.obd2ReportCatalyst(formatWhole(cat)),
      if (e.evapMinPa != null && e.evapMaxPa != null)
        l.obd2ReportEvap(formatWhole(e.evapMinPa!), formatWhole(e.evapMaxPa!)),
    ];
    return Obd2ReportSystemCard(
      key: const Key('obd2ReportEmissions'),
      icon: Icons.air_outlined,
      title: l.obd2ReportEmissionsTitle,
      verdict: e.verdict,
      lines: lines,
    );
  }

  Obd2ReportSystemCard _faults(AppLocalizations l) {
    final f = report.faults;
    final none = f.stored.isEmpty && f.pending.isEmpty && f.permanent.isEmpty;
    final lines = <String>[
      if (f.milOn ?? false) l.obd2ReportFaultsMil,
      if (f.verdict == HealthVerdict.good && none) l.obd2ReportFaultsNone,
    ];
    String row(String label, String code) => l.obd2ReportFaultRow(
        label, code, dtcGroupLabel(l, dtcGroupOf(code)));
    final details = [
      for (final c in f.stored) row(l.obd2ReportFaultsStored, c),
      for (final c in f.permanent) row(l.obd2ReportFaultsPermanent, c),
      for (final c in f.pending) row(l.obd2ReportFaultsPending, c),
      for (final c in f.freezeFrame) row(l.obd2ReportFaultsFreezeFrame, c),
    ];
    return Obd2ReportSystemCard(
      key: const Key('obd2ReportFaults'),
      icon: Icons.report_problem_outlined,
      title: l.obd2ReportFaultsTitle,
      verdict: f.verdict,
      lines: lines,
      details: details,
    );
  }
}
