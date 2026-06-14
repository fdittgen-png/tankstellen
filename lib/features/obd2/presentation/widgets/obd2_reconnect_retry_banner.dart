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
///
/// #3306 — restyled to the app's compact status-strip convention
/// ([ServiceStatusBanner]): a full-width [Container] strip carrying the
/// container colour + a leading icon/spinner + the message + an inline action,
/// instead of a bulky [MaterialBanner] (which read as a detached system
/// surface, unlike the rest of the app). The host wraps it in an `AnimatedSize`
/// so the strip slides in/out smoothly instead of jumping the screen below it.
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

  /// The shared app-consistent status strip (mirrors [ServiceStatusBanner]'s
  /// full-width container convention): a [SafeArea]-topped strip with the
  /// container colour, a leading glyph, the message, and an optional inline
  /// action.
  Widget _strip({
    required Key key,
    required Color background,
    required Color foreground,
    required Widget leading,
    required String message,
    required ThemeData theme,
    Widget? action,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 20, height: 20, child: Center(child: leading)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ),
              if (action != null) ...[const SizedBox(width: 8), action],
            ],
          ),
        ),
      ),
    );
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
    final fg = theme.colorScheme.onSecondaryContainer;
    return _strip(
      key: const Key('obd2ReconnectingBanner'),
      theme: theme,
      background: theme.colorScheme.secondaryContainer,
      foreground: fg,
      leading: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
      ),
      message: text,
      // No action: the loop is in flight; the user just waits.
    );
  }

  Widget _failedBanner(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l,
  ) {
    final fg = theme.colorScheme.onErrorContainer;
    return _strip(
      key: const Key('obd2ReconnectFailedBanner'),
      theme: theme,
      background: theme.colorScheme.errorContainer,
      foreground: fg,
      leading: Icon(Icons.bluetooth_disabled, size: 20, color: fg),
      message: l.obd2ReconnectFailedBody,
      action: TextButton(
        key: const Key('obd2ReconnectRetryButton'),
        style: TextButton.styleFrom(foregroundColor: fg),
        onPressed: () => ref.read(obd2ReconnectProvider.notifier).retry(),
        child: Text(l.obd2ReconnectRetry),
      ),
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
    final fg = theme.colorScheme.onTertiaryContainer;
    return _strip(
      key: const Key('obd2ReconnectEngineOffBanner'),
      theme: theme,
      background: theme.colorScheme.tertiaryContainer,
      foreground: fg,
      leading: Icon(Icons.power_settings_new, size: 20, color: fg),
      message: l.obdAdapterUnresponsive,
      action: TextButton(
        key: const Key('obd2ReconnectEngineOffRetryButton'),
        style: TextButton.styleFrom(foregroundColor: fg),
        onPressed: () => ref.read(obd2ReconnectProvider.notifier).retry(),
        child: Text(l.obd2ReconnectRetry),
      ),
    );
  }
}
