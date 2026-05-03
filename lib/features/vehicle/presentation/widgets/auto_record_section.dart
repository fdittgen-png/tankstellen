import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../providers/vehicle_providers.dart';

/// Hands-free auto-record configuration card on the vehicle edit
/// screen (#1004 phase 6).
///
/// Exposes a master toggle plus the advanced fields (start speed,
/// disconnect-save delay, paired adapter, background-location
/// consent). #1310 — when the master toggle is on the card renders a
/// state-aware status banner that mirrors the actual orchestrator
/// gate (`pairedAdapterMac` non-empty + `backgroundLocationConsent`
/// true). The banner shows one of three states:
///
///   * Active — both prerequisites satisfied; auto-record arms next
///     drive.
///   * Needs pairing — no `pairedAdapterMac` set. #1400 — the card
///     surfaces a passive informational link pointing the user at
///     the canonical "OBD2 adapter" card below; the actual pair CTA
///     lives there to consolidate the two adapter-pair entry points.
///   * Needs background location — adapter paired but consent
///     missing; the existing background-location row below already
///     surfaces the OS prompt.
///
/// Replaces the pre-#1310 stale phase-status copy that misled users
/// into thinking the feature wasn't shipped — every phase is on
/// master.
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

  /// Hook for prompting `Permission.location` (foreground). Same
  /// shape and rationale as [requestBackgroundLocation] — Android
  /// requires foreground location to be granted before the OS will
  /// even consider an `ACCESS_BACKGROUND_LOCATION` prompt (#1302),
  /// so the widget runs a two-step flow and tests inject both hooks.
  final Future<PermissionStatus> Function()? requestForegroundLocation;

  /// Hook for opening the OS app-settings page. Used as the fallback
  /// for the permanently-denied path on Android 11+, where the runtime
  /// dialog no longer appears and the user has to flip
  /// "Allow all the time" manually. Tests inject a counter so the
  /// rationale-dialog assertion can be made without launching the
  /// real Android intent.
  final Future<void> Function()? openSettings;

  /// Hook invoked when the user taps the passive "Pair an adapter in
  /// the section below" link rendered while the vehicle has no paired
  /// adapter (#1400). Wired by [EditVehicleScreen] to scroll the host
  /// `ListView` to the canonical "OBD2 adapter" card and pulse its
  /// border. Null is permitted (e.g. isolated widget tests that don't
  /// care about scrolling); the link still renders and tapping it is a
  /// safe no-op.
  final VoidCallback? onScrollToObd2Card;

  const AutoRecordSection({
    super.key,
    required this.vehicleId,
    this.requestBackgroundLocation,
    this.requestForegroundLocation,
    this.openSettings,
    this.onScrollToObd2Card,
  });

  static Future<PermissionStatus> _defaultRequestBackgroundLocation() {
    return Permission.locationAlways.request();
  }

  static Future<PermissionStatus> _defaultRequestForegroundLocation() {
    return Permission.location.request();
  }

  static Future<void> _defaultOpenSettings() async {
    await openAppSettings();
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
    } catch (e, st) {
      debugPrint('AutoRecordSection: profile lookup failed: $e\n$st');
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
            _AutoRecordStatusBanner(
              state: _statusFor(profile),
              theme: theme,
              l: l,
              onScrollToObd2Card: onScrollToObd2Card,
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
              onRequest: () => _handleBackgroundLocationRequest(
                context: context,
                ref: ref,
                profile: profile,
                l: l,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _persist(WidgetRef ref, VehicleProfile next) {
    return ref.read(vehicleProfileListProvider.notifier).save(next);
  }

  /// Map the four real states the auto-record orchestrator gates on
  /// to the banner shown on this card (#1310). Mirrors
  /// `AutoRecordOrchestrator._isAutoRecordReady`: a vehicle is
  /// "active" only when `pairedAdapterMac` is non-empty AND
  /// `backgroundLocationConsent` is true.
  _AutoRecordStatus _statusFor(VehicleProfile profile) {
    final mac = profile.pairedAdapterMac;
    if (mac == null || mac.isEmpty) {
      return _AutoRecordStatus.needsPairing;
    }
    if (!profile.backgroundLocationConsent) {
      return _AutoRecordStatus.needsBackgroundLocation;
    }
    return _AutoRecordStatus.active;
  }

  /// Two-step background-location grant flow (#1302).
  ///
  /// 1. Foreground first. Android refuses to even surface the
  ///    "Allow all the time" choice unless ACCESS_FINE_LOCATION (or
  ///    coarse) is already granted, so we prompt that first if the
  ///    status is not yet `granted`. A denial aborts with a snackbar.
  /// 2. Then the background permission. On API <30 the runtime dialog
  ///    handles it; on API 30+ a `permanentlyDenied` status (which
  ///    Android returns after the first denial) sends the user to the
  ///    OS settings page via [openAppSettings] after a rationale
  ///    dialog explains *why* the app needs it.
  ///
  /// Replaces the old silent `try/catch` (#1302) — every failure path
  /// now produces user-visible feedback (snackbar) AND a structured
  /// log entry through [errorLogger].
  Future<void> _handleBackgroundLocationRequest({
    required BuildContext context,
    required WidgetRef ref,
    required VehicleProfile profile,
    required AppLocalizations? l,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.maybeOf(context);
    final foregroundPrompt =
        requestForegroundLocation ?? _defaultRequestForegroundLocation;
    final backgroundPrompt =
        requestBackgroundLocation ?? _defaultRequestBackgroundLocation;
    final openSettingsFn = openSettings ?? _defaultOpenSettings;

    try {
      // Step 1 — foreground location must be granted first.
      final fgStatus = await foregroundPrompt();
      if (!fgStatus.isGranted) {
        if (!context.mounted) return;
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              l?.autoRecordBackgroundLocationForegroundDeniedSnackbar ??
                  'Location permission required',
            ),
          ),
        );
        return;
      }

      // Step 2 — background location. Permanent denial on API 30+
      // can never recover via runtime dialog, so we route through the
      // rationale dialog → Settings fallback instead of re-prompting.
      final bgStatus = await backgroundPrompt();
      if (bgStatus.isGranted) {
        await _persist(
          ref,
          profile.copyWith(backgroundLocationConsent: true),
        );
        return;
      }

      if (bgStatus.isPermanentlyDenied || bgStatus.isRestricted) {
        if (!context.mounted) return;
        await _showRationaleDialog(
          context: context,
          navigator: navigator,
          openSettingsFn: openSettingsFn,
          l: l,
        );
        return;
      }

      // Plain denial — Android <30 will have already shown its dialog
      // and we cannot re-prompt. Surface a rationale so the user can
      // open Settings if they meant to grant.
      if (!context.mounted) return;
      await _showRationaleDialog(
        context: context,
        navigator: navigator,
        openSettingsFn: openSettingsFn,
        l: l,
      );
    } catch (e, st) {
      // Replace the old silent debugPrint with structured logging plus
      // user-visible feedback. Without this the user saw nothing on
      // failure (#1302).
      await errorLogger.log(
        ErrorLayer.ui,
        e,
        st,
        context: const {
          'op': 'autoRecordSection.requestBackgroundLocation',
        },
      );
      if (!context.mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l?.autoRecordBackgroundLocationRequestFailedSnackbar ??
                'Could not request background location',
          ),
        ),
      );
    }
  }

  Future<void> _showRationaleDialog({
    required BuildContext context,
    required NavigatorState? navigator,
    required Future<void> Function() openSettingsFn,
    required AppLocalizations? l,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('autoRecordBackgroundLocationRationaleDialog'),
          title: Text(
            l?.autoRecordBackgroundLocationRationaleTitle ??
                'Why "Allow all the time"?',
          ),
          content: Text(
            l?.autoRecordBackgroundLocationRationaleBody ??
                'Auto-record streams GPS coordinates from the OBD-II '
                    'foreground service while the screen is off so your '
                    'trip route stays accurate. Android requires the '
                    '"Allow all the time" option for that to keep '
                    'working after the device locks.',
          ),
          actions: [
            TextButton(
              key: const Key('autoRecordBackgroundLocationOpenSettings'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openSettingsFn();
              },
              child: Text(
                l?.autoRecordBackgroundLocationOpenSettings ??
                    'Open settings',
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Three real prerequisites the auto-record orchestrator gates on
/// (#1310). Drives the colour, icon, copy, and presence of the
/// passive "Pair an adapter in the section below" link on
/// [_AutoRecordStatusBanner] (#1400 — replaces the pre-#1400
/// orange-tinted "Pair an adapter" CTA that duplicated the canonical
/// pair button on the OBD2 card directly below).
enum _AutoRecordStatus {
  /// Adapter paired and background-location consent granted —
  /// orchestrator will arm next time the user enters the car.
  active,

  /// `pairedAdapterMac` is null/empty. The orchestrator silently
  /// drops this vehicle until an adapter is paired.
  needsPairing,

  /// Adapter paired but `backgroundLocationConsent` is false. The
  /// foreground service can connect, but trips lose their GPS path
  /// once the screen locks.
  needsBackgroundLocation,
}

class _AutoRecordStatusBanner extends StatelessWidget {
  final _AutoRecordStatus state;
  final ThemeData theme;
  final AppLocalizations? l;
  final VoidCallback? onScrollToObd2Card;

  const _AutoRecordStatusBanner({
    required this.state,
    required this.theme,
    required this.l,
    required this.onScrollToObd2Card,
  });

  @override
  Widget build(BuildContext context) {
    // #1400 — needsPairing renders a passive informational link
    // pointing the user at the canonical OBD2 adapter card below
    // instead of duplicating the pair CTA inline. Other states keep
    // the pre-#1400 banner shape.
    if (state == _AutoRecordStatus.needsPairing) {
      return _PairAdapterLink(
        key: const Key('autoRecordStatusBannerNeedsPairing'),
        theme: theme,
        l: l,
        onTap: onScrollToObd2Card,
      );
    }

    final isActive = state == _AutoRecordStatus.active;
    final container = isActive
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.tertiaryContainer;
    final onContainer = isActive
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onTertiaryContainer;
    final icon = isActive ? Icons.check_circle : Icons.warning_amber_rounded;

    return Container(
      key: Key(_keyFor(state)),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _labelFor(state, l),
              style: theme.textTheme.bodySmall?.copyWith(
                color: onContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelFor(_AutoRecordStatus s, AppLocalizations? l) {
    switch (s) {
      case _AutoRecordStatus.active:
        return l?.autoRecordStatusActiveLabel ??
            'Auto-record will activate the next time you enter the car.';
      case _AutoRecordStatus.needsPairing:
        // Unused for needsPairing — the passive link in
        // [_PairAdapterLink] supplies its own copy. Kept as a fallback
        // for completeness so a future refactor that re-routes this
        // helper for needsPairing still gets a sensible string.
        return l?.autoRecordStatusNeedsPairingLabel ??
            'Pair an OBD2 adapter to enable auto-record.';
      case _AutoRecordStatus.needsBackgroundLocation:
        return l?.autoRecordStatusNeedsBackgroundLocationLabel ??
            'Allow background location so auto-record keeps running '
                'with the screen off.';
    }
  }

  static String _keyFor(_AutoRecordStatus s) {
    switch (s) {
      case _AutoRecordStatus.active:
        return 'autoRecordStatusBannerActive';
      case _AutoRecordStatus.needsPairing:
        return 'autoRecordStatusBannerNeedsPairing';
      case _AutoRecordStatus.needsBackgroundLocation:
        return 'autoRecordStatusBannerNeedsBackgroundLocation';
    }
  }
}

/// Passive informational link rendered in the [_AutoRecordStatus.needsPairing]
/// state (#1400). Replaces the pre-#1400 orange-tinted "Pair an
/// adapter" button + warning box that duplicated the canonical pair
/// CTA on the OBD2 adapter card directly below this section. Tapping
/// the link calls [onTap] (wired by [EditVehicleScreen] to scroll to
/// and pulse the OBD2 card); a null callback is a safe no-op so
/// isolated widget tests don't need to wire scroll plumbing.
class _PairAdapterLink extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations? l;
  final VoidCallback? onTap;

  const _PairAdapterLink({
    super.key,
    required this.theme,
    required this.l,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        key: const Key('autoRecordPairAdapterLink'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l?.autoRecordPairAdapterLinkText ??
                      'Pair an adapter in the section below to enable '
                          'auto-recording',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Icon(Icons.arrow_downward, size: 16, color: color),
            ],
          ),
        ),
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
