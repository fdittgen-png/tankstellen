import 'package:go_router/go_router.dart';

import '../../features/carbon/presentation/screens/carbon_dashboard_screen.dart';
import '../../features/consumption/presentation/screens/add_fill_up_screen.dart';
import '../../features/consumption/presentation/screens/consumption_screen.dart';
import '../../features/consumption/presentation/screens/pick_station_for_fill_up_screen.dart';
import '../../features/consumption/presentation/screens/trip_detail_screen.dart';
import '../../features/consumption/presentation/screens/trip_history_screen.dart';
import '../../features/consumption/presentation/screens/trip_recording_screen.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import 'invalid_id_screen.dart';

/// Routes that drive the "behind-the-wheel" savings lens: consumption logging,
/// trip recording/history/detail, the carbon dashboard, and the deep-linkable
/// fill-up flow. The `/consumption-tab` path lives in [shellBranches]; this
/// file owns every consumption route that pushes on top of the shell.
List<RouteBase> get consumptionRoutes => [
      GoRoute(
        path: '/consumption',
        builder: (context, state) => const ConsumptionScreen(),
      ),
      GoRoute(
        path: '/carbon',
        builder: (context, state) => const CarbonDashboardScreen(),
      ),
      GoRoute(
        path: '/consumption/pick-station',
        builder: (_, _) => const PickStationForFillUpScreen(),
      ),
      // #726 — global trip recording view. The recording session
      // itself lives in `tripRecordingProvider` (keepAlive), so this
      // screen is a thin viewer that can come and go without losing
      // state. Opened from AddFillUpScreen after OBD2 connect, and
      // re-entered by tapping the banner shown on every screen
      // while a trip is active.
      GoRoute(
        path: '/trip-recording',
        builder: (_, _) => const TripRecordingScreen(),
      ),
      GoRoute(
        path: '/trip-history',
        builder: (_, _) => const TripHistoryScreen(),
      ),
      // #889 — placeholder trip-detail route wired up alongside the
      // new Trajets tab on the Consumption screen. Full detail UI
      // (timeline / per-minute consumption / map) lands in #890.
      GoRoute(
        path: '/trip/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          return TripDetailScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/consumption/add',
        builder: (context, state) {
          final extra = state.extra;
          String? stationId;
          String? stationName;
          FuelType? fuelType;
          double? pricePerLiter;
          if (extra is Map) {
            stationId = extra['stationId']?.toString();
            stationName = extra['stationName']?.toString();
            final ft = extra['fuelType'];
            if (ft is FuelType) fuelType = ft;
            final price = extra['pricePerLiter'];
            if (price is num) pricePerLiter = price.toDouble();
          }
          return AddFillUpScreen(
            stationId: stationId,
            stationName: stationName,
            preFilledFuelType: fuelType,
            preFilledPricePerLiter: pricePerLiter,
          );
        },
      ),
    ];
