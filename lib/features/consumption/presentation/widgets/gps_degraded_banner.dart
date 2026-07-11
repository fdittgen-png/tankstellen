// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
// `trip_recording_provider.dart` re-exports `TripRecordingPhase`.
import '../../providers/trip_recording_provider.dart';

/// Lightweight banner shown when the OBD2 link drops mid-trip but GPS is
/// still alive (#2565 — the GPS-DEGRADE half of the connection-resilience
/// work).
///
/// Unlike [Obd2PauseBanner], recording NEVER pauses in this state: the
/// trip keeps capturing GPS-only samples (live speed from the GPS latch,
/// a physics-derived L/100 km estimate) while the reconnect scanner tries
/// to re-attach the dongle. So this banner carries NO Resume / End
/// actions — recording continues automatically and the metric cards show
/// genuinely live GPS values. It surfaces only to tell the user WHY the
/// OBD2-derived readings briefly switched to GPS, and clears itself once
/// the dongle re-attaches.
///
/// Renders zero-height unless the phase is
/// [TripRecordingPhase.degradedGpsOnly], so it is safe to drop into any
/// layout that always-on renders the trip chrome. The pause banner and
/// this banner are mutually exclusive: the pause banner renders only for
/// [TripRecordingPhase.pausedDueToDrop] (BOTH sources gone), this one
/// only for [TripRecordingPhase.degradedGpsOnly] (OBD2 gone, GPS alive).
///
/// #3010 — flicker fix. The OBD2 reconnect scanner flips the recording
/// phase `recording <-> degradedGpsOnly` on *every* transient Bluetooth
/// blip. Reflecting that raw signal directly made the banner pop in/out
/// and jump the metrics/content below on each strobe. This widget now
/// debounces + animates the DISPLAYED state purely in the view layer
/// (the underlying reconnect logic is untouched):
///
///   * **Debounce** — the banner appears only after the link has stayed
///     degraded for [_appearDelay]; a degrade that clears before then is
///     ignored, so transient drops never flash.
///   * **Grace / hysteresis** — once shown, it lingers for [_hideGrace]
///     after the phase recovers, so a quick re-drop inside the grace
///     window keeps it up rather than strobing it off-then-on.
///   * **Fade** — the in/out transition is a fade (#3545: the pill floats
///     in an overlay, so there is no content below to reflow). The hidden
///     state is a true zero-size box, so it costs no layout when idle.
class GpsDegradedBanner extends ConsumerStatefulWidget {
  const GpsDegradedBanner({super.key});

  /// How long the link must stay degraded before the banner appears.
  /// A transient drop+reconnect inside this window never surfaces it.
  static const Duration _appearDelay = Duration(milliseconds: 2500);

  /// How long the banner lingers after the phase recovers, so a quick
  /// re-drop keeps it up instead of strobing it off then back on.
  static const Duration _hideGrace = Duration(milliseconds: 1500);

  /// Ease duration of the fade in & out.
  static const Duration _animDuration = Duration(milliseconds: 220);

  @override
  ConsumerState<GpsDegradedBanner> createState() => _GpsDegradedBannerState();
}

class _GpsDegradedBannerState extends ConsumerState<GpsDegradedBanner> {
  /// Whether the banner is currently displayed (post-debounce, pre-grace).
  bool _visible = false;

  /// Pending appear (degrade still settling) / hide (grace) timer. Only
  /// one is ever live at a time — entering degraded cancels a pending
  /// hide and vice-versa, which is what gives the hysteresis.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // `ref.listen` (in build) fires only on a CHANGE, so seed the state
    // machine with the phase already present when this banner mounts —
    // e.g. the recording screen opening while the link is already
    // degraded. The same appear-debounce then applies, so even an
    // already-degraded mount eases in rather than popping.
    final degraded = ref.read(
      tripRecordingProvider.select(
        (s) => s.phase == TripRecordingPhase.degradedGpsOnly,
      ),
    );
    if (degraded) _onPhaseChanged(true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// React to a raw phase change from the provider. Runs the debounce /
  /// grace state machine; only calls [setState] when the displayed
  /// visibility actually flips.
  void _onPhaseChanged(bool degraded) {
    if (degraded) {
      // Entering / staying degraded: cancel any pending hide and, if not
      // already shown, arm the appear-debounce. A blip that clears before
      // the timer fires leaves the banner hidden (no flash).
      _timer?.cancel();
      _timer = null;
      if (_visible) return; // already up — a re-drop just keeps it up.
      _timer = Timer(GpsDegradedBanner._appearDelay, () {
        _timer = null;
        if (mounted) setState(() => _visible = true);
      });
    } else {
      // Recovered: if the appear-debounce was still pending, just drop it
      // (the degrade never lasted long enough to show). If already shown,
      // linger for the grace window before hiding so a quick re-drop keeps
      // it up rather than strobing.
      if (!_visible) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      if (_timer != null) return; // hide already scheduled.
      _timer = Timer(GpsDegradedBanner._hideGrace, () {
        _timer = null;
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Drive the debounce/grace state machine off the raw degraded signal.
    // `ref.listen` fires only on an ACTUAL change (not every rebuild), so
    // there's no post-frame churn and the timer logic runs exactly once
    // per real transition. Selecting just the boolean means unrelated
    // state changes — live readings, band transitions — don't fire it.
    ref.listen(
      tripRecordingProvider.select(
        (s) => s.phase == TripRecordingPhase.degradedGpsOnly,
      ),
      (_, degraded) => _onPhaseChanged(degraded),
    );

    // #2767 — once the reconnect scanner exhausts its active-scan attempts
    // it drops to a passive autoConnect wait (it still periodically re-arms
    // an active scan). The trip keeps recording on GPS regardless, so this
    // is a calmer "we're still waiting" state, not a failure — surface a
    // distinct, less-urgent copy so the user isn't left reading
    // "reconnecting" forever. Only meaningful while the banner is shown.
    final passiveWaiting = ref.watch(
      tripRecordingProvider.select((s) => s.reconnectPassiveWaiting),
    );

    // #3545 — the widget now floats in an overlay Stack, so there is no
    // layout below to ease: the fade alone softens the appearance. When
    // hidden the child is a true zero-size box, so the idle cost is nil
    // and taps in its corner of the overlay fall through.
    return AnimatedOpacity(
      duration: GpsDegradedBanner._animDuration,
      opacity: _visible ? 1.0 : 0.0,
      child: _visible
          ? _pill(context, passiveWaiting: passiveWaiting)
          : const SizedBox.shrink(),
    );
  }

  Widget _pill(BuildContext context, {required bool passiveWaiting}) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // A compact floating pill on a neutral/informational surface (not the
    // error surface the pause pill uses) — the trip is fine, it's just
    // running on GPS. No Resume / End: recording continues automatically.
    return Material(
      key: const Key('gpsDegradedBanner'),
      color: theme.colorScheme.secondaryContainer,
      elevation: 3,
      borderRadius: AppRadius.xl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              // A steady "fix held" glyph for the busy reconnect, a quieter
              // "still listening" glyph once we've dropped to the passive
              // wait.
              passiveWaiting ? Icons.bluetooth_searching : Icons.gps_fixed,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                passiveWaiting
                    ? (l.obd2GpsDegradedPassiveWaitingBanner)
                    : (l.obd2GpsDegradedBannerTitle),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
