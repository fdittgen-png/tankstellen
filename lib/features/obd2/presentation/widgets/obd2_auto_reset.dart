// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../obd2_connection_reset_action.dart';

/// Runs the OBD2 connection reset **by itself** shortly after a link
/// failure surfaces (#3963).
///
/// The reset was reachable only through a button on the drop banners —
/// and those banners appear while the user is DRIVING, where touching the
/// phone is exactly what must not happen. The link therefore stayed
/// degraded for the rest of the drive because nobody could tap. This
/// widget arms a [delay] timer when the failure appears and fires the
/// same guarded run the button fires.
///
/// Deliberately **once per episode**: one reset, not a loop. If it does
/// not help, the #3529 link supervisor keeps retrying reconnects on its
/// own — a self-repeating reset ladder would fight it and spam the
/// outcome snackbar. Re-arms only when [armed] goes false and true again,
/// i.e. on the NEXT drop.
///
/// Renders the pending-reset line (or nothing when idle) so the banner
/// says the link is repairing itself instead of looking like it waits
/// for a tap. The manual button stays where it is: a stopped driver who
/// wants it now should not have to wait five seconds.
class Obd2AutoReset extends ConsumerStatefulWidget {
  const Obd2AutoReset({
    super.key,
    required this.armed,
    this.delay = defaultDelay,
    this.foreground,
  });

  /// True while the failure that the reset addresses is on screen AND a
  /// reset could actually run (engine awake). False disarms and, on the
  /// next true, re-arms for the new episode.
  final bool armed;

  /// How long the failure must persist before the reset runs itself.
  final Duration delay;

  /// Colour of the pending line — the hosting banner's foreground.
  final Color? foreground;

  /// Long enough that a blip which heals itself never triggers a reset,
  /// short enough that the driver never has to reach for the phone.
  static const Duration defaultDelay = Duration(seconds: 5);

  @override
  ConsumerState<Obd2AutoReset> createState() => _Obd2AutoResetState();
}

class _Obd2AutoResetState extends ConsumerState<Obd2AutoReset> {
  Timer? _timer;

  /// Set once the reset has run for the CURRENT episode; cleared when
  /// [Obd2AutoReset.armed] drops, so the next drop gets its own attempt.
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    // A banner can mount already armed (the screen opened onto a drop).
    if (widget.armed) _arm();
  }

  @override
  void didUpdateWidget(Obd2AutoReset old) {
    super.didUpdateWidget(old);
    if (widget.armed == old.armed) return;
    if (widget.armed) {
      _arm();
    } else {
      _timer?.cancel();
      _timer = null;
      _fired = false; // the episode ended — the next one may reset again
    }
  }

  void _arm() {
    if (_fired || _timer != null) return;
    _timer = Timer(widget.delay, () {
      _timer = null;
      if (!mounted || !widget.armed || _fired) return;
      setState(() => _fired = true);
      unawaited(runObd2ConnectionReset(context, ref));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.armed || _fired) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      AppLocalizations.of(context).obd2ResetConnectionAuto,
      key: const Key('obd2AutoResetPending'),
      style: theme.textTheme.labelSmall?.copyWith(
        color: widget.foreground ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
