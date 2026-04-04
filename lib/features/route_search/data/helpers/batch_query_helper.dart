import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/route_search_strategy.dart';

/// Executes station queries in concurrent batches for faster route search.
///
/// Instead of querying each sample point sequentially (N * 500ms),
/// processes [batchSize] points concurrently, then waits before the
/// next batch. A 33-point route with batch size 4 takes ~4s instead of ~17s.
class BatchQueryHelper {
  final int batchSize;

  const BatchQueryHelper({this.batchSize = 4});

  /// Query stations at all [samplePoints] using concurrent batches.
  ///
  /// Returns deduplicated results. Failed individual queries are skipped
  /// without aborting the batch.
  Future<List<SearchResultItem>> queryAll({
    required List<LatLng> samplePoints,
    required StationQueryFunction queryStations,
    required FuelType fuelType,
    required double searchRadiusKm,
  }) async {
    final seen = <String>{};
    final results = <SearchResultItem>[];
    int successCount = 0;
    int failCount = 0;

    for (var batchStart = 0; batchStart < samplePoints.length; batchStart += batchSize) {
      final batchEnd = (batchStart + batchSize).clamp(0, samplePoints.length);
      final batch = samplePoints.sublist(batchStart, batchEnd);

      // Execute batch concurrently
      final futures = batch.map((point) async {
        try {
          return await queryStations(
            lat: point.latitude,
            lng: point.longitude,
            radiusKm: searchRadiusKm,
            fuelType: fuelType,
          );
        } catch (e) {
          debugPrint('BatchQuery: point ${point.latitude},${point.longitude} failed: $e');
          return <SearchResultItem>[];
        }
      });

      final batchResults = await Future.wait(futures);

      for (final stations in batchResults) {
        if (stations.isNotEmpty) successCount++;
        else failCount++;
        for (final item in stations) {
          if (seen.add(item.id)) {
            results.add(item);
          }
        }
      }

      // Brief pause between batches to respect rate limits
      if (batchEnd < samplePoints.length) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    debugPrint('BatchQuery: $successCount succeeded, $failCount empty/failed, ${results.length} unique stations');
    return results;
  }
}
