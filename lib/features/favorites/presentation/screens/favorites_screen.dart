import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/tab_switcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/favorites_provider.dart';
import '../widgets/alerts_tab.dart';
import '../widgets/favorites_fuel_tab.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // favoritesProvider merges both fuel + EV IDs, so watching it
    // rebuilds on any change to either set.
    final favoriteIds = ref.watch(favoritesProvider);

    // Reload favorites when the auth identity changes
    // (anonymous -> email, reconnect, disconnect, etc.)
    ref.listen(
      syncStateProvider.select((s) => s.userId),
      (prev, next) {
        if (prev != next) {
          ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
        }
      },
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            child: Text(l10n?.favorites ?? 'Favorites'),
          ),
          actions: [
            if (favoriteIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
                },
                tooltip: l10n?.refreshPrices ?? 'Refresh prices',
              ),
          ],
          bottom: TabSwitcher(
            tabs: [
              TabSwitcherEntry(label: l10n?.favorites ?? 'Favorites'),
              TabSwitcherEntry(label: l10n?.priceAlerts ?? 'Price Alerts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FavoritesFuelTab(),
            AlertsTab(),
          ],
        ),
      ),
    );
  }
}
