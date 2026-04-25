import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../providers/vehicle_providers.dart';

/// Hands-free auto-record configuration card on the vehicle edit
/// screen (#1004 phase 6).
///
/// Exposes a master toggle plus the advanced fields (start speed,
/// disconnect-save delay, paired adapter, background-location
/// consent). Phases 2-4 (foreground service, movement detection,
/// disconnect-save) are not yet shipped, so the card renders a
/// soft warning banner explaining that the toggle persists the
/// preference but does not yet activate any background flow.
///
/// Stateless against the vehicle list — every change is funnelled
/// through `vehicleProfileListProvider.save` so the rest of the
/// edit screen continues to read the canonical profile via the
/// usual provider chain.
class AutoRecordSection extends ConsumerWidget {
  /// Stable id of the vehicle being edited. The card is only
  /// useful once the profile has been saved at least once — the
  /// host screen hides this widget while a brand-new vehicle is
  /// still being created.
  final String vehicleId;

  /// Hook for prompting `Permission.locationAlways`. Null defers to
  /// the production `permission_handler` API; widget tests inject a
  /// fake so the prompt sequence can be asserted without binding
  /// the real plugin. Stored as nullable rather than wrapped at
  /// construction so the constructor stays const-eligible.
  final Future<PermissionStatus> Function()? requestBackgroundLocation;

  const AutoRecordSection({
    super.key,
    required this.vehicleId,
    this.requestBackgroundLocation,
  });

  static Future<PermissionStatus> _defaultRequestBackgroundLocation() {
    return Permission.locationAlways.request();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Mirror the defensive lookup pattern used by
    // [VehicleCalibrationModeSelector]: the provider may throw in
    // isolated widget tests that don't wire storage. Falling back to
    // an empty card keeps the surrounding form rendering.
    VehicleProfile profile;
    try {
      profile = ref.watch(vehicleProfileListProvider).firstWhere(
            (v) => v.id == vehicleId,
            orElse: () => const VehicleProfile(id: '', name: ''),
          );
    } catch (e) {
      debugPrint('AutoRecordSection: profile lookup failed: $e');
      return const SizedBox.shrink();
    }

    if (profile.id.isEmpty) {
      // Profile not yet saved — the section is wired to a stable id
      // only, so we hide rather than render a half-broken card.
      return const SizedBox.shrink();
    }

    return SectionCard(
      title: l?.autoRecordSectionTitle ?? 'Auto-record',
      leadingIcon: Icons.smart_toy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('autoRecordToggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(l?.autoRecordToggleLabel ?? 'Auto-record trips'),
            value: profile.autoRecord,
            onChanged: (next) =>
                _persist(ref, profile.copyWith(autoRecord: next)),
          ),
          if (profile.autoRecord) ...[
            const SizedBox(height: 8),
            _PhaseStatusBanner(
              text: l?.autoRecordPhaseStatusBanner ??
                  'Auto-record is being rolled out in phases. Turning '
                      'this on saves your preference, but the background '
                      'recording flow is still in development — your '
                      'trips are not yet auto-captured.',
              theme: theme,
            ),
            const SizedBox(height: 16),
            _SpeedThresholdSlider(
              value: profile.movementStartThresholdKmh,
              label: l?.autoRecordSpeedThresholdLabel ??
                  'Start speed (km/h)',
              onChanged: (v) => _persist(
                ref,
                profile.copyWith(movementStartThresholdKmh: v),
              ),
            ),
            const SizedBox(height: 16),
            _SaveDelaySlider(
              value: profile.disconnectSaveDelaySec,
              label: l?.autoRecordSaveDelayLabel ??
                  'Save delay after disconnect (seconds)',
              onChanged: (v) => _persist(
                ref,
                profile.copyWith(disconnectSaveDelaySec: v),
              ),
            ),
            const SizedBox(height: 16),
            _PairedAdapterRow(
              mac: profile.pairedAdapterMac,
              label: l?.autoRecordPairedAdapterLabel ?? 'Paired adapter',
              empty: l?.autoRecordPairedAdapterNone ??
                  'No adapter paired. Pair one via the OBD2 onboarding '
                      'first.',
              theme: theme,
            ),
            const SizedBox(height: 16),
            _BackgroundLocationRow(
              consent: profile.backgroundLocationConsent,
              label: l?.autoRecordBackgroundLocationLabel ??
                  'Background location allowed',
              requestLabel: l?.autoRecordBackgroundLocationRequest ??
                  'Request permission',
              theme: theme,
              onRequest: () async {
                try {
                  final prompt = requestBackgroundLocation ??
                      _defaultRequestBackgroundLocation;
                  final status = await prompt();
                  if (status.isGranted) {
                    await _persist(
                      ref,
                      profile.copyWith(backgroundLocationConsent: true),
                    );
                  }
                } catch (e) {
                  debugPrint('AutoRecordSection: bg-location prompt: $e');
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _persist(WidgetRef ref, VehicleProfile next) {
    return ref.read(vehicleProfileListProvider.notifier).save(next);
  }
}

class _PhaseStatusBanner extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _PhaseStatusBanner({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.science_outlined,
            color: theme.colorScheme.onTertiaryContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedThresholdSlider extends StatelessWidget {
  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  const _SpeedThresholdSlider({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Clamp persisted value into the slider's bounds — pre-#1004
    // profiles may have any default; we render them at the edge so
    // the user always sees a knob.
    final v = value.clamp(1.0, 15.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            Text(
              v.toStringAsFixed(0),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        Slider(
          key: const Key('autoRecordSpeedThreshold'),
          min: 1,
          max: 15,
          divisions: 14,
          value: v,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SaveDelaySlider extends StatelessWidget {
  final int value;
  final String label;
  final ValueChanged<int> onChanged;

  const _SaveDelaySlider({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value.clamp(30, 300);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            Text(
              v.toString(),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        Slider(
          key: const Key('autoRecordSaveDelay'),
          min: 30,
          max: 300,
          divisions: 27,
          value: v.toDouble(),
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}

class _PairedAdapterRow extends StatelessWidget {
  final String? mac;
  final String label;
  final String empty;
  final ThemeData theme;

  const _PairedAdapterRow({
    required this.mac,
    required this.label,
    required this.empty,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final macText = mac;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        if (macText != null && macText.isNotEmpty)
          Text(
            macText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          )
        else
          Text(
            empty,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _BackgroundLocationRow extends StatelessWidget {
  final bool consent;
  final String label;
  final String requestLabel;
  final ThemeData theme;
  final Future<void> Function() onRequest;

  const _BackgroundLocationRow({
    required this.consent,
    required this.label,
    required this.requestLabel,
    required this.theme,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              consent ? Icons.check_circle : Icons.cancel_outlined,
              size: 20,
              color: consent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
        if (!consent) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('autoRecordBackgroundLocationRequest'),
              onPressed: onRequest,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(requestLabel),
            ),
          ),
        ],
      ],
    );
  }
}
