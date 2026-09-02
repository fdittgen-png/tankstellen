// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
// #3781 — the one guarded reset run (barrel import: boundary-exempt).
import '../../../../obd2/api.dart' show runObd2ConnectionReset;
import '../../../providers/recording_link_status_provider.dart';
import 'recording_status_l10n.dart';

/// The plain-language sheets behind the recording screen's status chips
/// (#3916): a title row (glyph + name), two-to-three sentences saying
/// what the state means for the recording and what the driver can do,
/// and — only where it helps — the existing shared connection reset.

/// Open the OBD2 status sheet for [status]. [adapterName] heads the sheet
/// when known; otherwise the generic "OBD2 link" title.
Future<void> showObd2StatusSheet(
  BuildContext context,
  WidgetRef ref, {
  required RecordingObd2Status status,
  String? adapterName,
}) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _StatusSheet(
      key: const Key('recordingObd2StatusSheet'),
      icon: obd2StatusIcon(status),
      title: adapterName ?? l.recordingObd2SheetTitle,
      subtitle: adapterName == null ? null : l.recordingObd2SheetTitle,
      body: obd2StatusSheetBody(l, status),
      action: obd2StatusOffersReset(status)
          ? _ResetAction(
              // The reset's own snackbar needs the SCREEN's messenger,
              // not the sheet's transient context.
              onRun: () => runObd2ConnectionReset(context, ref),
            )
          : null,
    ),
  );
}

/// Open the GPS status sheet for [status].
Future<void> showGpsStatusSheet(
  BuildContext context, {
  required RecordingGpsStatus status,
}) {
  final l = AppLocalizations.of(context);
  final coverage = status.coveragePercent;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _StatusSheet(
      key: const Key('recordingGpsStatusSheet'),
      icon: gpsStatusIcon(status),
      title: l.recordingGpsSheetTitle,
      subtitle: gpsFixLabel(l, status),
      body: gpsStatusSheetBody(l, status),
      footnote: coverage == null ? null : l.recordingGpsSheetCoverage(coverage),
    ),
  );
}

class _StatusSheet extends StatelessWidget {
  const _StatusSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.subtitle,
    this.footnote,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String body;
  final String? footnote;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              body,
              key: const Key('recordingStatusSheetBody'),
              style: theme.textTheme.bodyMedium,
            ),
            if (footnote != null) ...[
              const SizedBox(height: 8),
              Text(
                footnote!,
                key: const Key('recordingStatusSheetFootnote'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                ?action,
                FilledButton.tonal(
                  key: const Key('recordingStatusSheetClose'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.recordingSheetClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The shared connection reset as a sheet action: closes the sheet and
/// runs the guarded reset (double-tap safe — the button is gone with
/// the sheet).
class _ResetAction extends StatelessWidget {
  const _ResetAction({required this.onRun});

  final Future<void> Function() onRun;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextButton(
      key: const Key('recordingStatusSheetReset'),
      onPressed: () {
        Navigator.of(context).pop();
        unawaited(onRun());
      },
      child: Text(l.obd2ResetConnection),
    );
  }
}
