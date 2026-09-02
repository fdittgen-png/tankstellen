// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/auto_record_section.dart';
import 'vehicle_topic_scaffold.dart';

/// Edit vehicle → "Auto-record" topic (#3900): the hands-free auto-record
/// settings card (#1004 phase 6 / #1400). Its "pair an adapter" link now
/// opens the OBD2 adapter topic instead of scrolling a shared page.
class VehicleAutoRecordTopicScreen extends StatelessWidget {
  final String vehicleId;

  /// Opens the OBD2 adapter topic — the ONE place an adapter is paired.
  final VoidCallback onOpenAdapterTopic;

  const VehicleAutoRecordTopicScreen({
    super.key,
    required this.vehicleId,
    required this.onOpenAdapterTopic,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VehicleTopicScaffold(
      title: l.autoRecordSectionTitle,
      children: [
        AutoRecordSection(
          vehicleId: vehicleId,
          onScrollToObd2Card: onOpenAdapterTopic,
        ),
      ],
    );
  }
}
