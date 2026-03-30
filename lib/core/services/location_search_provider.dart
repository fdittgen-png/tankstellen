import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../cache/cache_manager.dart';
import 'location_search_service.dart';

part 'location_search_provider.g.dart';

@Riverpod(keepAlive: true)
LocationSearchService locationSearchService(Ref ref) {
  return LocationSearchService(ref.watch(cacheManagerProvider));
}
