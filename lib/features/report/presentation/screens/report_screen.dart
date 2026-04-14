import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_report_service.dart';
import '../../providers/report_form_provider.dart';

enum ReportType {
  wrongE5('wrongPetrolPremium'),
  wrongE10('wrongPetrolPremiumE10'),
  wrongDiesel('wrongDiesel'),
  wrongStatusOpen('wrongStatusOpen'),
  wrongStatusClosed('wrongStatusClosed');

  final String apiValue;
  const ReportType(this.apiValue);

  bool get needsPrice =>
      this == wrongE5 || this == wrongE10 || this == wrongDiesel;

  /// Localized display name for this report type.
  String displayName(AppLocalizations? l10n) {
    switch (this) {
      case wrongE5:
        return l10n?.wrongE5Price ?? 'Wrong Super E5 price';
      case wrongE10:
        return l10n?.wrongE10Price ?? 'Wrong Super E10 price';
      case wrongDiesel:
        return l10n?.wrongDieselPrice ?? 'Wrong Diesel price';
      case wrongStatusOpen:
        return l10n?.wrongStatusOpen ?? 'Shown as open, but closed';
      case wrongStatusClosed:
        return l10n?.wrongStatusClosed ?? 'Shown as closed, but open';
    }
  }
}

/// Screen for submitting a community report about a station. Form state
/// (selected type, submission progress) lives in [reportFormControllerProvider];
/// the price text controller is owned locally for lifecycle reasons.
class ReportScreen extends ConsumerStatefulWidget {
  final String stationId;
  const ReportScreen({super.key, required this.stationId});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset form state each time the screen is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reportFormControllerProvider.notifier).selectType(null);
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final form = ref.read(reportFormControllerProvider);
    final notifier = ref.read(reportFormControllerProvider.notifier);
    final selectedType = form.selectedType;
    if (selectedType == null) return;
    if (selectedType.needsPrice && _priceController.text.isEmpty) {
      SnackBarHelper.showError(
        context,
        l10n?.enterValidPrice ?? 'Please enter a valid price',
      );
      return;
    }

    notifier.setSubmitting(true);
    try {
      final apiKeys = ref.read(apiKeyStorageProvider);
      final apiKey = apiKeys.getApiKey();
      final price = selectedType.needsPrice
          ? double.tryParse(_priceController.text.replaceAll(',', '.'))
          : null;

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
      final canSubmitTankerkoenig = country.code == 'DE' &&
          apiKey != null &&
          apiKey.isNotEmpty;
      final canSubmitTankSync = TankSyncClient.isConnected &&
          syncConfig.userId != null;

      if (!canSubmitTankerkoenig && !canSubmitTankSync) {
        if (mounted) {
          // TODO: localise via `reportNoBackendAvailable` ARB key when
          // the next batch of l10n strings is added.
          SnackBarHelper.showError(
            context,
            'Le signalement n\'a pas pu être envoyé : aucun service de '
            'report n\'est configuré pour ce pays. Activez TankSync dans '
            'les paramètres pour envoyer des signalements communautaires.',
          );
        }
        return;
      }

      if (canSubmitTankerkoenig) {
        await ReportService().submitComplaint(
          stationId: widget.stationId,
          reportType: selectedType.apiValue,
          apiKey: apiKey,
          correction: price,
        );
      }

      if (canSubmitTankSync && selectedType.needsPrice && price != null) {
        final fuelType = switch (selectedType) {
          ReportType.wrongE5 => 'e5',
          ReportType.wrongE10 => 'e10',
          ReportType.wrongDiesel => 'diesel',
          _ => 'unknown',
        };
        await CommunityReportService.submitReport(
          stationId: widget.stationId,
          fuelType: fuelType,
          reportedPrice: price,
          // #484 — was hardcoded to 'DE', mislabelling every non-DE
          // community report as German data.
          countryCode: country.code,
          supabaseUserId: syncConfig.userId,
          supabaseClient: TankSyncClient.client,
        );
      }

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          l10n?.reportSent ?? 'Report sent. Thank you!',
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          '${l10n?.retry ?? "Error"}: ${e.message}',
        );
      }
    } finally {
      if (mounted) {
        ref.read(reportFormControllerProvider.notifier).setSubmitting(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final form = ref.watch(reportFormControllerProvider);
    final selectedType = form.selectedType;

    // #484 — compute the reporting-backends availability up front so
    // we can both (a) render a banner when nothing is configured and
    // (b) disable the submit button in the same condition. Keeps the
    // UI consistent with what _submit() will actually do.
    final country = ref.watch(activeCountryProvider);
    final apiKey = ref.watch(apiKeyStorageProvider).getApiKey();
    final syncConfig = ref.watch(syncStateProvider);
    final canSubmitTankerkoenig = country.code == 'DE' &&
        apiKey != null &&
        apiKey.isNotEmpty;
    final canSubmitTankSync =
        TankSyncClient.isConnected && syncConfig.userId != null;
    final hasAnyBackend = canSubmitTankerkoenig || canSubmitTankSync;

    return Scaffold(
      appBar: AppBar(
        // #484 — was "Signaler un prix" but two of the existing options
        // (open/closed status) are not about prices and the rework will
        // add metadata-only report types. Generic "Signaler un problème"
        // matches the actual scope.
        // TODO: add `reportIssueTitle` ARB key for localisation.
        title: const Text('Signaler un problème'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // #484 — banner telling the user that no reporting backend is
          // available for their country/config. Previously the form
          // accepted their input and silently failed on submit.
          if (!hasAnyBackend) ...[
            Container(
              key: const ValueKey('report-no-backend-banner'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 20, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    // TODO: `reportNoBackendBanner` ARB key for localisation.
                    child: Text(
                      'Les signalements ne sont pas disponibles dans ce pays '
                      'pour le moment. Activez TankSync dans les paramètres '
                      'pour envoyer des signalements communautaires, ou '
                      'ajoutez une clé API Tankerkoenig si vous êtes en '
                      'Allemagne.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l10n?.whatsWrong ?? "What's wrong?",
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...ReportType.values.map(
            (type) => RadioListTile<ReportType>(
              value: type,
              groupValue: selectedType,
              title: Text(type.displayName(l10n)),
              onChanged: hasAnyBackend
                  ? (v) => ref
                      .read(reportFormControllerProvider.notifier)
                      .selectType(v)
                  : null,
            ),
          ),
          if (selectedType != null && selectedType.needsPrice) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n?.correctPrice ?? 'Correct price (e.g. 1.459)',
                prefixText: '\u20ac ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: hasAnyBackend &&
                    selectedType != null &&
                    !form.isSubmitting
                ? _submit
                : null,
            child: form.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n?.sendReport ?? 'Send report'),
          ),
        ],
      ),
    );
  }
}
