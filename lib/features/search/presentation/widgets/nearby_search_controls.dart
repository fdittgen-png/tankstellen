import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import 'fuel_type_selector.dart';
import 'location_input.dart';

/// Controls for "Nearby" search mode: location input, fuel type, radius slider,
/// and search button. The search bar stays visible (sticky) while filters can
/// be collapsed after a search is performed.
class NearbySearchControls extends ConsumerWidget {
  const NearbySearchControls({
    super.key,
    required this.onGpsSearch,
    required this.onZipSearch,
    required this.onCitySearch,
    required this.isLandscape,
  });

  /// Callback to trigger GPS-based search.
  final VoidCallback onGpsSearch;

  /// Callback to trigger search by postal code.
  final ValueChanged<String> onZipSearch;

  /// Callback to trigger search by resolved city/location.
  final ValueChanged<ResolvedLocation> onCitySearch;

  /// Whether the device is in landscape orientation.
  final bool isLandscape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final radius = ref.watch(searchRadiusProvider);
    final fuelType = ref.watch(selectedFuelTypeProvider);
    final filtersExpanded = ref.watch(filtersExpandedProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar — always visible (sticky)
        LocationInput(
          onGpsSearch: onGpsSearch,
          onZipSearch: onZipSearch,
          onCitySearch: onCitySearch,
        ),
        // Collapsible filters: fuel type + radius
        AnimatedCrossFade(
          firstChild: Padding(
            padding: EdgeInsets.only(top: isLandscape ? 2 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FuelTypeSelector(),
                SizedBox(height: isLandscape ? 0 : 4),
                Row(
                  children: [
                    Text('${l10n?.searchRadius ?? "Radius"}:',
                        style: theme.textTheme.bodySmall),
                    Expanded(
                      child: Slider(
                        value: radius,
                        min: 1,
                        max: 25,
                        divisions: 24,
                        label: '${radius.round()} km',
                        onChanged: (value) {
                          ref.read(searchRadiusProvider.notifier).set(value);
                        },
                      ),
                    ),
                    Text('${radius.round()} km', style: theme.textTheme.bodySmall),
                  ],
                ),
                if (!isLandscape)
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(filtersExpandedProvider.notifier).collapse();
                      onGpsSearch();
                    },
                    icon: const Icon(Icons.search),
                    label: Text(l10n?.searchNearby ?? 'Nearby stations'),
                  ),
              ],
            ),
          ),
          secondChild: GestureDetector(
            onTap: () => ref.read(filtersExpandedProvider.notifier).set(true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${fuelType.displayName} · ${radius.round()} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more, size: 18, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          crossFadeState: filtersExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
