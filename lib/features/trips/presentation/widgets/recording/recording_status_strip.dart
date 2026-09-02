// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/recording_link_status_provider.dart';
import 'recording_status_l10n.dart';
import 'recording_status_sheets.dart';

/// The recording screen's status strip (#3916, Epic #3914): two tappable
/// pills directly under the hero — the OBD2 link (live / reconnecting /
/// GPS only / engine off / no adapter) and the GPS fix (precise /
/// approximate / none, plus coverage so far). Each opens a plain-language
/// sheet saying what the state means and what the driver can do.
///
/// Rebuild-cheap by construction: the strip watches ONE derived value
/// ([recordingLinkStatusProvider]) whose fields are all `select`ed from
/// the 4 Hz live reading, and the value has structural equality, so an
/// unchanged status never rebuilds the pills.
class RecordingStatusStrip extends ConsumerWidget {
  const RecordingStatusStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(recordingLinkStatusProvider);
    final reconnecting = status.obd2 is Obd2StatusReconnecting;
    return Row(
      key: const Key('recordingStatusStrip'),
      children: [
        Expanded(
          child: _StatusPill(
            key: const Key('recordingObd2StatusChip'),
            icon: obd2StatusIcon(status.obd2),
            label: obd2StatusChipLabel(l, status.obd2),
            emphasized: status.obd2 is Obd2StatusLive,
            busy: reconnecting,
            onTap: () => unawaited(showObd2StatusSheet(
              context,
              ref,
              status: status.obd2,
              adapterName: status.adapterName,
            )),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusPill(
            key: const Key('recordingGpsStatusChip'),
            icon: gpsStatusIcon(status.gps),
            label: gpsStatusChipLabel(l, status.gps),
            emphasized: status.gps.quality == GpsFixQuality.precise,
            busy: false,
            onTap: () => unawaited(showGpsStatusSheet(
              context,
              status: status.gps,
            )),
          ),
        ),
      ],
    );
  }
}

/// One chip-styled, full-width tappable row: glyph + single-line label
/// (ellipsizes under text expansion rather than overflowing) + a
/// chevron hinting at the sheet. [emphasized] tints the pill with the
/// primary container (the "all good" reading); [busy] swaps the glyph
/// for a small spinner while a reconnect is in flight.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.emphasized,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool emphasized;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        emphasized ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final foreground =
        emphasized ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: AppRadius.xl,
        child: InkWell(
          borderRadius: AppRadius.xl,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if (busy)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: foreground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
