// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../widgets/privacy/cache_details_tile.dart';
import '../../../widgets/privacy/device_data_inventory_list.dart';
import '../settings_topic_scaffold.dart';
import 'privacy_blocked_users_screen.dart';

/// Privacy & data → Data on this device (#3910, Epic #3907): the ONE
/// inventory — storage bar on top, one row per category with count +
/// size (empty categories greyed at the end, blocked users tappable),
/// the total, then "Cache details" collapsed. Replaces the former
/// dashboard "Data on this device" card AND the storage section, which
/// showed the same figures twice.
class PrivacyDeviceDataScreen extends StatelessWidget {
  const PrivacyDeviceDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.privacyLocalData,
      children: [
        SettingsGroupHeader(icon: Icons.storage, title: l.storageUsage),
        DeviceDataInventoryList(
          onBlockedUsersTap: () => unawaited(Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PrivacyBlockedUsersScreen(),
            ),
          )),
        ),
        const SizedBox(height: 12),
        const CacheDetailsTile(),
      ],
    );
  }
}
