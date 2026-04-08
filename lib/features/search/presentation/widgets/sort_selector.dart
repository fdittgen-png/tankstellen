import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

enum SortMode { distance, price, name, open24h, rating, priceDistance }

class SortSelector extends StatelessWidget {
  final SortMode selected;
  final ValueChanged<SortMode> onChanged;

  const SortSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SortChip(
              label: l10n?.sortDistance ?? 'Distance',
              icon: Icons.near_me,
              selected: selected == SortMode.distance,
              onSelected: () => onChanged(SortMode.distance),
            ),
            const SizedBox(width: 6),
            _SortChip(
              label: l10n?.price ?? 'Price',
              icon: Icons.euro,
              selected: selected == SortMode.price,
              onSelected: () => onChanged(SortMode.price),
            ),
            const SizedBox(width: 6),
            _SortChip(
              label: 'A-Z',
              icon: Icons.sort_by_alpha,
              selected: selected == SortMode.name,
              onSelected: () => onChanged(SortMode.name),
            ),
            const SizedBox(width: 6),
            _SortChip(
              label: l10n?.sortOpen24h ?? '24h',
              icon: Icons.schedule,
              selected: selected == SortMode.open24h,
              onSelected: () => onChanged(SortMode.open24h),
            ),
            const SizedBox(width: 6),
            _SortChip(
              label: l10n?.sortRating ?? 'Rating',
              icon: Icons.star,
              selected: selected == SortMode.rating,
              onSelected: () => onChanged(SortMode.rating),
            ),
            const SizedBox(width: 6),
            _SortChip(
              label: l10n?.sortPriceDistance ?? 'Price/km',
              icon: Icons.balance,
              selected: selected == SortMode.priceDistance,
              onSelected: () => onChanged(SortMode.priceDistance),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sort by $label${selected ? ", selected" : ""}',
      child: ChoiceChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
