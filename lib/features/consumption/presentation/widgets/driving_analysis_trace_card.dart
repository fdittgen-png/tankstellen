// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../data/analysis/driving_analysis_trace.dart';
import '../../data/analysis/driving_analysis_trace_export.dart';
import '../../domain/driving_score.dart';
import '../../domain/gps_driving_features.dart';
import '../../domain/lessons/driving_lesson.dart';
import '../../domain/trip_summary.dart';

/// Dev-only and self-hiding: renders nothing unless [Feature.debugMode] is on
/// (the GPS / OBD2 diagnostics-card convention). Exports the trip's
/// driving-analysis trace — GPS KPIs, IMU counts, the computed score and the
/// firing lessons — as JSON to Downloads + the share sheet, with a `comment`
/// slot the maintainer fills in. Annotated traces shared back give labelled
/// real-trip data to calibrate the GPS verdict thresholds (#2804, Epic #2789
/// C6), instead of guessing cutoffs that could contradict the smooth-driving
/// lesson.
class DrivingAnalysisTraceCard extends ConsumerWidget {
  const DrivingAnalysisTraceCard({
    super.key,
    required this.summary,
    required this.score,
    required this.lessons,
    this.gpsFeatures,
  });

  final TripSummary summary;
  final DrivingScore score;
  final List<DrivingLesson> lessons;
  final GpsDrivingFeatures? gpsFeatures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugOn =
        ref.watch(enabledFeaturesProvider).contains(Feature.debugMode);
    if (!debugOn) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.drivingTraceCardTitle ?? 'Driving-analysis trace (dev)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l?.drivingTraceCardBody ??
                  "Export this trip's GPS KPIs, score and lessons as JSON, "
                      'write how the drive felt in the comment field, and '
                      'share it back to calibrate the thresholds.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => _export(context),
                icon: const Icon(Icons.bug_report_outlined),
                label: Text(
                  l?.drivingTraceExportAction ?? 'Export analysis trace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final trace = DrivingAnalysisTrace(
      capturedAt: DateTime.now(),
      summary: summary,
      score: score,
      lessons: lessons,
      gpsFeatures: gpsFeatures,
    );
    final ok = await DrivingAnalysisTraceExport.export(trace);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (l?.drivingTraceExported ??
                  'Analysis trace saved to Downloads.')
              : (l?.drivingTraceExportFailed ??
                  "Couldn't export the analysis trace."),
        ),
      ),
    );
  }
}
