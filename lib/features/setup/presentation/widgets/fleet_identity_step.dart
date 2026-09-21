// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Onboarding step where a fleet driver says *which* fleet (#4217,
/// Epic #4211, ADR 0025 D2/D3).
///
/// Shown only when the user picked the company-vehicle intent on the
/// profile-choice step; a personal user never sees it.
///
/// Three mutually exclusive faces, decided by [FleetScope] and never by
/// a failed attempt:
///
///   1. **Blocked** — cloud sync is off, the backend is the community
///      project, or the TankSync identity is still anonymous. The
///      controls are not rendered at all and the reason is, in full
///      (D2: "disabled with a reason", never a silent failure).
///   2. **Member** — the account is already in an organisation; the
///      step confirms which one and with what role.
///   3. **Join** — an invite code (typed or scanned) plus, for the
///      person setting the fleet up, F2's create-organisation RPC.
///
/// The step never blocks the wizard: Next stays enabled, because a
/// driver who cannot reach their administrator today must still be able
/// to finish setting the app up (the same choice is in Settings →
/// Fleet).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/api.dart';
import '../../../sync/api.dart' show QrScannerScreen;
import '../../providers/onboarding_wizard_provider.dart';

/// The wizard page that binds this device to one organisation.
class FleetIdentityStep extends ConsumerStatefulWidget {
  const FleetIdentityStep({super.key});

  @override
  ConsumerState<FleetIdentityStep> createState() => _FleetIdentityStepState();
}

class _FleetIdentityStepState extends ConsumerState<FleetIdentityStep> {
  late final TextEditingController _inviteCode;
  late final TextEditingController _orgName;

  @override
  void initState() {
    super.initState();
    // Seeded from the wizard state so stepping back onto this page
    // shows what was typed before (#4217 — back preserves data).
    final wizard = ref.read(onboardingWizardControllerProvider);
    _inviteCode = TextEditingController(text: wizard.fleetInviteCode);
    _orgName = TextEditingController(text: wizard.fleetOrgName);
  }

  @override
  void dispose() {
    _inviteCode.dispose();
    _orgName.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (!mounted || scanned == null || scanned.isEmpty) return;
    _onInviteCodeChanged(scanned.trim());
    setState(() => _inviteCode.text = scanned.trim());
  }

  void _onInviteCodeChanged(String value) {
    ref.read(onboardingWizardControllerProvider.notifier)
        .setFleetInviteCode(value);
    setState(() {});
  }

  void _onOrgNameChanged(String value) {
    ref.read(onboardingWizardControllerProvider.notifier)
        .setFleetOrgName(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scope = ref.watch(fleetScopeProvider);
    final blocked = fleetBlockedReason(l, scope.reason);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.fleetIdentityTitle,
            style: AppText.title(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (blocked != null)
            _ReasonCard(key: const Key('fleetIdentityBlocked'), text: blocked)
          else if (scope.isMember)
            _MemberCard(scope: scope)
          else
            ..._joinForm(l, theme),
          const SizedBox(height: 16),
          Text(
            l.fleetIdentityLater,
            style: AppText.label(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _joinForm(AppLocalizations l, ThemeData theme) {
    final join = ref.watch(fleetJoinControllerProvider);
    final code = _inviteCode.text.trim();
    final name = _orgName.text.trim();
    final failure = join.failure;
    return [
      Text(l.fleetIdentityIntro, style: AppText.body(context)),
      const SizedBox(height: 16),
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('fleetInviteCodeField'),
              controller: _inviteCode,
              enabled: !join.busy,
              textInputAction: TextInputAction.done,
              onChanged: _onInviteCodeChanged,
              decoration: InputDecoration(
                labelText: l.fleetInviteCodeLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('fleetScanQrButton'),
                onPressed: join.busy ? null : () => unawaited(_scan()),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l.fleetScanQrCode),
              ),
            ),
            _Action(
              buttonKey: const Key('fleetJoinButton'),
              label: l.fleetJoinButton,
              icon: Icons.group_add_outlined,
              busy: join.busy,
              disabledReason: code.isEmpty ? l.fleetBlockedEnterCode : null,
              onPressed: () => unawaited(
                ref
                    .read(fleetJoinControllerProvider.notifier)
                    .joinWithInviteCode(code),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SectionCard(
        title: l.fleetCreateSectionTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('fleetOrgNameField'),
              controller: _orgName,
              enabled: !join.busy,
              textInputAction: TextInputAction.done,
              onChanged: _onOrgNameChanged,
              decoration: InputDecoration(
                labelText: l.fleetOrgNameLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            _Action(
              buttonKey: const Key('fleetCreateButton'),
              label: l.fleetCreateButton,
              icon: Icons.add_business_outlined,
              busy: join.busy,
              disabledReason: name.isEmpty ? l.fleetBlockedEnterName : null,
              onPressed: () => unawaited(
                ref
                    .read(fleetJoinControllerProvider.notifier)
                    .createOrganization(name),
              ),
            ),
          ],
        ),
      ),
      if (failure != null) ...[
        const SizedBox(height: 12),
        _ReasonCard(
          key: const Key('fleetJoinFailure'),
          text: fleetJoinFailureMessage(l, failure),
          color: theme.colorScheme.error,
        ),
      ],
    ];
  }
}

/// A primary action with its own disabled-with-reason caption — the
/// #4217 rule applied per button instead of per wizard step.
class _Action extends StatelessWidget {
  const _Action({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.busy,
    required this.disabledReason,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final bool busy;
  final String? disabledReason;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final blocked = disabledReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (blocked != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(blocked, style: AppText.label(context)),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: buttonKey,
          onPressed: busy || blocked != null ? null : onPressed,
          icon: busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon),
          label: Text(label),
        ),
      ],
    );
  }
}

/// A full-width explanation card — the block reason or the refusal.
class _ReasonCard extends StatelessWidget {
  const _ReasonCard({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppText.body(context).copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// The confirmation face: which organisation, which role, and how fresh
/// that answer is (ADR 0025 D4 — a stale directory says so).
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.scope});

  final FleetScope scope;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final role = scope.role;
    final note = fleetFreshnessNote(l, scope.state);
    return SectionCard(
      key: const Key('fleetIdentityMember'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.fleetMemberOf(scope.orgName ?? ''),
            style: AppText.body(context),
          ),
          if (role != null) ...[
            const SizedBox(height: 4),
            Text(
              l.fleetYourRole(fleetRoleLabel(l, role)),
              style: AppText.label(context),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(note, style: AppText.label(context)),
          ],
        ],
      ),
    );
  }
}
