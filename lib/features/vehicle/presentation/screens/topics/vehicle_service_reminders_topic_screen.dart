// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/service_reminder_section.dart';
import '../../widgets/vehicle_save_actions.dart';
import 'vehicle_topic_scaffold.dart';

/// Edit vehicle → "Service reminders" topic (#3900): the reminder list
/// (#584), keyed by vehicle id. Reminders persist through their own
/// provider the moment they are added / acknowledged.
class VehicleServiceRemindersTopicScreen extends ConsumerWidget {
  final String vehicleId;

  const VehicleServiceRemindersTopicScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return VehicleTopicScaffold(
      title: l.serviceRemindersSection,
      children: [
        ServiceReminderSection(
          vehicleId: vehicleId,
          currentOdometerKm: ref.latestOdometerKm(vehicleId),
        ),
      ],
    );
  }
}
