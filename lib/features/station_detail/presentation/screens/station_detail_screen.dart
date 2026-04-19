import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/domain/entities/price_alert.dart';
import '../../../alerts/presentation/widgets/create_alert_dialog.dart';
import '../../../alerts/providers/alert_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/brand_registry.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../payment/domain/qr_payment_decoder.dart';
import '../../../payment/presentation/scan_payment_dispatcher.dart';
import '../../../sync/presentation/widgets/qr_scanner_screen.dart';
import '../../providers/station_detail_provider.dart';
import '../widgets/price_history_section.dart';
import '../widgets/price_tile.dart';
import '../widgets/station_info_section.dart';
import '../widgets/station_rating_section.dart';
import '../widgets/station_status_row.dart';

/// True when the station has a real, displayable brand — i.e. not
/// empty and not one of the sentinel strings that parsers use when
/// they cannot detect a brand (`'Station'` is the legacy sentinel,
/// `BrandRegistry.independentLabel` is the new one from #482). Used
/// everywhere the detail screen decides whether to render the brand
/// text or fall back to the street address as the title.
bool _hasRealBrand(Station s) {
  if (s.brand.isEmpty) return false;
  if (s.brand == 'Station') return false;
  if (s.brand == BrandRegistry.independentLabel) return false;
  return true;
}

/// True when the station's brand is the explicit "independent" sentinel
/// (or the legacy `'Station'` value). The detail view uses this to
/// render a localised "Station indépendante" subtitle so users can tell
/// the difference between a genuine independent and a brand-detection
/// bug (#482).
bool _isIndependentSentinel(Station s) =>
    s.brand == BrandRegistry.independentLabel || s.brand == 'Station';

class StationDetailScreen extends ConsumerWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stationDetailProvider(stationId));
    final isFav = ref.watch(isFavoriteProvider(stationId));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(AppLocalizations.of(context)?.search ?? 'Station'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: AppLocalizations.of(context)?.tooltipBack ?? 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: () {
              final station = detailAsync.value?.data.station;
              if (station != null) {
                NavigationUtils.openInMaps(station.lat, station.lng,
                    label: _hasRealBrand(station)
                        ? station.brand
                        : station.street);
              }
            },
            tooltip: l10n?.navigate ?? 'Navigate',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showCreateAlertDialog(context, ref),
            tooltip: l10n?.createAlert ?? 'Create price alert',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _startScanPayment(context),
            tooltip: l10n?.scanPayment ?? 'Scan payment QR',
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => context.push('/report/$stationId'),
            tooltip: l10n?.reportPrice ?? 'Report price',
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : null,
            ),
            onPressed: () {
              final station = detailAsync.value?.data.station;
              ref.read(favoritesProvider.notifier).toggle(stationId, stationData: station);
            },
            tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: detailAsync.when(
        data: (result) => Column(
          children: [
            ServiceStatusBanner(result: result),
            Expanded(child: _buildContent(context, ref, result.data, result)),
          ],
        ),
        loading: () => const ShimmerStationDetail(),
        error: (error, _) => ServiceChainErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(stationDetailProvider(stationId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    StationDetail detail,
    ServiceResult<StationDetail> serviceResult,
  ) {
    final station = detail.station;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Open/closed status + freshness inline + rating stars (top-right)
          StationStatusRow(
            station: station,
            serviceResult: serviceResult,
            stationId: stationId,
          ),
          const SizedBox(height: 12),

          // Brand logo + Name
          //
          // #482: stations returned without a recognised brand previously
          // rendered just the street address, leaving the user unsure
          // whether the missing brand was a bug or the station genuinely
          // had no chain affiliation. Now we also show an explicit
          // "Station indépendante" subtitle when the parser flagged the
          // station with the independent sentinel.
          Semantics(
            label:
                '${_hasRealBrand(station) ? station.brand : station.street}'
                '${_hasRealBrand(station) && station.brand != station.street ? ', ${station.street}' : ''}',
            header: true,
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BrandLogo(brand: station.brand, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasRealBrand(station)
                            ? station.brand
                            : station.street,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_hasRealBrand(station) &&
                          station.brand != station.street)
                        Text(station.street, style: theme.textTheme.bodyLarge),
                      if (_isIndependentSentinel(station))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          // TODO: localise via an `independentStation`
                          // ARB key when the next batch of l10n keys
                          // is added. Inline French fallback here
                          // matches the primary user locale and the
                          // inline fallback pattern used elsewhere on
                          // this screen for strings not yet in the
                          // ARB files.
                          child: Text(
                            'Station indépendante',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Prices (compact)
          Semantics(
            header: true,
            child: Text(l10n?.prices ?? 'Prices', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 6),
          PriceTile(label: 'Super E5', price: station.e5, fuelType: FuelType.e5),
          PriceTile(label: 'Super E10', price: station.e10, fuelType: FuelType.e10),
          PriceTile(label: 'Diesel', price: station.diesel, fuelType: FuelType.diesel),
          if (station.e98 != null) PriceTile(label: 'Super 98', price: station.e98, fuelType: FuelType.e98),
          if (station.e85 != null) PriceTile(label: 'E85', price: station.e85, fuelType: FuelType.e85),
          if (station.lpg != null) PriceTile(label: 'LPG', price: station.lpg, fuelType: FuelType.lpg),
          if (station.cng != null) PriceTile(label: 'CNG', price: station.cng, fuelType: FuelType.cng),
          const SizedBox(height: 12),
          _LogFillUpButton(station: station),
          const SizedBox(height: 16),

          // Address, opening hours, fuels, location (services moved to bottom)
          StationInfoSection(station: station, detail: detail),

          // Rating (interactive)
          const SizedBox(height: 16),
          StationRatingSection(stationId: stationId),

          // Price History
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(l10n?.priceHistory ?? 'Price History', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          PriceHistorySection(stationId: stationId, station: station),
        ],
      ),
    );
  }

  Future<void> _showCreateAlertDialog(BuildContext context, WidgetRef ref) async {
    final detailAsync = ref.read(stationDetailProvider(stationId));
    final station = detailAsync.value?.data.station;
    final stationName = station != null
        ? (_hasRealBrand(station) ? station.brand : station.street)
        : stationId;
    final currentPrice = station?.diesel ?? station?.e10 ?? station?.e5;

    final alert = await showDialog<PriceAlert>(
      context: context,
      builder: (context) => CreateAlertDialog(
        stationId: stationId,
        stationName: stationName,
        currentPrice: currentPrice,
      ),
    );

    if (alert != null && context.mounted) {
      await ref.read(alertProvider.notifier).addAlert(alert);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showSuccess(context, l10n?.alertCreated ?? 'Price alert created');
      }
    }
  }

  /// Opens the mobile_scanner surface, decodes the scanned value and
  /// dispatches to url_launcher / a confirmation dialog / a fallback
  /// sheet based on the [QrPaymentTarget] classification (#587).
  Future<void> _startScanPayment(BuildContext context) async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (raw == null || !context.mounted) return;

    final target = QrPaymentDecoder.decode(raw);
    final outcome = await ScanPaymentDispatcher.handle(target);
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case ScanPaymentOutcome.launched:
        break;
      case ScanPaymentOutcome.launchFailed:
        SnackBarHelper.showError(
          context,
          l10n?.qrPaymentLaunchFailed ??
              'No app available to open this code',
        );
      case ScanPaymentOutcome.confirmEpc:
        await showDialog<bool>(
          context: context,
          builder: (ctx) => ScanPaymentDispatcher.buildEpcDialog(
            ctx,
            target as QrPaymentEpc,
          ),
        );
      case ScanPaymentOutcome.unknown:
        await showDialog<void>(
          context: context,
          builder: (ctx) {
            final unknown = target as QrPaymentUnknown;
            return AlertDialog(
              title: Text(
                l10n?.qrPaymentUnknownTitle ?? 'Unrecognised code',
              ),
              content: SelectableText(unknown.raw),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
              ],
            );
          },
        );
    }
  }
}

