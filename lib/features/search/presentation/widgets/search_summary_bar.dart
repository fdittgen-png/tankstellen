import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fuel_type.dart';
import '../../providers/search_provider.dart';
import '../screens/search_criteria_screen.dart';

/// Compact, 1-row summary bar shown above the results list.
///
/// Displays the current search criteria (fuel type, quantity, radius) and a
/// "Rechercher" action that opens the full [SearchCriteriaScreen]. Tapping
/// anywhere on the bar also opens the criteria screen.
///
/// Designed to be under 56dp tall and to leave the maximum amount of
/// vertical space for the results list below.
class SearchSummaryBar extends ConsumerWidget {
  const SearchSummaryBar({super.key});

  Future<void> _openCriteria(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const SearchCriteriaScreen(),
      ),
    );
  }

  String _fuelLabel(BuildContext context, FuelType type) {
    if (type == FuelType.all) {
      return AppLocalizations.of(context)?.allFuels ?? 'All';
    }
    return type.displayName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fuelType = ref.watch(selectedFuelTypeProvider);
    final radius = ref.watch(searchRadiusProvider);
    final theme = Theme.of(context);

    final fuelColor = FuelColors.forType(fuelType);
    final kmText = radius.round().toString();

    return Semantics(
      label: 'Search criteria summary. Tap to edit.',
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: () => _openCriteria(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Fuel type chip
                        _SummaryChip(
                          icon: Icon(fuelType.icon,
                              size: 16, color: fuelColor),
                          label: _fuelLabel(context, fuelType),
                        ),
                        const SizedBox(width: 6),
                        // Radius badge
                        _SummaryChip(
                          icon: const Icon(Icons.radar, size: 16),
                          label: l10n?.searchCriteriaRadiusBadge(kmText) ??
                              'Within $kmText km',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // "Rechercher" button
                FilledButton.tonalIcon(
                  onPressed: () => _openCriteria(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(
                    l10n?.searchCriteriaOpen ?? 'Search',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
