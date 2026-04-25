import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/country/country_provider.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error_reporting/error_report_payload.dart';
import '../../../../core/error_reporting/error_reporter.dart';
import '../../../../core/error_reporting/error_reporter_context.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_report_service.dart';
import '../../domain/entities/report_type.dart';
import '../../providers/report_form_provider.dart';

/// Encapsulates the submit-flow for [ReportScreen]. Split out of the
/// screen file in #563 so the screen stays under the 300-LOC budget and
/// so the dispatching logic (GitHub vs Tankerkoenig vs TankSync) is
/// reachable from a single place.
class ReportSubmitHandler {
  ReportSubmitHandler({
    required this.context,
    required this.ref,
    required this.stationId,
    required this.priceController,
    required this.textController,
    this.reporter,
  });

  final BuildContext context;
  final WidgetRef ref;
  final String stationId;
  final TextEditingController priceController;
  final TextEditingController textController;
  final ErrorReporter? reporter;

  Future<void> submit() async {
    final l10n = AppLocalizations.of(context);
    final form = ref.read(reportFormControllerProvider);
    final notifier = ref.read(reportFormControllerProvider.notifier);
    final selectedType = form.selectedType;
    if (selectedType == null) return;
    if (selectedType.needsPrice && priceController.text.isEmpty) {
      SnackBarHelper.showError(
        context,
        l10n?.enterValidPrice ?? 'Please enter a valid price',
      );
      return;
    }
    if (selectedType.needsText && textController.text.trim().isEmpty) {
      SnackBarHelper.showError(
        context,
        l10n?.enterCorrection ?? 'Please enter the correction',
      );
      return;
    }

    notifier.setSubmitting(true);
    try {
      // #508 — name / address errors are implementation bugs, not
      // community data corrections. Route them to a pre-filled GitHub
      // issue instead of the Tankerkoenig / TankSync backends.
      if (selectedType.routesToGitHub) {
        await _routeToGitHub(selectedType, l10n);
        return;
      }

      final apiKeys = ref.read(apiKeyStorageProvider);
      final apiKey = apiKeys.getApiKey();
      final price = selectedType.needsPrice
          ? double.tryParse(priceController.text.replaceAll(',', '.'))
          : null;
      final correctionText =
          selectedType.needsText ? textController.text.trim() : null;

      // #484 — resolve the reporting backends for the current country
      // and config. Before this fix the screen always hit the
      // Tankerkoenig complaint endpoint (which exists only for DE and
      // requires an API key), so every non-DE user saw a silent failure.
      // Now:
      //   - Tankerkoenig: only when country == DE AND a key is set
      //   - TankSync community reports: whenever TankSync is connected,
      //     tagged with the user's ACTUAL country (not hardcoded 'DE')
      //   - If neither backend is available, fail loudly with a
      //     banner-style error so the user knows their report was not
      //     sent anywhere.
      final country = ref.read(activeCountryProvider);
      final syncConfig = ref.read(syncStateProvider);
      // #484 — Tankerkoenig only accepts the 5 original report types.
      // Metadata and extended-fuel types (wrongE85, wrongName, etc.)
      // route to TankSync only, even in Germany with a key set.
      final canSubmitTankerkoenig = country.code == 'DE' &&
          apiKey != null &&
          apiKey.isNotEmpty &&
          selectedType.isTankerkoenigSupported;
      final canSubmitTankSync = TankSyncClient.isConnected &&
          syncConfig.userId != null;

      if (!canSubmitTankerkoenig && !canSubmitTankSync) {
        if (context.mounted) {
          SnackBarHelper.showError(
            context,
            l10n?.reportNoBackendAvailable ??
                'The report could not be sent: no reporting service is '
                    'configured for this country. Enable TankSync in Settings '
                    'to send community reports.',
          );
        }
        return;
      }

      if (canSubmitTankerkoenig) {
        await ReportService().submitComplaint(
          stationId: stationId,
          reportType: selectedType.apiValue,
          apiKey: apiKey,
          correction: price,
        );
      }

      if (canSubmitTankSync) {
        // #484 — dispatch by report shape. Price reports carry
        // reportedPrice, metadata reports carry correctionText, status
        // reports carry neither (they don't hit TankSync — the row
        // would fail the check constraint, so we skip).
        final hasPricePayload = selectedType.needsPrice && price != null;
        final hasTextPayload =
            selectedType.needsText && correctionText != null;
        if (hasPricePayload || hasTextPayload) {
          await CommunityReportService.submitReport(
            stationId: stationId,
            fuelType: selectedType.fuelTypeColumnValue,
            reportedPrice: hasPricePayload ? price : null,
            correctionText: hasTextPayload ? correctionText : null,
            // #484 — was hardcoded to 'DE', mislabelling every non-DE
            // community report as German data.
            countryCode: country.code,
            supabaseUserId: syncConfig.userId,
            supabaseClient: TankSyncClient.client,
          );
        }
      }

      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          l10n?.reportSent ?? 'Report sent. Thank you!',
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          '${l10n?.retry ?? "Error"}: ${e.message}',
        );
      }
    } finally {
      if (context.mounted) {
        ref.read(reportFormControllerProvider.notifier).setSubmitting(false);
      }
    }
  }

  Future<void> _routeToGitHub(
    ReportType selectedType,
    AppLocalizations? l10n,
  ) async {
    final country = ref.read(activeCountryProvider);
    final correction = textController.text.trim();
    final payload = ErrorReportPayload(
      errorType: 'WrongMetadataReport',
      errorMessage:
          '${selectedType.fuelTypeColumnValue} reported wrong for '
              'station $stationId: "$correction"',
      sourceLabel: country.apiProvider ?? country.name,
      countryCode: country.code,
      appVersion: ErrorReporterContext.currentAppVersion(),
      platform: ErrorReporterContext.currentPlatform(),
      locale: ErrorReporterContext.currentLocale(context),
      capturedAt: DateTime.now(),
    );
    final launched =
        await (reporter ?? const ErrorReporter()).reportError(context, payload);
    if (context.mounted && launched) {
      SnackBarHelper.showSuccess(
        context,
        l10n?.reportSent ?? 'Report sent. Thank you!',
      );
      // Use Navigator.maybePop so the path works both under the
      // real GoRouter shell and under the plain MaterialApp that
      // widget tests use — context.pop() would throw
      // `No GoRouter found in context` in tests.
      await Navigator.of(context).maybePop();
    }
  }
}
