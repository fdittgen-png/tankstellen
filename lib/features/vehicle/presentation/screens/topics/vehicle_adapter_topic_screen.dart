// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/vehicle_profile.dart';
import '../../../../../core/error/guarded.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../trips/api.dart';
import '../../../providers/vehicle_providers.dart';
import '../../widgets/obd2_capability_section.dart';
import 'vehicle_topic_scaffold.dart';

/// Edit vehicle → "OBD2 adapter" topic (#3900): the adapter pairing
/// card (#779) and the adapter capability tier (#1401).
///
/// Pair / forget persist IN PLACE through the editor's existing
/// `_onAdapterChanged` path (#2960), so this screen reads the live
/// adapter state straight off the persisted profile — the tile on the
/// editor's top level and this screen can never disagree.
class VehicleAdapterTopicScreen extends ConsumerWidget {
  final String vehicleId;
  final void Function(String name, String mac) onPaired;
  final VoidCallback onForget;

  const VehicleAdapterTopicScreen({
    super.key,
    required this.vehicleId,
    required this.onPaired,
    required this.onForget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = guard(
      () => ref
          .watch(vehicleProfileListProvider)
          .where((v) => v.id == vehicleId)
          .firstOrNull,
      where: 'VehicleAdapterTopicScreen: profile lookup failed',
      fallback: null as VehicleProfile?,
    );
    return VehicleTopicScaffold(
      title: l.vehicleAdapterSectionTitle,
      children: [
        VehicleAdapterSection(
          adapterMac: profile?.obd2AdapterMac,
          adapterName: profile?.obd2AdapterName,
          onPaired: onPaired,
          onForget: onForget,
        ),
        // #1401 phase 6 — adapter capability tier card (collapses to
        // SizedBox.shrink when no adapter is connected).
        const SizedBox(height: 16),
        const Obd2CapabilitySection(),
      ],
    );
  }
}
