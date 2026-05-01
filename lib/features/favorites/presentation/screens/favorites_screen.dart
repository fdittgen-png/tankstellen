import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/sharing/widget_share_renderer.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/page_scaffold.dart';
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

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  /// [GlobalKey] for the [RepaintBoundary] wrapping the Favorites tab
  /// content — passed to [shareWidgetAsImage] so the Share AppBar action
  /// (#1344) can rasterise the visible favorites list into a PNG.
  final GlobalKey _shareBoundaryKey = GlobalKey(
    debugLabel: 'favorites_share_boundary',
  );

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Rebuild on tab swipe so the AppBar can hide the Share action
    // when the user is on the Alerts tab (Share v1 only supports the
    // Favorites tab — see #1344).
    _tabController.addListener(_handleTabChange);
    Future.microtask(() {
      ref.read(favoriteStationsProvider.notifier).loadAndRefresh();
    });
  }

  void _handleTabChange() {
    // The TabController fires twice per swipe (mid-animation + on
    // settle). Only rebuild when we land on a fresh index so we don't
    // thrash setState during the transition.
    if (_tabController.indexIsChanging) return;
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // favoritesProvider merges both fuel + EV IDs, so watching it
    // rebuilds on any change to either set.
    final favoriteIds = ref.watch(favoritesProvider);
    final isFavoritesTab = _tabController.index == 0;

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

    return PageScaffold(
      title: l10n?.favorites ?? 'Favorites',
      actions: [
        if (favoriteIds.isNotEmpty && isFavoritesTab)
          IconButton(
            key: const Key('favorites_share_button'),
            icon: const Icon(Icons.share),
            tooltip: l10n?.favoritesShareAction ?? 'Share',
            onPressed: () => _onShare(context, l10n),
          ),
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
        controller: _tabController,
        tabs: [
          TabSwitcherEntry(
            label: l10n?.favorites ?? 'Favorites',
            icon: Icons.star_outline,
          ),
          TabSwitcherEntry(
            label: l10n?.priceAlerts ?? 'Price Alerts',
            icon: Icons.notifications_outlined,
          ),
        ],
      ),
      bodyPadding: EdgeInsets.zero,
      body: TabBarView(
        controller: _tabController,
        children: [
          RepaintBoundary(
            key: _shareBoundaryKey,
            child: const FavoritesFuelTab(),
          ),
          const AlertsTab(),
        ],
      ),
    );
  }

  Future<void> _onShare(
    BuildContext context,
    AppLocalizations? l10n,
  ) async {
    // Compose a friendly subject line so the OS share sheet (and the
    // receiving app's preview) shows "Tankstellen — favourites on
    // <date>" instead of a bare filename.
    final locale = Localizations.localeOf(context);
    final formattedDate =
        DateFormat.yMMMd(locale.toString()).format(DateTime.now());
    final subject = l10n?.favoritesShareSubject(formattedDate) ??
        'Tankstellen — favourites on $formattedDate';
    // Filename stem uses ISO-style yyyyMMdd so the filename is stable
    // and locale-independent (the user-visible subject still carries
    // the localised date).
    final fileNameStem =
        'tankstellen_favorites_${DateFormat('yyyyMMdd').format(DateTime.now())}';
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await shareWidgetAsImage(
        boundaryKey: _shareBoundaryKey,
        subject: subject,
        fileNameStem: fileNameStem,
      );
    } catch (e, st) {
      // Surface the failure to the user instead of silently swallowing
      // it — the snackbar tells them the share didn't go through, and
      // the debugPrint keeps the cause in `flutter logs` for support.
      debugPrint('FavoritesScreen share image: $e\n$st');
      if (messenger == null) return;
      final errorMsg = l10n?.favoritesShareError ??
          "Couldn't generate share image";
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }
}
