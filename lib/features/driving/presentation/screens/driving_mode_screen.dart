import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/providers/search_provider.dart';
import '../widgets/driving_bottom_bar.dart';
import '../widgets/driving_lock_overlay.dart';
import '../widgets/driving_map_view.dart';
import '../widgets/driving_station_sheet.dart';
import '../widgets/driving_top_bar.dart';

/// Full-screen driving mode with oversized touch targets and minimal UI.
///
/// Features:
/// - Full-screen map with no bottom navigation
/// - Large price markers (2x normal size)
/// - 3-button bottom bar (re-center, nearest station, exit)
/// - Auto-lock overlay after 30s of inactivity
/// - Station tap shows simplified bottom sheet with Navigate button
class DrivingModeScreen extends ConsumerStatefulWidget {
  const DrivingModeScreen({super.key});

  @override
  ConsumerState<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

class _DrivingModeScreenState extends ConsumerState<DrivingModeScreen> {
  late final MapController _mapController;
  Timer? _inactivityTimer;
  bool _isLocked = false;

  /// Duration before the auto-lock overlay appears.
  static const _lockTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _resetInactivityTimer();
    // Enter immersive full-screen mode — hides status bar and nav bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _mapController.dispose();
    // Restore normal system UI when leaving driving mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_lockTimeout, () {
      if (mounted) {
        setState(() => _isLocked = true);
      }
    });
  }

  void _unlock() {
    setState(() => _isLocked = false);
    _resetInactivityTimer();
  }

  void _onUserInteraction() {
    if (_isLocked) return;
    _resetInactivityTimer();
  }

  @override
  Widget build(BuildContext context) {
    final selectedFuel = ref.watch(selectedFuelTypeProvider);
    final stations = ref.watch(fuelStationsProvider);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onUserInteraction,
        onPanDown: (_) => _onUserInteraction(),
        child: Stack(
          children: [
            DrivingMapView(
              mapController: _mapController,
              stations: stations,
              selectedFuel: selectedFuel,
              onMarkerTap: (station) =>
                  _showStationSheet(context, station, selectedFuel),
              onInteraction: _onUserInteraction,
            ),
            DrivingTopBar(selectedFuel: selectedFuel),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DrivingBottomBar(
                onRecenter: () => _recenter(stations),
                onNearestStation: () =>
                    _navigateToNearest(context, stations, selectedFuel),
                onExit: () => context.go('/map'),
              ),
            ),
            if (_isLocked) DrivingLockOverlay(onUnlock: _unlock),
          ],
        ),
      ),
    );
  }

  void _showStationSheet(
    BuildContext context,
    Station station,
    FuelType fuelType,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => DrivingStationSheet(
        station: station,
        fuelType: fuelType,
      ),
    );
  }

  void _recenter(List<Station> stations) {
    _onUserInteraction();
    if (stations.isNotEmpty) {
      _mapController.move(DrivingMapView.computeCenter(stations), 13);
    }
  }

  void _navigateToNearest(
    BuildContext context,
    List<Station> stations,
    FuelType selectedFuel,
  ) {
    _onUserInteraction();
    if (stations.isEmpty) return;

    // Sort by distance and pick the closest station that has a price for
    // the active fuel; fall back to the absolute nearest if none do.
    final sorted = [...stations]..sort((a, b) => a.dist.compareTo(b.dist));
    final nearest = sorted.firstWhere(
      (s) => s.priceFor(selectedFuel) != null,
      orElse: () => sorted.first,
    );

    _showStationSheet(context, nearest, selectedFuel);
    _mapController.move(LatLng(nearest.lat, nearest.lng), 15);
  }

}