/// "Log fill-up here" button. Reads the active profile's preferred fuel
/// type and the station's current price for that fuel, then navigates to
/// [AddFillUpScreen] with both pre-filled so the user only needs to type
/// liters and odometer.
class _LogFillUpButton extends ConsumerWidget {
  final Station station;

  const _LogFillUpButton({required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final preferredFuel = profile?.preferredFuelType;
    // Fall back to any fuel the station reports if the profile fuel isn't
    // available at this station (e.g. diesel-preferring user at a petrol-only
    // bio station).
    final pricedFuel = preferredFuel != null &&
            station.priceFor(preferredFuel) != null
        ? preferredFuel
        : _firstAvailableFuel(station);
    final pricePerLiter =
        pricedFuel != null ? station.priceFor(pricedFuel) : null;
    final stationName = station.brand.isNotEmpty &&
            station.brand != 'Station' &&
            station.brand != BrandRegistry.independentLabel
        ? station.brand
        : station.street;

    return OutlinedButton.icon(
      onPressed: () {
        final extra = <String, Object>{
          'stationId': station.id,
          'stationName': stationName,
        };
        if (pricedFuel != null) extra['fuelType'] = pricedFuel;
        if (pricePerLiter != null) extra['pricePerLiter'] = pricePerLiter;
        context.push('/consumption/add', extra: extra);
      },
      icon: const Icon(Icons.local_gas_station_outlined),
      label: Text(
        AppLocalizations.of(context)?.addFillUp ?? 'Log fill-up here',
      ),
    );
  }

  /// Returns the first fuel type for which this station has a price, in a
  /// predictable priority order. Used when the profile fuel isn't available
  /// at the station, so the button can still pre-fill a reasonable default.
  static FuelType? _firstAvailableFuel(Station s) {
    const order = [
      FuelType.e10,
      FuelType.e5,
      FuelType.diesel,
      FuelType.e98,
      FuelType.e85,
      FuelType.lpg,
      FuelType.cng,
    ];
    for (final f in order) {
      if (s.priceFor(f) != null) return f;
    }
    return null;
  }
}
