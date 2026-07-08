// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_link_supervisor.dart';
import '../../providers/obd2_connection_state_provider.dart';
import '../../providers/obd2_reconnect_provider.dart';

/// Tiny always-visible OBD2 connection indicator (#784).
///
/// Sits in the shell's app-bar area alongside the trip-recording
/// banner. Renders as zero-size when no adapter has ever been paired
/// — zero UX weight for unconfigured users, only appearing once the
/// adapter is remembered.
///
/// Colours:
/// - green  = connected
/// - amber (pulsing) = idle auto-reconnect in flight (#3505 — the AMBIENT
///   replacement for the app-wide "Reconnecting…" strip)
/// - red    = permission denied
/// - hidden = idle (no saved adapter)
class Obd2StatusDot extends ConsumerWidget {
  const Obd2StatusDot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(obd2ConnectionStatusProvider);
    // #3505 — the idle reconnect loop surfaces HERE (pulsing amber +
    // the spoken/semantics label), not as an app-wide strip.
    final reconnecting =
        ref.watch(obd2ReconnectProvider) == Obd2LinkState.reconnecting;
    if (!snapshot.hasVisibleIndicator && !reconnecting) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    var (color, semanticsLabel) = _styleFor(context, snapshot, l);
    if (reconnecting) {
      color = Colors.amber;
      semanticsLabel = l.obd2ReconnectInProgress;
    }
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        key: const Key('obd2StatusDot'),
        customBorder: const CircleBorder(),
        onTap: () => _openSheet(context, ref, snapshot, l),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: reconnecting ? _PulsingDot(child: dot) : dot,
        ),
      ),
    );
  }

  (Color, String) _styleFor(
    BuildContext context,
    Obd2ConnectionSnapshot s,
    AppLocalizations l,
  ) {
    switch (s.state) {
      case Obd2ConnectionState.connected:
        return (DarkModeColors.success(context), l.obd2StatusConnected);
      case Obd2ConnectionState.permissionDenied:
        return (DarkModeColors.error(context), l.obd2StatusPermissionDenied);
      case Obd2ConnectionState.idle:
        // Never reached — guarded by hasVisibleIndicator above.
        return (Colors.grey, '');
    }
  }

  void _openSheet(
    BuildContext context,
    WidgetRef ref,
    Obd2ConnectionSnapshot snapshot,
    AppLocalizations l,
  ) {
    final name = snapshot.adapterName ?? (l.obd2StatusNoAdapter);
    final mac = snapshot.adapterMac;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(ctx).textTheme.titleMedium),
                  if (mac != null) ...[
                    const SizedBox(height: 4),
                    Text(mac, style: Theme.of(ctx).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _description(snapshot.state, l),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: const Key('obd2StatusDotForget'),
                        onPressed: () {
                          ref
                              .read(obd2ConnectionStatusProvider.notifier)
                              .markIdle();
                          Navigator.of(ctx).pop();
                        },
                        child: Text(l.obd2StatusForget),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _description(Obd2ConnectionState s, AppLocalizations l) {
    switch (s) {
      case Obd2ConnectionState.connected:
        return l.obd2StatusConnectedBody;
      case Obd2ConnectionState.permissionDenied:
        return l.obd2StatusPermissionDeniedBody;
      case Obd2ConnectionState.idle:
        return '';
    }
  }
}

/// #3505 — gentle opacity pulse for the reconnecting dot: ambient enough
/// to ignore, alive enough to say "the app is on it". Pure animation
/// wrapper so the dot widget itself stays a ConsumerWidget.
class _PulsingDot extends StatefulWidget {
  final Widget child;

  const _PulsingDot({required this.child});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: widget.child,
      );
}
