part of 'service_reminder_section.dart';

/// Preset chip row rendered above the reminder list inside
/// [ServiceReminderSection].
///
/// Three [ActionChip]s exposing the most common service intervals
/// (oil 15,000 km, tires 20,000 km, inspection 30,000 km). Each chip
/// fires [onAdd] with a localized label and the interval in km — the
/// parent owns the actual storage call.
///
/// Library-private (`part of`) so the public API of the section stays
/// unchanged.
class _PresetChipRow extends StatelessWidget {
  final void Function(String label, double intervalKm) onAdd;

  const _PresetChipRow({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.oil_barrel_outlined, size: 18),
          label:
              Text(l?.serviceReminderPresetOil ?? 'Oil (15,000 km)'),
          onPressed: () =>
              onAdd(l?.serviceReminderPresetOilLabel ?? 'Oil change', 15000),
        ),
        ActionChip(
          avatar: const Icon(Icons.tire_repair_outlined, size: 18),
          label:
              Text(l?.serviceReminderPresetTires ?? 'Tires (20,000 km)'),
          onPressed: () =>
              onAdd(l?.serviceReminderPresetTiresLabel ?? 'Tires', 20000),
        ),
        ActionChip(
          avatar: const Icon(Icons.build_outlined, size: 18),
          label: Text(
              l?.serviceReminderPresetInspection ?? 'Inspection (30,000 km)'),
          onPressed: () => onAdd(
              l?.serviceReminderPresetInspectionLabel ?? 'Inspection', 30000),
        ),
      ],
    );
  }
}
