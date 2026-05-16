import '../../vehicle/domain/entities/vehicle_profile.dart' show ConnectorType;
import 'entities/brand_registry.dart';
import 'entities/search_result_item.dart';
import 'entities/station.dart';
import 'entities/station_amenity.dart';

/// Pure filter functions for the search-results pipeline.
///
/// Relocated here from `brand_filter_chips.dart` (#1762) so the memoised
/// `filteredSortedSearchResults` provider can consume them without a
/// provider→presentation import.

/// Applies brand and highway filters to a station list.
///
/// Uses [BrandRegistry] to match canonical brand names, so selecting
/// "TotalEnergies" matches "Total", "Total Access", "TOTALENERGIES", etc.
List<Station> applyBrandFilter(
  List<Station> stations, {
  required Set<String> selectedBrands,
  required bool excludeHighway,
}) {
  var result = stations;

  if (selectedBrands.isNotEmpty) {
    result = result.where((s) {
      final canonical = BrandRegistry.canonicalize(s.brand.trim());
      final label = canonical ?? BrandRegistry.othersLabel;

      // Check if any selected brand matches
      if (selectedBrands.contains(label)) return true;

      // Special case: "Autoroute" matches highway stations
      if (selectedBrands.contains('Autoroute') && s.stationType == 'A') {
        return true;
      }

      return false;
    }).toList();
  }

  if (excludeHighway) {
    result = result.where((s) => s.stationType != 'A').toList();
  }

  return result;
}

/// Filters stations by required amenities and open-status (#491).
///
/// A station passes the amenity filter only if it provides **every**
/// amenity the user selected (AND semantics, not OR). An empty
/// [requiredAmenities] set is a no-op. When [openOnly] is true, closed
/// stations are excluded regardless of amenities.
List<Station> applyAmenityAndStatusFilters(
  List<Station> stations, {
  required Set<StationAmenity> requiredAmenities,
  required bool openOnly,
}) {
  var result = stations;

  if (requiredAmenities.isNotEmpty) {
    result = result
        .where((s) => requiredAmenities.every(s.amenities.contains))
        .toList();
  }

  if (openOnly) {
    result = result.where((s) => s.isOpen).toList();
  }

  return result;
}

/// Applies the EV-only filters — connector type and minimum charging
/// power — to a list of [EVStationResult]s (#1784).
///
/// An empty [connectorTypes] set and a [minPowerKw] of `0` are each
/// no-ops. A station passes the connector filter when it offers **any**
/// of the selected connector types (OR semantics — the user is asking
/// "can I plug in here"). These filters apply only to EV rows;
/// `filteredSortedSearchResults` never routes fuel rows through them.
List<EVStationResult> applyEvFilters(
  List<EVStationResult> evResults, {
  required Set<ConnectorType> connectorTypes,
  required double minPowerKw,
}) {
  var result = evResults;

  if (connectorTypes.isNotEmpty) {
    result = result
        .where((r) =>
            r.station.connectors.any((c) => connectorTypes.contains(c.type)))
        .toList();
  }

  if (minPowerKw > 0) {
    result = result.where((r) => r.maxPowerKW >= minPowerKw).toList();
  }

  return result;
}
