import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/station_type_filter.dart';

part 'station_type_filter_provider.g.dart';

/// Controls whether the search screen shows fuel or EV results.
@Riverpod(keepAlive: true)
class ActiveStationTypeFilter extends _$ActiveStationTypeFilter {
  @override
  StationTypeFilter build() => StationTypeFilter.fuel;

  void set(StationTypeFilter filter) => state = filter;
}
