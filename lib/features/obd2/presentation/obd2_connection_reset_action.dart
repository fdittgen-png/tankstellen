// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/guarded.dart';
import '../../../core/widgets/snackbar_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/obd2_reconnect_provider.dart';

/// #3676/#3678 — the ONE user-facing "reset the OBD2 connection" run,
/// shared by the vehicle screen's adapter card and the recording
/// screen's overflow kebab: ATZ chip reset on the dongle (best effort),
/// full link recycle, fresh dial — then an honest outcome snackbar
/// ("re-established" vs "reconnecting in the background").
///
/// Shell-safe (#2163): an unwired provider graph (isolated widget
/// tests) degrades to "no link", never a crash. The messenger and the
/// localized strings are captured BEFORE the await (SnackBarHelper
/// contract) so the feedback survives the caller's context dying
/// mid-reset (e.g. the user navigates off the recording screen while
/// the redial runs).
Future<void> runObd2ConnectionReset(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final linked = await guardAsync(
    () => ref.read(obd2ReconnectProvider.notifier).resetConnection(),
    where: 'runObd2ConnectionReset failed',
    fallback: false,
  );
  messenger?.showSnackBar(SnackBarHelper.infoSnackBar(
    linked ? l.obd2ResetConnectionDone : l.obd2ResetConnectionNoLink,
  ));
}
