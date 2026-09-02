// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../moderation/api.dart' show BlockedAuthorsSection;
import '../settings_topic_scaffold.dart';

/// Data on this device → Blocked users (#3910, Epic #3907): the
/// device-local block list with its Unblock action (#3871), reached from
/// the inventory row — the list itself is the moderation feature's.
class PrivacyBlockedUsersScreen extends StatelessWidget {
  const PrivacyBlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.blockedAuthorsTitle,
      children: const [BlockedAuthorsSection()],
    );
  }
}
