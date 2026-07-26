// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'animated_splash.dart';

/// Minimum time the splash overlay stays up after the real tree's first
/// frame (#3607). The initial pop-in cascade — boxes opening, providers
/// resolving, tiles appearing — happens in the first few hundred ms; a
/// floor guarantees none of it is ever visible, even on fast devices.
const Duration kStartupRevealMinHold = Duration(milliseconds: 350);

/// Hard cap on the overlay after the first frame. A screen with a
/// permanently-animating widget (an indeterminate spinner) never goes
/// frame-quiescent, and a wedged provider must not trap the user on the
/// splash — past this point the app is revealed regardless.
const Duration kStartupRevealCap = Duration(milliseconds: 2500);

/// Fade-out duration of the reveal itself.
const Duration kStartupRevealFade = Duration(milliseconds: 250);

/// One reveal per process: the app tree is keyed on the language code and
/// fully rebuilds on a locale change — the splash must not re-play then.
bool _revealDoneThisProcess = false;

/// Test seam — widget tests re-run the reveal in one process.
@visibleForTesting
void resetStartupRevealForTests() => _revealDoneThisProcess = false;

/// Holds the branded splash as an overlay ON TOP of the real app until
/// the first screen has actually settled (#3607), so the user never
/// watches the form being constructed.
///
/// The #795 splash covers `AppInitializer.run`; this widget covers the
/// gap AFTER it — the real tree's own async composition. Reveal fires
/// when ALL of:
///   1. [kStartupRevealMinHold] elapsed since the first frame under the
///      overlay, AND
///   2. the tree went frame-quiescent (a frame completed with no next
///      frame scheduled — nothing is still rebuilding or animating),
/// OR the [kStartupRevealCap] elapsed (the escape hatch for screens that
/// animate forever). The overlay then fades out over
/// [kStartupRevealFade] and unmounts.
class StartupReveal extends StatefulWidget {
  const StartupReveal({super.key, required this.child});

  final Widget child;

  @override
  State<StartupReveal> createState() => _StartupRevealState();
}

class _StartupRevealState extends State<StartupReveal> {
  bool _minHoldElapsed = false;
  bool _quiescent = false;
  bool _fading = false;
  bool _gone = false;
  Timer? _minHoldTimer;
  Timer? _capTimer;

  @override
  void initState() {
    super.initState();
    if (_revealDoneThisProcess) {
      _gone = true;
      return;
    }
    _minHoldTimer = Timer(kStartupRevealMinHold, () {
      _minHoldElapsed = true;
      _maybeReveal();
    });
    _capTimer = Timer(kStartupRevealCap, _reveal);
    // Quiescence watch: after each frame, another frame being scheduled
    // means the tree is still mutating — re-arm and keep waiting. A frame
    // that ends with nothing scheduled is the settled first screen.
    // Re-arming only when a frame IS coming makes this self-terminating.
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _onFrame(Duration _) {
    if (!mounted || _fading || _gone) return;
    if (SchedulerBinding.instance.hasScheduledFrame) {
      SchedulerBinding.instance.addPostFrameCallback(_onFrame);
      return;
    }
    _quiescent = true;
    _maybeReveal();
  }

  void _maybeReveal() {
    if (_minHoldElapsed && _quiescent) _reveal();
  }

  void _reveal() {
    if (!mounted || _fading || _gone) return;
    _minHoldTimer?.cancel();
    _capTimer?.cancel();
    _revealDoneThisProcess = true;
    setState(() => _fading = true);
    Timer(kStartupRevealFade, () {
      if (mounted) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _minHoldTimer?.cancel();
    _capTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // The overlay swallows taps while up — the screen underneath is
        // deliberately not interactive until it is fully presented.
        IgnorePointer(
          ignoring: _fading,
          child: AnimatedOpacity(
            opacity: _fading ? 0.0 : 1.0,
            duration: kStartupRevealFade,
            curve: Curves.easeOut,
            // The splash resumes at its settled end state — the intro
            // scale/fade already played under the #795 pre-init host,
            // and replaying it here would read as a restart.
            child: const AnimatedSplash(animateIn: false),
          ),
        ),
      ],
    );
  }
}
