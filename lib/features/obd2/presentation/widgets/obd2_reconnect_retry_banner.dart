// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_reconnect_controller.dart';
import '../../providers/obd2_reconnect_provider.dart';

/// Terminal auto-reconnect "tap to retry" surface (Epic #3013 phase 3,
/// #3019 — reworked by #3505).
///
/// The trip-INDEPENDENT [Obd2ReconnectController] drives a bounded
/// backoff reconnect loop on any link drop (decoupled from a live trip).
/// #3505 demoted the idle-loop states that used to paint an app-wide
/// strip over EVERY screen (the field screenshot showed the spinner
/// colonising the trip-history screen for minutes — background
/// housekeeping presented as urgent):
///
///   * [Obd2ReconnectState.reconnecting] — AMBIENT now: no strip; the
///     [Obd2StatusDot] pulses amber with the reconnect semantics label.
///   * [Obd2ReconnectState.terminalEngineOff] (#3035) — a parked car with
///     the ignition off is the EXPECTED idle state, not an app-wide
///     banner; the dot carries it, the retry affordance lives on the
///     OBD2 surfaces (picker / trip start re-checks on its own).
///   * [Obd2ReconnectState.terminalFailed] — STAYS user-actionable (the
///     bounded attempts were exhausted): the strip offers "tap to retry",
///     and #3505 adds a dismiss (X) that silences it for THIS episode —
///     a fresh drop re-arms it.
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
class Obd2ReconnectRetryBanner extends ConsumerStatefulWidget {
  const Obd2ReconnectRetryBanner({super.key});

  @override
  ConsumerState<Obd2ReconnectRetryBanner> createState() =>
      _Obd2ReconnectRetryBannerState();
}

class _Obd2ReconnectRetryBannerState
    extends ConsumerState<Obd2ReconnectRetryBanner> {
  /// #3505 — the user closed the terminal-failed strip for this episode.
  /// Any state change away from terminalFailed re-arms it (a fresh drop
  /// starts a fresh episode).
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<Obd2ReconnectState>(obd2ReconnectProvider, (prev, next) {
      if (next != Obd2ReconnectState.terminalFailed && _dismissed) {
        setState(() => _dismissed = false);
      }
    });
    final state = ref.watch(obd2ReconnectProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    switch (state) {
      case Obd2ReconnectState.terminalFailed:
        return _dismissed
            ? const SizedBox.shrink()
            : _failedBanner(context, ref, theme, l);
      // #3505 — ambient states: the status dot carries them (see class doc).
      case Obd2ReconnectState.reconnecting:
      case Obd2ReconnectState.terminalEngineOff:
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
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            key: const Key('obd2ReconnectRetryButton'),
            style: TextButton.styleFrom(foregroundColor: fg),
            onPressed: () => ref.read(obd2ReconnectProvider.notifier).retry(),
            child: Text(l.obd2ReconnectRetry),
          ),
          // #3505 — dismiss for THIS episode; a fresh drop re-arms.
          IconButton(
            key: const Key('obd2ReconnectDismissButton'),
            tooltip: l.obd2ReconnectDismiss,
            icon: Icon(Icons.close, size: 18, color: fg),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}
