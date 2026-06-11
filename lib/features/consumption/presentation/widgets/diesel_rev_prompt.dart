// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// The diesel rev prompt shown during a broken-MAP probe (#1621).
///
/// Diesels run unthrottled, so the broken-MAP detector can only tell a
/// healthy MAP sensor from a stuck one by reading how MAP *changes*
/// under a brief rev. The phase-2 detector waited a blind fixed 1.5 s
/// and hoped the user happened to blip the throttle; this widget makes
/// the ask explicit — it shows the user what to do and a countdown of
/// the window they have to do it.
///
/// The widget is presentation-only and self-contained: it owns a
/// countdown [window] and reports exactly one outcome through
/// [onResult] — `true` the moment the user confirms they revved,
/// `false` if the window elapses first. The caller wires that result
/// into `BrokenMapDetector.probe`'s `awaitUserRev` callback, so the
/// rev MAP read is keyed off the confirmed rev rather than a blind
/// delay. A `false` outcome makes the probe record no observation.
class DieselRevPrompt extends StatefulWidget {
  const DieselRevPrompt({
    super.key,
    required this.window,
    required this.onResult,
  });

  /// How long the user has to blip the throttle. When it elapses with
  /// no confirmation, [onResult] fires with `false`.
  final Duration window;

  /// Fired exactly once: `true` on user confirmation, `false` on
  /// timeout.
  final void Function(bool revved) onResult;

  @override
  State<DieselRevPrompt> createState() => _DieselRevPromptState();
}

class _DieselRevPromptState extends State<DieselRevPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Guards [onResult] against a double fire — e.g. the user tapping
  /// confirm in the same frame the countdown completes.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.window)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish(revved: false);
      });
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish({required bool revved}) {
    if (_done) return;
    _done = true;
    _controller.stop();
    widget.onResult(revved);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.brokenMapRevPromptTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l.brokenMapRevPromptBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          // Counts down the rev window — full at the start, empty when
          // it elapses.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) =>
                LinearProgressIndicator(value: 1.0 - _controller.value),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('dieselRevPromptConfirm'),
              onPressed: () => _finish(revved: true),
              child: Text(l.brokenMapRevPromptConfirm),
            ),
          ),
        ],
      ),
    );
  }
}
