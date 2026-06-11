// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_reconnect_controller.dart';
import '../../providers/obd2_connection_state_provider.dart';
import '../../providers/obd2_reconnect_provider.dart';

/// Terminal auto-reconnect "tap to retry" surface (Epic #3013 phase 3,
/// #3019).
///
/// The trip-INDEPENDENT [Obd2ReconnectController] drives a bounded
/// backoff reconnect loop on any link drop (decoupled from a live trip).
/// Two of its states reach the user here:
///
///   * [Obd2ReconnectState.reconnecting] — a calm "reconnecting…" banner
///     so the user knows the app is already trying (no action needed).
///   * [Obd2ReconnectState.terminalFailed] — after the bounded attempts
///     were exhausted the auto-loop STOPS, and this banner offers the
///     user-actionable "tap to retry" button the Epic requires, instead
///     of spinning forever or silently giving up. Tapping restarts the
///     loop via [Obd2Reconnect.retry].
///   * [Obd2ReconnectState.terminalEngineOff] (#3035) — the adapter
///     re-connected fine but the `0100` probe confirmed the ECU is silent
///     (a parked car / ignition off). The loop STOPS (no backoff burst) and
///     this banner shows the accurate "turn the ignition on and retry"
///     prompt, again wired to [Obd2Reconnect.retry].
///
/// Renders zero-height in every other state (idle / connected), so it is
/// safe to drop into any always-on chrome.
class Obd2ReconnectRetryBanner extends ConsumerWidget {
  const Obd2ReconnectRetryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(obd2ReconnectProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final adapterName = ref.watch(
      obd2ConnectionStatusProvider.select((s) => s.adapterName),
    );
    switch (state) {
      case Obd2ReconnectState.reconnecting:
        return _reconnectingBanner(theme, l, adapterName);
      case Obd2ReconnectState.terminalFailed:
        return _failedBanner(context, ref, theme, l);
      case Obd2ReconnectState.terminalEngineOff:
        return _engineOffBanner(context, ref, theme, l);
      case Obd2ReconnectState.idle:
      case Obd2ReconnectState.connected:
        return const SizedBox.shrink();
    }
  }

  Widget _reconnectingBanner(
    ThemeData theme,
    AppLocalizations l,
    String? adapterName,
  ) {
    final hasName = adapterName != null && adapterName.isNotEmpty;
    final text = hasName
        ? (l.obd2ReconnectInProgressNamed(adapterName))
        : (l.obd2ReconnectInProgress);
    return MaterialBanner(
      key: const Key('obd2ReconnectingBanner'),
      backgroundColor: theme.colorScheme.secondaryContainer,
      contentTextStyle: TextStyle(
        color: theme.colorScheme.onSecondaryContainer,
      ),
      leading: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
      content: Text(text),
      // No action: the loop is in flight; the user just waits.
      actions: const [SizedBox.shrink()],
    );
  }

  Widget _failedBanner(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return MaterialBanner(
      key: const Key('obd2ReconnectFailedBanner'),
      backgroundColor: theme.colorScheme.errorContainer,
      contentTextStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
      leading: Icon(
        Icons.bluetooth_disabled,
        color: theme.colorScheme.onErrorContainer,
      ),
      content: Text(l.obd2ReconnectFailedBody),
      actions: [
        TextButton(
          key: const Key('obd2ReconnectRetryButton'),
          onPressed: () => ref.read(obd2ReconnectProvider.notifier).retry(),
          child: Text(l.obd2ReconnectRetry),
        ),
      ],
    );
  }

  /// #3035 — terminal "the adapter re-connected but the engine is off"
  /// surface. The auto-loop STOPPED on a confirmed engine-off (the `0100`
  /// probe stayed silent through every retry), so re-trying on a backoff
  /// would just spin. We reuse the existing localized engine-off string
  /// (`obdAdapterUnresponsive` — "turn the ignition on and retry") and the
  /// same manual [Obd2Reconnect.retry] action so the user re-checks once the
  /// ignition is on, instead of being told "adapter not found".
  Widget _engineOffBanner(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l,
  ) {
    return MaterialBanner(
      key: const Key('obd2ReconnectEngineOffBanner'),
      backgroundColor: theme.colorScheme.tertiaryContainer,
      contentTextStyle: TextStyle(color: theme.colorScheme.onTertiaryContainer),
      leading: Icon(
        Icons.power_settings_new,
        color: theme.colorScheme.onTertiaryContainer,
      ),
      content: Text(l.obdAdapterUnresponsive),
      actions: [
        TextButton(
          key: const Key('obd2ReconnectEngineOffRetryButton'),
          onPressed: () => ref.read(obd2ReconnectProvider.notifier).retry(),
          child: Text(l.obd2ReconnectRetry),
        ),
      ],
    );
  }
}
