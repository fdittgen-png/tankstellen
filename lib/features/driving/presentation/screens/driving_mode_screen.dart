import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/providers/search_provider.dart';
import '../widgets/driving_bottom_bar.dart';
import '../widgets/driving_marker_builder.dart';
import '../widgets/driving_station_sheet.dart';

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
    final searchState = ref.watch(searchStateProvider);
    final selectedFuel = ref.watch(selectedFuelTypeProvider);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onUserInteraction,
        onPanDown: (_) => _onUserInteraction(),
        child: Stack(
          children: [
            // Map layer
            _buildMap(context, searchState, selectedFuel),
            // Top bar with fuel type
            _buildTopBar(context, selectedFuel),
            // Bottom control bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DrivingBottomBar(
                onRecenter: () => _recenter(searchState),
                onNearestStation: () =>
                    _navigateToNearest(context, searchState, selectedFuel),
                onExit: () => context.go('/map'),
              ),
            ),
            // Auto-lock overlay
            if (_isLocked) _buildLockOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    AsyncValue searchState,
    FuelType selectedFuel,
  ) {
    final stations = _extractStations(searchState);
    if (stations.isEmpty) {
      return FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(52.52, 13.405),
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: AppConstants.osmTileUrl,
            userAgentPackageName: AppConstants.osmUserAgent,
          ),
        ],
      );
    }

    final center = _computeCenter(stations);
    final priceRange = _getPriceRange(stations, selectedFuel);

    final markers = stations.map((station) {
      return DrivingMarkerBuilder.build(
        station,
        selectedFuel,
        priceRange.$1,
        priceRange.$2,
        onTap: () {
          _onUserInteraction();
          _showStationSheet(context, station, selectedFuel);
        },
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.doubleTapZoom,
        ),
        onTap: (_, _) => _onUserInteraction(),
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.osmTileUrl,
          userAgentPackageName: AppConstants.osmUserAgent,
        ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, FuelType selectedFuel) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).viewPadding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: topPadding + 8,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface.withValues(alpha: 0.9),
              theme.colorScheme.surface.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.drive_eta, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              l10n?.drivingMode ?? 'Driving Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedFuel.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Positioned.fill(
      child: GestureDetector(
        onTap: _unlock,
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(
                  l10n?.drivingTapToUnlock ?? 'Tap to unlock',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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

  void _recenter(AsyncValue searchState) {
    _onUserInteraction();
    final stations = _extractStations(searchState);
    if (stations.isNotEmpty) {
      final center = _computeCenter(stations);
      _mapController.move(center, 13);
    }
  }

  void _navigateToNearest(
    BuildContext context,
    AsyncValue searchState,
    FuelType selectedFuel,
  ) {
    _onUserInteraction();
    final stations = _extractStations(searchState);
    if (stations.isEmpty) return;

    // Sort by distance and pick closest with a price
    final sorted = [...stations]
      ..sort((a, b) => a.dist.compareTo(b.dist));
    final nearest = sorted.firstWhere(
      (s) => s.priceFor(selectedFuel) != null,
      orElse: () => sorted.first,
    );

    _showStationSheet(context, nearest, selectedFuel);
    _mapController.move(LatLng(nearest.lat, nearest.lng), 15);
  }

  List<Station> _extractStations(AsyncValue searchState) {
    if (!searchState.hasValue) return [];
    final result = searchState.value;
    if (result == null) return [];
    return result.data as List<Station>? ?? [];
  }

  LatLng _computeCenter(List<Station> stations) {
    double sumLat = 0, sumLng = 0;
    for (final s in stations) {
      sumLat += s.lat;
      sumLng += s.lng;
    }
    return LatLng(sumLat / stations.length, sumLng / stations.length);
  }

  static (double, double) _getPriceRange(
    List<Station> stations,
    FuelType fuel,
  ) {
    double minP = double.infinity;
    double maxP = 0;
    for (final s in stations) {
      final p = priceForFuelType(s, fuel);
      if (p != null) {
        if (p < minP) minP = p;
        if (p > maxP) maxP = p;
      }
    }
    if (minP == double.infinity) return (0, 0);
    return (minP, maxP);
  }
}
