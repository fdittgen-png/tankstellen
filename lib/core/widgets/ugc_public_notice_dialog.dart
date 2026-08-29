// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../data/storage_repository.dart';
import '../error/guarded.dart';
import '../logging/error_logger.dart';
import '../storage/storage_keys.dart';
import '../../l10n/app_localizations.dart';

/// #3871 (Epic #3865, GDPR) — THE one-time notice before the user's
/// FIRST public contribution.
///
/// Every surface that pushes user content into the shared sync database
/// where other people can read it (community price reports, ratings
/// switched to "shared") calls this before proceeding. The first time it
/// shows an explanatory dialog — where the content goes, who can read
/// it, how to delete it — with Cancel / Continue. This is NOT an OS
/// pre-permission screen, so Cancel is allowed here (App Review 5.1.1
/// only forbids it before an OS permission prompt).
///
/// Contract:
///  * returns `true` when the notice was already accepted (persisted
///    [StorageKeys.ugcPublicNoticeShown]) — no dialog is shown;
///  * returns `true` on Continue and persists the flag so the notice
///    never shows again;
///  * returns `false` on Cancel, barrier dismiss or system back — the
///    caller must abort the contribution; the flag stays unset so the
///    notice shows again next time;
///  * never throws: an unreadable settings box (widget-test harness,
///    storage not initialised) shows the dialog; a failed persist still
///    honours the user's Continue for this session.
Future<bool> ensureUgcPublicNoticeAccepted(
  BuildContext context, {
  required SettingsStorage settings,
}) async {
  if (_alreadyAccepted(settings)) return true;
  if (!context.mounted) return false;

  final l = AppLocalizations.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('ugc_public_notice_dialog'),
      icon: const Icon(Icons.public),
      title: Text(l.ugcPublicNoticeTitle),
      content: Text(l.ugcPublicNoticeBody),
      actions: [
        TextButton(
          key: const Key('ugc_public_notice_cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('ugc_public_notice_continue'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l.continueButton),
        ),
      ],
    ),
  );
  if (accepted != true) return false;

  try {
    await settings.putSetting(StorageKeys.ugcPublicNoticeShown, true);
  } catch (e, st) {
    logFailure(
      e,
      st,
      where: 'ensureUgcPublicNoticeAccepted: cannot persist shown flag',
      layer: ErrorLayer.storage,
    );
  }
  return true;
}

bool _alreadyAccepted(SettingsStorage settings) {
  try {
    return settings.getSetting(StorageKeys.ugcPublicNoticeShown) == true;
  } catch (e, st) {
    logFailure(
      e,
      st,
      where: 'ensureUgcPublicNoticeAccepted: cannot read shown flag',
      layer: ErrorLayer.storage,
    );
    return false;
  }
}
