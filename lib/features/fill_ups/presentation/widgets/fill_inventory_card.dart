// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/vehicle_profile.dart';
import '../../../../core/error/guarded.dart';
import '../../../vehicle/api.dart';
import '../../domain/entities/fill_inventory.dart';
import '../../providers/fill_inventory_provider.dart';
import 'fill_inventory_sheet.dart';

/// The last "Bilan du plein" (#3917) pinned at the top of the Carburant
/// tab until the next fill replaces it. Same lines as the post-save
/// sheet ([FillInventoryContent]); hidden when no inventory exists or
/// the stored one belongs to another vehicle.
class FillInventoryCard extends ConsumerWidget {
  const FillInventoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shell-safety (#2163 idiom): an unwired settings / vehicle graph
    // reads as "no inventory", never a crash on the tab.
    final inventory = guard(
      () => ref.watch(lastFillInventoryProvider),
      where: 'FillInventoryCard: inventory watch failed',
      fallback: null as FillInventory?,
    );
    if (inventory == null) return const SizedBox.shrink();
    final active = guard(
      () => ref.watch(activeVehicleProfileProvider),
      where: 'FillInventoryCard: active vehicle watch failed',
      fallback: null as VehicleProfile?,
    );
    if (active != null && active.id != inventory.vehicleId) {
      return const SizedBox.shrink();
    }
    return Card(
      key: const Key('fillInventoryCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FillInventoryContent(inventory: inventory),
      ),
    );
  }
}
