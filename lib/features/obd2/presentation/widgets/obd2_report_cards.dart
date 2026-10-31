// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/primary_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/obd2_full_diagnostic_provider.dart';

/// #4552 — one system card of the diagnostic report: an icon, the
/// system name, a traffic-light verdict chip and the plain sentences
/// that explain it.
class Obd2ReportSystemCard extends StatelessWidget {
  const Obd2ReportSystemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.verdict,
    required this.lines,
    this.details = const [],
  });

  final IconData icon;
  final String title;
  final HealthVerdict verdict;

  /// The explanation sentences.
  final List<String> lines;

  /// Secondary rows (episodes, codes) under the sentences.
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: verdictColor(context, verdict)),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(title, style: AppText.title(context))),
            ],
          ),
          // Under the title, not beside it: a long localized title and
          // the chip never fight for one 320 dp row.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: VerdictChip(verdict: verdict),
          ),
          if (verdict == HealthVerdict.notReported)
            Text(l.obd2ReportNotReported, style: AppText.body(context)),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Text(line, style: AppText.body(context)),
            ),
          for (final d in details)
            Padding(
              padding: const EdgeInsets.only(left: Spacing.sm, top: Spacing.xs),
              child: Text(d, style: AppText.label(context)),
            ),
        ],
      ),
    );
  }
}

/// The traffic-light chip.
class VerdictChip extends StatelessWidget {
  const VerdictChip({super.key, required this.verdict});

  final HealthVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = switch (verdict) {
      HealthVerdict.good => l.obd2ReportVerdictGood,
      HealthVerdict.check => l.obd2ReportVerdictCheck,
      HealthVerdict.problem => l.obd2ReportVerdictProblem,
      HealthVerdict.notReported => l.obd2ReportVerdictNotReported,
    };
    return Chip(
      avatar: Icon(verdictIcon(verdict),
          size: 18, color: verdictColor(context, verdict)),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Colour of [v]: success / warning / error / outline.
Color verdictColor(BuildContext context, HealthVerdict v) => switch (v) {
      HealthVerdict.good => DarkModeColors.success(context),
      HealthVerdict.check => DarkModeColors.warning(context),
      HealthVerdict.problem => DarkModeColors.error(context),
      HealthVerdict.notReported => Theme.of(context).colorScheme.outline,
    };

/// Glyph of [v] — the verdict never rides on colour alone.
IconData verdictIcon(HealthVerdict v) => switch (v) {
      HealthVerdict.good => Icons.check_circle_outline,
      HealthVerdict.check => Icons.error_outline,
      HealthVerdict.problem => Icons.warning_amber_outlined,
      HealthVerdict.notReported => Icons.help_outline,
    };

/// `13.8 V`, or the localized "no voltage" when [v] is null.
String formatVolts(AppLocalizations l, double? v) => v == null
    ? l.obd2ReportVoltsUnknown
    : l.obd2ReportVolts(UnitFormatter.formatDecimal(v));

/// One decimal, locale decimal mark.
String formatOneDecimal(double v) => UnitFormatter.formatDecimal(v);

/// Whole number.
String formatWhole(num v) => UnitFormatter.formatDecimal(v.toDouble(),
    fractionDigits: 0);

/// `+12.5` / `-8.0` — the sign is the message for fuel trims.
String formatSigned(double v) =>
    (v >= 0 ? '+' : '') + UnitFormatter.formatDecimal(v);

/// `mm:ss` (or `h:mm:ss`) offset into the recording.
String formatOffset(Duration d) {
  String two(int v) => v.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final mmss = [two(m), two(s)].join(':');
  return h > 0 ? [h.toString(), mmss].join(':') : mmss;
}

/// Localized name of a DTC group.
String dtcGroupLabel(AppLocalizations l, DtcGroup g) => switch (g) {
      DtcGroup.fuelAir => l.dtcGroupFuelAir,
      DtcGroup.ignition => l.dtcGroupIgnition,
      DtcGroup.emissions => l.dtcGroupEmissions,
      DtcGroup.idleElectrical => l.dtcGroupIdleElectrical,
      DtcGroup.computer => l.dtcGroupComputer,
      DtcGroup.transmission => l.dtcGroupTransmission,
      DtcGroup.chassis => l.dtcGroupChassis,
      DtcGroup.body => l.dtcGroupBody,
      DtcGroup.network => l.dtcGroupNetwork,
      DtcGroup.other => l.dtcGroupOther,
    };
