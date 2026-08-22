// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// A non-dismissible modal shown while a full backup is exporting or
/// restoring (#2815). Mirrors the visual grammar of [TripSaveProgress] — a
/// slowly-rotating icon + an indeterminate [LinearProgressIndicator] + a
/// `liveRegion` status label — so the user sees the work happening instead of
/// a frozen screen. Indeterminate by design: the zip/parse/write sequence has
/// no per-item counter.
class BackupProgressDialog extends StatefulWidget {
  /// Localized one-line status (e.g. "Exporting your backup…").
  final String label;

  /// The spinning glyph — backup vs restore is conveyed by the icon + label.
  final IconData icon;

  const BackupProgressDialog({
    super.key,
    required this.label,
    this.icon = Icons.cached,
  });

  @override
  State<BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<BackupProgressDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Back-button / barrier dismissal is blocked: the operation is a short
    // fixed await and must not be left half-run.
    return PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RotationTransition(
                    turns: _spin,
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.label,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: AppRadius.md,
                child: const LinearProgressIndicator(minHeight: 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a [BackupProgressDialog] over [context], runs [work], and guarantees
/// the dialog is dismissed afterwards — on success, error, or an empty result
/// (#2815). Rethrows so the caller's existing try/catch still handles failures.
Future<T> runWithBackupProgress<T>(
  BuildContext context, {
  required String label,
  required IconData icon,
  required Future<T> Function() work,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var dialogUp = true;
  // Not awaited — the dialog stays up until we pop it in the finally.
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => BackupProgressDialog(label: label, icon: icon),
    ).whenComplete(() => dialogUp = false),
  );
  try {
    return await work();
  } finally {
    if (dialogUp) {
      try {
        navigator.pop();
      } on Object {
        // Navigator already torn down (e.g. screen disposed mid-op) — no-op.
      }
    }
  }
}
