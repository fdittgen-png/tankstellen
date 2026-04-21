import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/obd2_connection_state_provider.dart';

/// Tiny always-visible OBD2 connection indicator (#784).
///
/// Sits in the shell's app-bar area alongside the trip-recording
/// banner. Renders as zero-size when no adapter has ever been paired
/// — zero UX weight for unconfigured users, only appearing once the
/// adapter is remembered.
///
/// Colours:
/// - green  = connected
/// - amber  = attempting / retrying
/// - red    = unreachable / permission denied
/// - hidden = idle (no saved adapter)
class Obd2StatusDot extends ConsumerWidget {
  const Obd2StatusDot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(obd2ConnectionStatusProvider);
    if (!snapshot.hasVisibleIndicator) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final (color, semanticsLabel) = _styleFor(snapshot, l);
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        key: const Key('obd2StatusDot'),
        customBorder: const CircleBorder(),
        onTap: () => _openSheet(context, ref, snapshot, l),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  (Color, String) _styleFor(
    Obd2ConnectionSnapshot s,
    AppLocalizations? l,
  ) {
    switch (s.state) {
      case Obd2ConnectionState.connected:
        return (
          Colors.green.shade600,
          l?.obd2StatusConnected ?? 'OBD2 adapter: connected',
        );
      case Obd2ConnectionState.attempting:
        return (
          Colors.amber.shade700,
          l?.obd2StatusAttempting ?? 'OBD2 adapter: connecting',
        );
      case Obd2ConnectionState.unreachable:
        return (
          Colors.red.shade700,
          l?.obd2StatusUnreachable ?? 'OBD2 adapter: unreachable',
        );
      case Obd2ConnectionState.permissionDenied:
        return (
          Colors.red.shade700,
          l?.obd2StatusPermissionDenied ??
              'OBD2 adapter: Bluetooth permission needed',
        );
      case Obd2ConnectionState.idle:
        // Never reached — guarded by hasVisibleIndicator above.
        return (Colors.grey, '');
    }
  }

  void _openSheet(
    BuildContext context,
    WidgetRef ref,
    Obd2ConnectionSnapshot snapshot,
    AppLocalizations? l,
  ) {
    final name = snapshot.adapterName ??
        (l?.obd2StatusNoAdapter ?? 'No adapter paired');
    final mac = snapshot.adapterMac;
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
                Text(
                  name,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
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
                      child: Text(
                        l?.obd2StatusForget ?? 'Forget adapter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _description(Obd2ConnectionState s, AppLocalizations? l) {
    switch (s) {
      case Obd2ConnectionState.connected:
        return l?.obd2StatusConnectedBody ??
            'Ready to record a trip.';
      case Obd2ConnectionState.attempting:
        return l?.obd2StatusAttemptingBody ??
            'Connecting in the background…';
      case Obd2ConnectionState.unreachable:
        return l?.obd2StatusUnreachableBody ??
            'Adapter out of range or already in use by another app.';
      case Obd2ConnectionState.permissionDenied:
        return l?.obd2StatusPermissionDeniedBody ??
            'Grant Bluetooth permission in system settings to reconnect automatically.';
      case Obd2ConnectionState.idle:
        return '';
    }
  }
}
