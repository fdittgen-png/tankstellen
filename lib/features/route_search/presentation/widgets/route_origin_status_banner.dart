// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_origin.dart';
import '../../providers/route_origin_status_provider.dart';

/// The route start's GPS state, under the start field (#4432).
///
/// Nothing while idle. While a fix is being acquired it says so, and
/// offers to type a start instead of waiting. When acquisition failed it
/// names WHY — permission, service, timeout, a stale or imprecise fix —
/// and offers the two remedies the driver actually has: try again, or
/// enter an address. A "Current location" label must never be the only
/// thing on screen while no current location exists.
class RouteOriginStatusBanner extends ConsumerWidget {
  const RouteOriginStatusBanner({
    super.key,
    required this.onRetry,
    required this.onEnterAddress,
  });

  final VoidCallback onRetry;
  final VoidCallback onEnterAddress;

  /// One distinct sentence per state, so each failure reads as its own
  /// remedy rather than as a generic "GPS error".
  static String messageFor(AppLocalizations l10n, RouteOriginStatus status) {
    if (status.locating) return l10n.routeOriginStatusLocating;
    return switch (status.failure) {
      RouteOriginFailure.permissionDenied =>
        l10n.routeOriginStatusPermissionDenied,
      RouteOriginFailure.serviceDisabled =>
        l10n.routeOriginStatusServiceDisabled,
      RouteOriginFailure.timeout => l10n.routeOriginStatusTimeout,
      RouteOriginFailure.staleFix =>
        l10n.routeOriginStatusStaleFix(formatPositionAge(l10n, status.age)),
      RouteOriginFailure.poorAccuracy => l10n.routeOriginStatusPoorAccuracy,
      RouteOriginFailure.unavailable ||
      null =>
        l10n.routeOriginStatusUnavailable,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(routeOriginStatusControllerProvider);
    if (status.isIdle) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = status.locating
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.error;
    return Padding(
      key: ValueKey(
          'route-origin-status-${status.locating ? 'locating' : status.failure!.name}'),
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A static glyph, not a spinner: an indeterminate animation
              // would never let the criteria screen settle while a cold
              // lock runs (up to 30 s), and the sentence says it anyway.
              Icon(
                status.locating
                    ? Icons.location_searching
                    : Icons.location_disabled,
                size: 16,
                color: color,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  messageFor(l10n, status),
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Spacing.md,
            children: [
              if (!status.locating)
                TextButton.icon(
                  key: const ValueKey('route-origin-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: Text(l10n.retry),
                ),
              TextButton.icon(
                key: const ValueKey('route-origin-enter-address'),
                onPressed: onEnterAddress,
                icon: const Icon(Icons.edit_location_alt, size: 16),
                label: Text(l10n.routeOriginStatusEnterAddress),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
