// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:ui' as ui;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/language/language_provider.dart';
import '../../../core/logging/error_logger.dart';
import '../../../l10n/app_localizations.dart';

/// #3756 — mirror the armed adapter MAC + LOCALIZED wake-notification
/// copy into SharedPreferences for the native `AdapterWakeReceiver`.
///
/// After a background low-memory kill the Dart side is gone; the
/// manifest ACL receiver reads these keys (no Flutter engine spin-up,
/// honoring the #3688 engine-churn lesson) and posts a tap-to-open
/// notification the moment the pinned adapter connects. Best-effort:
/// a prefs failure must never block arming (never-throws by catch-all;
/// the locale fallback chain mirrors `recordingLocationSettingsForRef`,
/// #2766).
Future<void> mirrorAclWakeConfig(Ref ref, String? mac) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (mac == null || mac.isEmpty) {
      await prefs.remove('acl_wake_mac');
      return;
    }
    String code;
    try {
      code = ref.read(activeLanguageProvider).code;
    } catch (_) {
      code = 'en';
    }
    AppLocalizations l10n;
    try {
      l10n = lookupAppLocalizations(ui.Locale(code));
    } catch (_) {
      l10n = lookupAppLocalizations(const ui.Locale('en'));
    }
    await prefs.setString('acl_wake_mac', mac);
    await prefs.setString('acl_wake_title', l10n.aclWakeNotificationTitle);
    await prefs.setString('acl_wake_body', l10n.aclWakeNotificationBody);
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.background, e, st,
        context: const {'where': 'aclWake prefs mirror failed'}));
  }
}

/// #3756 — clear the wake config so a disarmed adapter never posts
/// wake notifications. Same best-effort contract as the mirror.
Future<void> clearAclWakeConfig() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('acl_wake_mac');
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.background, e, st,
        context: const {'where': 'aclWake prefs clear failed'}));
  }
}
