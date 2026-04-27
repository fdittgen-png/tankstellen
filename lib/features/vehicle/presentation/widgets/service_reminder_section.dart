import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/service_reminder.dart';
import '../../providers/service_reminder_providers.dart';

part 'service_reminder_section_parts.dart';

/// Service-reminders section of the vehicle edit screen (#584).
///
/// Renders a preset chip row ("Oil 15000 km", "Tires 20000 km",
/// "Inspection 30000 km"), the list of currently configured
/// reminders, and a free-form "Add reminder" action for custom
/// intervals. The parent screen provides [vehicleId] and the current
/// odometer (used when the user marks a reminder done).
///
/// The section hides itself when [vehicleId] is null — reminders
/// need a stable id so they can be attached. The edit screen lets
/// the user save a new vehicle first to unlock this section.
class ServiceReminderSection extends ConsumerWidget {
  final String vehicleId;

  /// Best-known odometer reading for this vehicle — used for the
  /// "mark as done" action. May be null when no fill-up has been
  /// logged yet, in which case the mark-done action prompts the
  /// user for the value.
  final double? currentOdometerKm;

  const ServiceReminderSection({
    super.key,
    required this.vehicleId,
    this.currentOdometerKm,
  });

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final reminders = ref.watch(serviceRemindersForVehicleProvider(vehicleId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l?.serviceRemindersSection ?? 'Service reminders',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _PresetChipRow(
          onAdd: (label, interval) => _addPreset(ref, label, interval),
        ),
        const SizedBox(height: 8),
        if (reminders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l?.serviceRemindersEmpty ??
                  'No reminders yet — pick a preset above.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...reminders.map(
            (r) => _ReminderRow(
              reminder: r,
              currentOdometerKm: currentOdometerKm,
              onMarkDone: () => _markDone(context, ref, r),
              onDelete: () => _delete(ref, r.id),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l?.addServiceReminder ?? 'Add reminder'),
          onPressed: () => _promptCustom(context, ref),
        ),
      ],
    );
  }

  void _addPreset(WidgetRef ref, String label, double intervalKm) {
    final reminder = ServiceReminder(
      id: _uuid.v4(),
      vehicleId: vehicleId,
      label: label,
      intervalKm: intervalKm,
      lastServiceOdometerKm: currentOdometerKm,
    );
    ref.read(serviceReminderListProvider.notifier).save(reminder);
  }

  void _delete(WidgetRef ref, String id) {
    ref.read(serviceReminderListProvider.notifier).remove(id);
  }

  Future<void> _markDone(
    BuildContext context,
    WidgetRef ref,
    ServiceReminder reminder,
  ) async {
    double? odo = currentOdometerKm;
    if (odo == null) {
      odo = await _promptForOdometer(context);
      if (odo == null) return;
    }
    await ref
        .read(serviceReminderListProvider.notifier)
        .markDone(reminder.id, odo);
  }

  Future<double?> _promptForOdometer(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    try {
      return await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l?.serviceReminderMarkDone ?? 'Mark as done'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l?.odometerKm ?? 'Odometer (km)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                    controller.text.trim().replaceAll(',', '.'));
                Navigator.of(ctx).pop(value);
              },
              child: Text(l?.save ?? 'Save'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _promptCustom(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final labelCtrl = TextEditingController();
    final intervalCtrl = TextEditingController();
    try {
      final added = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l?.addServiceReminder ?? 'Add reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l?.serviceReminderLabel ?? 'Label',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: intervalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                decoration: InputDecoration(
                  labelText: l?.serviceReminderInterval ?? 'Interval (km)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l?.save ?? 'Save'),
            ),
          ],
        ),
      );
      if (added != true) return;
      final label = labelCtrl.text.trim();
      final interval = double.tryParse(
        intervalCtrl.text.trim().replaceAll(',', '.'),
      );
      if (label.isEmpty || interval == null || interval <= 0) return;
      final reminder = ServiceReminder(
        id: _uuid.v4(),
        vehicleId: vehicleId,
        label: label,
        intervalKm: interval,
        lastServiceOdometerKm: currentOdometerKm,
      );
      await ref.read(serviceReminderListProvider.notifier).save(reminder);
    } finally {
      labelCtrl.dispose();
      intervalCtrl.dispose();
    }
  }
}

class _ReminderRow extends StatelessWidget {
  final ServiceReminder reminder;
  final double? currentOdometerKm;
  final VoidCallback onMarkDone;
  final VoidCallback onDelete;

  const _ReminderRow({
    required this.reminder,
    required this.currentOdometerKm,
    required this.onMarkDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final intervalText = '${reminder.intervalKm.round()} km';
    final lastService = reminder.lastServiceOdometerKm;
    final subtitle = lastService == null
        ? intervalText
        : '$intervalText • '
            '${l?.serviceReminderLastService ?? 'Last service'}: '
            '${lastService.round()} km';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            reminder.pendingAcknowledgment
                ? Icons.notification_important
                : Icons.build_circle_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.label),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: l?.serviceReminderMarkDone ?? 'Mark as done',
            onPressed: onMarkDone,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l?.delete ?? 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
