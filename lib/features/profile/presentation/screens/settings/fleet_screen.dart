// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Settings → Fleet (#4217 / #4218, ADR 0025 D10).
///
/// The employee's answer to "what does my employer know about me here":
/// which organisation, what role, whether sharing is on, and — in
/// plain sentences — exactly what a fleet manager can and cannot see.
///
/// Read-only by design. The sharing consent is *shown*, not offered:
/// the switch lands with the manager surfaces, together with the single
/// privacy-policy bump (ADR 0025 D6), so this slice takes no new
/// consent and changes no policy version. A test asserts there is no
/// `Switch` on this screen for that reason.
///
/// The tile that opens it is gated on `Feature.fleetMode`, so a
/// personal user never sees fleet administration clutter (#4218).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/section_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/api.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Fleet: organisation, role, sharing state and the
/// manager-visibility list, all read-only.
class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scope = ref.watch(fleetScopeProvider);
    final sharing = ref.watch(fleetSharingConsentProvider);
    final blocked = fleetBlockedReason(l, scope.reason);
    final freshness = fleetFreshnessNote(l, scope.state);
    final role = scope.role;

    return SettingsTopicScaffold(
      title: l.settingsTopicFleetTitle,
      children: [
        SettingsGroupHeader(
          icon: Icons.business_center_outlined,
          title: l.settingsTopicFleetTitle,
          subtitle: l.settingsTopicFleetSubtitle,
        ),
        SectionCard(
          key: const Key('fleetSettingsMembership'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blocked != null)
                Text(blocked)
              else if (scope.isMember) ...[
                _Field(
                  label: l.fleetSettingsOrgLabel,
                  value: scope.orgName ?? '',
                ),
                if (role != null) ...[
                  const SizedBox(height: 8),
                  _Field(
                    label: l.fleetSettingsRoleLabel,
                    value: fleetRoleLabel(l, role),
                  ),
                ],
                if (freshness != null) ...[
                  const SizedBox(height: 8),
                  SettingsHintText(freshness),
                ],
              ] else
                Text(l.fleetSettingsNoFleet),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SectionCard(
          key: const Key('fleetSettingsSharing'),
          child: _Field(
            label: l.fleetSettingsSharingLabel,
            value: sharing
                ? l.fleetSettingsSharingOn
                : l.fleetSettingsSharingOff,
          ),
        ),
        const SizedBox(height: 8),
        SectionCard(
          key: const Key('fleetSettingsVisibility'),
          title: l.fleetSettingsManagerSeesTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bullet(icon: Icons.check, text: l.fleetVisibilityVehicle),
              _Bullet(icon: Icons.check, text: l.fleetVisibilityExpenses),
              _Bullet(icon: Icons.check, text: l.fleetVisibilityCosts),
              _Bullet(
                icon: Icons.block,
                text: l.fleetVisibilityNeverJourneys,
              ),
              _Bullet(
                icon: Icons.block,
                text: l.fleetVisibilityNeverBehaviour,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A label above its value — the read-only shape of a settings row.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsHintText(label),
        Text(value),
      ],
    );
  }
}

/// One line of the visibility matrix: a tick for what a manager sees,
/// a bar for what they never do (ADR 0025 D5).
class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
