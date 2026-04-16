import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/ev_favorites_provider.dart';
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
    // #538 — watch both fuel and EV favorites so the screen rebuilds
    // when either set changes. The previous code only watched
    // favoritesProvider (fuel), which meant adding an EV favorite
    // never triggered a rebuild — the list stayed stale until the
    // user switched tabs or restarted the app.
    final favoriteIds = ref.watch(favoritesProvider);
    final evFavoriteIds = ref.watch(evFavoritesProvider);

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
            if (favoriteIds.isNotEmpty || evFavoriteIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
                },
                tooltip: l10n?.refreshPrices ?? 'Refresh prices',
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n?.favorites ?? 'Favorites'),
              Tab(text: l10n?.priceAlerts ?? 'Price Alerts'),
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
