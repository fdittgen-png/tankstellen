import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/cross_border_suggestion.dart';
import '../../providers/cross_border_suggestion_provider.dart';
import '../../providers/search_provider.dart';

/// Banner shown above the nearby-search results when the user is close
/// to a neighbor country whose fuel is currently cheaper.
///
/// Wires up `crossBorderSuggestionProvider` (issue #1118): when the
/// user is within 25 km of a border, the provider fires a parallel
/// query against the neighbor's `StationService` (cached + coalesced
/// by `StationServiceChain`) and returns the price delta vs. the
/// current search. This banner renders that result with:
///
///  * the neighbor flag emoji,
///  * a localized "stations Xkm away — €Y/L cheaper" label,
///  * a dismiss button (per-session, resets on restart),
///  * tap-to-switch — `ActiveCountry.select()` then `searchByCoordinates`.
///
/// Shows nothing while the suggestion is loading, when no suggestion
/// is available (loading / null / dismissed), or while the suggestion
/// errors — the banner is opt-in upside, never a blocker.
class CrossBorderBanner extends ConsumerWidget {
  const CrossBorderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSuggestion = ref.watch(crossBorderSuggestionProvider);
    final dismissed = ref.watch(crossBorderBannerDismissedProvider);

    if (!asyncSuggestion.hasValue) return const SizedBox.shrink();
    final suggestion = asyncSuggestion.value;
    if (suggestion == null) return const SizedBox.shrink();
    if (dismissed.contains(suggestion.neighborCountryCode)) {
      return const SizedBox.shrink();
    }

    return _CrossBorderSuggestionCard(suggestion: suggestion);
  }
}

class _CrossBorderSuggestionCard extends ConsumerWidget {
  final CrossBorderSuggestion suggestion;

  const _CrossBorderSuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;

    final priceLabel = suggestion.priceDeltaPerLiter.toStringAsFixed(2);
    final distanceLabel = suggestion.distanceKm.toStringAsFixed(0);

    final headline = l10n?.crossBorderCheaper(
          suggestion.neighborName,
          distanceLabel,
          priceLabel,
        ) ??
        '${suggestion.neighborName} stations $distanceLabel km away '
            '— €$priceLabel/L cheaper';

    final hint = l10n?.crossBorderTapToSwitch ?? 'Tap to switch country';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.tertiary.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: () => _onTap(ref),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  suggestion.neighborFlag,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    container: true,
                    label: '$headline. $hint',
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n?.crossBorderDismissTooltip ?? 'Dismiss',
                  onPressed: () => ref
                      .read(crossBorderBannerDismissedProvider.notifier)
                      .dismiss(suggestion.neighborCountryCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(WidgetRef ref) async {
    final neighbor = Countries.byCode(suggestion.neighborCountryCode);
    if (neighbor == null) return;

    // Switch active country — the StationService provider rebuilds for
    // the new country automatically.
    await ref.read(activeCountryProvider.notifier).select(neighbor);

    // Re-run the search at the user's current position. Using
    // `searchByCoordinates` (rather than `searchByGps`) avoids a fresh
    // location-permission prompt — we already have the position.
    final position = ref.read(userPositionProvider);
    if (position == null) return;
    await ref.read(searchStateProvider.notifier).searchByCoordinates(
          lat: position.lat,
          lng: position.lng,
        );
  }
}
