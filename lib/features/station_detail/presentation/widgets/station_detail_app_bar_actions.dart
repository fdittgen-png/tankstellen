// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/animated_favorite_star.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/domain/entities/price_alert.dart';
import '../../../alerts/presentation/widgets/create_alert_dialog.dart';
import '../../../alerts/providers/alert_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../payment/domain/qr_payment_decoder.dart';
import '../../../payment/presentation/scan_payment_dispatcher.dart';
import '../../../payment/presentation/widgets/unknown_qr_dialog.dart';
import '../../../../core/domain/station.dart';
import '../../../sync/presentation/widgets/qr_scanner_screen.dart';
import '../../providers/station_detail_provider.dart';
import 'station_brand_helpers.dart';

/// AppBar actions cluster for [StationDetailScreen]: directions, create
/// price alert, scan payment QR, report price, favorite toggle.
///
/// Extracted so the screen stays under the 300-LOC cap (#563). Public
/// behaviour is identical to the previous inline implementation —
/// same tooltips, same ordering, same callbacks.
class StationDetailAppBarActions extends ConsumerWidget {
  final String stationId;
  final Station? station;

  const StationDetailAppBarActions({
    super.key,
    required this.stationId,
    required this.station,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFav = ref.watch(isFavoriteProvider(stationId));
    final enabledFeatures = ref.watch(enabledFeaturesProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.directions),
          onPressed: () {
            final s = station;
            if (s != null) {
              unawaited(NavigationUtils.openInMaps(
                s.lat,
                s.lng,
                label: hasRealBrand(s) ? s.brand : s.street,
              ));
            }
          },
          tooltip: l10n?.navigate ?? 'Navigate',
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showCreateAlertDialog(context, ref),
          tooltip: l10n?.createAlert ?? 'Create price alert',
        ),
        // #1638 — the scan-payment-QR action is gated on the central
        // Feature enum so it can be toggled per profile.
        if (enabledFeatures.contains(Feature.paymentQrScan))
          IconButton(
            key: const Key('scan_payment_qr'),
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _startScanPayment(context),
            tooltip: l10n?.scanPayment ?? 'Scan payment QR',
          ),
        // #1638 — the community price-report action is gated on the
        // central Feature enum so it can be toggled per profile.
        if (enabledFeatures.contains(Feature.communityPriceReports))
          IconButton(
            key: const Key('report_price'),
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => ReportRoute(stationId).push<void>(context),
            tooltip: l10n?.reportPrice ?? 'Report price',
          ),
        IconButton(
          icon: AnimatedFavoriteStar(isFavorite: isFav),
          onPressed: () {
            unawaited(ref
                .read(favoritesProvider.notifier)
                .toggle(stationId, stationData: station));
          },
          tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
        ),
      ],
    );
  }

  Future<void> _showCreateAlertDialog(
      BuildContext context, WidgetRef ref) async {
    final detailAsync = ref.read(stationDetailProvider(stationId));
    final s = detailAsync.value?.data.station;
    final stationName = s != null
        ? (hasRealBrand(s) ? s.brand : s.street)
        : stationId;
    final currentPrice = s?.diesel ?? s?.e10 ?? s?.e5;

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
        SnackBarHelper.showSuccess(
            context, l10n?.alertCreated ?? 'Price alert created');
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
        final epc = target as QrPaymentEpc;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => ScanPaymentDispatcher.buildEpcDialog(ctx, epc),
        );
        if (confirmed == true && context.mounted) {
          final result = await ScanPaymentDispatcher.tryLaunchEpc(epc);
          if (!context.mounted) break;
          switch (result) {
            case EpcLaunchOutcome.launched:
              break;
            case EpcLaunchOutcome.copiedToClipboard:
              SnackBarHelper.showSuccess(
                context,
                l10n?.qrPaymentEpcCopied ??
                    'Bank details copied — paste into your banking app',
              );
            case EpcLaunchOutcome.failed:
              SnackBarHelper.showError(
                context,
                l10n?.qrPaymentLaunchFailed ??
                    'No app available to open this code',
              );
          }
        }
      case ScanPaymentOutcome.unknown:
        final unknown = target as QrPaymentUnknown;
        await showDialog<void>(
          context: context,
          builder: (ctx) => UnknownQrDialog(
            raw: unknown.raw,
            onShare: (text, subject) => SharePlus.instance.share(
              ShareParams(text: text, subject: subject),
            ),
          ),
        );
    }
  }
}
