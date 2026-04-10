import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.vehiclesTitle ?? 'My vehicles'),
      ),
      body: vehicles.isEmpty
          ? _EmptyState(
              message: l?.vehiclesEmptyMessage ??
                  'Add your car to filter by connector and estimate charging costs.',
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewPadding.bottom + 96,
              ),
              itemCount: vehicles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return VehicleCard(
                  vehicle: v,
                  isActive: v.id == active?.id,
                  onTap: () => context.push('/vehicles/edit', extra: v.id),
                  onEdit: () => context.push('/vehicles/edit', extra: v.id),
                  onSetActive: () => ref
                      .read(activeVehicleProfileProvider.notifier)
                      .setActive(v.id),
                  onDelete: () => _confirmDelete(context, ref, v.id, v.name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/edit'),
        icon: const Icon(Icons.add),
        label: Text(l?.vehicleAdd ?? 'Add vehicle'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l?.vehicleDeleteTitle ?? 'Delete vehicle?'),
        content: Text(l?.vehicleDeleteMessage(name) ??
            'Remove "$name" from your profiles?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(vehicleProfileListProvider.notifier).remove(id);
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
