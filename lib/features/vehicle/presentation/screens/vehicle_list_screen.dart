// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/vehicle_providers.dart';
import '../widgets/vehicle_card.dart';

/// Screen listing all of the user's vehicle profiles with CRUD actions.
class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final vehicles = ref.watch(vehicleProfileListProvider);
    final active = ref.watch(activeVehicleProfileProvider);

    return PageScaffold(
      title: l.vehiclesTitle,
      bodyPadding: EdgeInsets.zero,
      body: vehicles.isEmpty
          ? Column(
              children: [
                HelpBanner(
                  storageKey: StorageKeys.helpBannerVehicles,
                  icon: Icons.tips_and_updates_outlined,
                  message: l.helpBannerVehicles,
                ),
                Expanded(child: _EmptyState(message: l.vehiclesEmptyMessage)),
              ],
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewPadding.bottom + 96,
              ),
              itemCount: vehicles.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return HelpBanner(
                    storageKey: StorageKeys.helpBannerVehicles,
                    icon: Icons.tips_and_updates_outlined,
                    message: l.helpBannerVehicles,
                  );
                }
                final v = vehicles[index - 1];
                return VehicleCard(
                  vehicle: v,
                  isActive: v.id == active?.id,
                  onTap: () => EditVehicleRoute(vehicleId: v.id).push<void>(context),
                  onEdit: () => EditVehicleRoute(vehicleId: v.id).push<void>(context),
                  onSetActive: () => ref
                      .read(activeVehicleProfileProvider.notifier)
                      .setActive(v.id),
                  onDelete: () => _confirmDelete(context, ref, v.id, v.name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => const EditVehicleRoute().push<void>(context),
        icon: const Icon(Icons.add),
        label: Text(l.vehicleAdd),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final l = AppLocalizations.of(context);
    // #3159 — capture before the dialog await: ref.read on an unmounted
    // element throws a StateError under Riverpod 3, and the screen can be
    // popped out from underneath the open dialog.
    final vehicles = ref.read(vehicleProfileListProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.vehicleDeleteTitle),
        content: Text(l.vehicleDeleteMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vehicles.remove(id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
