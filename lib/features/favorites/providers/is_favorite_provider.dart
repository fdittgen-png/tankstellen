import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'favorites_provider.dart';

part 'is_favorite_provider.g.dart';

/// Whether a specific station is favorited (checks both fuel and EV).
@riverpod
bool isFavorite(Ref ref, String stationId) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.contains(stationId);
}

/// Whether a specific EV station is favorited (backward compatibility alias).
@riverpod
bool isEvFavorite(Ref ref, String stationId) {
  return ref.watch(isFavoriteProvider(stationId));
}
