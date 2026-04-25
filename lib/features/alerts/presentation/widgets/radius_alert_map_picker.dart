import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-screen map-picker for choosing the center of a [RadiusAlert]
/// (#578 phase 3).
///
/// Shown via [Navigator.push]; the user pans the map under a fixed
/// crosshair and taps "Confirm" in the AppBar to return the current
/// center as a [LatLng]. "Cancel" (or back-navigation) returns `null`.
///
/// A pinned crosshair + panning map was chosen over a draggable marker
/// because it is simpler to test deterministically (the result always
/// equals the map's current center) and matches what users already
/// know from ride-share and delivery pickers.
class RadiusAlertMapPicker extends ConsumerStatefulWidget {
  /// Optional injected start position. When unset the picker falls
  /// back to the cached user position, then to the active country's
  /// example city, then to a coarse Europe fallback.
  final LatLng? initialCenter;

  /// Injected [MapController] hook so widget tests can drive the map
  /// without standing up a real tile pipeline. Production callers
  /// leave this unset; the widget builds its own controller.
  final MapController? mapController;

  const RadiusAlertMapPicker({
    super.key,
    this.initialCenter,
    this.mapController,
  });

  /// Convenience opener used by the create-sheet button. Returns the
  /// picked [LatLng], or `null` when the user cancels.
  static Future<LatLng?> push(
    BuildContext context, {
    LatLng? initialCenter,
  }) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RadiusAlertMapPicker(initialCenter: initialCenter),
      ),
    );
  }

  @override
  ConsumerState<RadiusAlertMapPicker> createState() =>
      _RadiusAlertMapPickerState();
}

class _RadiusAlertMapPickerState extends ConsumerState<RadiusAlertMapPicker> {
  late final MapController _controller;
  bool _ownsController = false;

  /// Current map center. Updated as the map pans so "Confirm" always
  /// returns the value the user sees under the crosshair.
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    if (widget.mapController != null) {
      _controller = widget.mapController!;
    } else {
      _controller = MapController();
      _ownsController = true;
    }
    _center = widget.initialCenter ?? _resolveInitialCenter();
  }

  /// Picks a sensible starting center:
  ///
  /// 1. Cached GPS position if available (most recent, highest signal).
  /// 2. Centre of the active country's bounding box, approximated by
  ///    a hard-coded dictionary so we don't reach out to the network.
  /// 3. Central Europe as a final fallback (never used in practice
  ///    since every country listed in `Countries.all` has an entry).
  LatLng _resolveInitialCenter() {
    final pos = ref.read(userPositionProvider);
    if (pos != null) {
      return LatLng(pos.lat, pos.lng);
    }
    final country = ref.read(activeCountryProvider);
    return _countryCenters[country.code] ?? const LatLng(50.0, 10.0);
  }

  /// Coarse geographic centres for every country shipping today.
  /// Values are rounded to the nearest 0.1° — enough to place the
  /// initial viewport somewhere meaningful while keeping the file
  /// free of ministry-grade precision nobody needs.
  static const Map<String, LatLng> _countryCenters = {
    'DE': LatLng(51.2, 10.4),
    'FR': LatLng(46.6, 2.2),
    'AT': LatLng(47.6, 14.1),
    'ES': LatLng(40.4, -3.7),
    'IT': LatLng(41.9, 12.6),
    'DK': LatLng(56.0, 10.0),
    'AR': LatLng(-38.4, -63.6),
    'PT': LatLng(39.4, -8.2),
    'GB': LatLng(54.0, -2.0),
    'AU': LatLng(-25.3, 133.8),
    'MX': LatLng(23.6, -102.6),
    'LU': LatLng(49.8, 6.1),
    'SI': LatLng(46.1, 14.8),
    'KR': LatLng(36.5, 127.8),
    'CL': LatLng(-35.7, -71.5),
  };

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    // `MapEvent` is fired for every camera change (pan, zoom,
    // programmatic move). We track the camera centre so the "Confirm"
    // action always returns what sits under the crosshair at the
    // moment of the tap.
    final camera = event.camera;
    if (camera.center != _center) {
      setState(() => _center = camera.center);
    }
  }

  void _confirm() {
    Navigator.of(context).pop<LatLng>(_center);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PageScaffold(
      title: l10n?.radiusAlertMapPickerTitle ?? 'Pick alert center',
      bodyPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n?.radiusAlertMapPickerCancel ?? 'Cancel',
        onPressed: _cancel,
      ),
      actions: [
        TextButton(
          onPressed: _confirm,
          child: Text(
            l10n?.radiusAlertMapPickerConfirm ?? 'Confirm',
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
        ),
      ],
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              minZoom: 3,
              maxZoom: 18,
              onMapEvent: _onMapEvent,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.osmUserAgent,
                // #757 — evict failed tiles once off-screen.
                evictErrorTileStrategy:
                    EvictErrorTileStrategy.notVisibleRespectMargin,
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          // Fixed crosshair marking the picked location. Sits on top
          // of the map (not a marker layer) so the visual stays put
          // while the map pans underneath.
          IgnorePointer(
            child: Icon(
              Icons.add_location_alt,
              size: 48,
              color: theme.colorScheme.primary,
              shadows: const [
                Shadow(blurRadius: 4, color: Colors.black54),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n?.radiusAlertMapPickerHint ??
                      'Drag the map to position the alert center',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
