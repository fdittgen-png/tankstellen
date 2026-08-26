// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_trip_evidence.dart';

/// The OBD2 health card as rendered from the TRIP RECORD (#3824), for a trip
/// that captured no per-PID communication diagnostic.
///
/// Split out of `Obd2DiagnosticsCard` to keep both files under the 400-line
/// cap; it is a sibling of `Obd2ReconnectSection` /
/// `Obd2InitTranscriptSection` in that respect.
///
/// Why it exists at all: the diagnostics card previously had exactly one
/// fallback — an empty state asserting *"No OBD2 session recorded — connect
/// an adapter and record a trip with developer mode enabled."* That text was
/// shown for a trip with 324 engine samples at 99.7% coverage over a named
/// adapter. The card knew only that per-PID instrumentation was missing and
/// printed the much stronger claim that nothing had been recorded, together
/// with advice that was wrong twice over (an adapter *was* connected, the
/// trip *was* recorded).
///
/// Every line here comes from data the trip record always carries, so it
/// stays truthful for a past trip after a restart — precisely where the old
/// empty state lied.
class Obd2TripEvidenceCard extends StatelessWidget {
  const Obd2TripEvidenceCard({super.key, required this.evidence});

  final Obd2TripEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final e = evidence;
    final adapter = e.adapterLabel;
    final verdict = e.protocolVerdict;
    final ended = e.terminationReason;
    final duration = e.duration;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ExpansionTile(
        key: const Key('obd2_diagnostics_trip_evidence'),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Icon(Icons.bluetooth_connected_outlined),
        title: Text(l.obd2DiagnosticsTitle, style: theme.textTheme.titleMedium),
        subtitle: Text(
          l.obd2DiagnosticsTripRecordedHeader(
            e.engineSamples,
            e.coveragePercent,
          ),
          style: muted,
        ),
        children: [
          _header(theme, l.obd2DiagnosticsTripEvidenceSection),
          _line(
            theme,
            l.obd2DiagnosticsTripSamplesLine(
              e.engineSamples,
              e.totalSamples,
              e.coveragePercent,
            ),
            const Key('obd2_diag_trip_samples_line'),
          ),
          if (adapter != null)
            _line(theme, l.obd2DiagnosticsTripAdapterLine(adapter),
                const Key('obd2_diag_trip_adapter_line')),
          if (verdict != null)
            _line(theme, l.obd2DiagnosticsTripProtocolLine(verdict),
                const Key('obd2_diag_trip_protocol_line')),
          if (duration != null)
            _line(
                theme,
                l.obd2DiagnosticsTripDurationLine(formatDuration(duration)),
                const Key('obd2_diag_trip_duration_line')),
          if (ended != null)
            _line(theme, l.obd2DiagnosticsTripEndedLine(ended),
                const Key('obd2_diag_trip_ended_line')),
          if (e.fuelMeasured)
            _line(theme, l.obd2DiagnosticsTripFuelMeasured,
                const Key('obd2_diag_trip_fuel_measured')),
          const SizedBox(height: 12),
          Text(
            l.obd2DiagnosticsTripNoPidDetail,
            key: const Key('obd2_diag_trip_no_pid_detail'),
            style: muted,
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            text,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
      );

  Widget _line(ThemeData theme, String text, Key key) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Align(
          key: key,
          alignment: AlignmentDirectional.centerStart,
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      );

  /// `m:ss` / `h:mm:ss` — digits and colons only, so it is language-neutral
  /// and needs no ARB key (and no opt-out marker: nothing here is a
  /// translatable literal reaching a widget).
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$s';
    return '$m:$s';
  }
}
