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
import '../../providers/report_form_provider.dart';

enum ReportType {
  // Tankerkoenig-supported price reports. apiValue maps to the types
  // the Tankerkoenig complaint endpoint recognises.
  wrongE5('wrongPetrolPremium'),
  wrongE10('wrongPetrolPremiumE10'),
  wrongDiesel('wrongDiesel'),
  // Additional price reports (#484). Tankerkoenig has no endpoint
  // for these, so they route to TankSync only. The `apiValue` is a
  // descriptive string for logging but is not sent to Tankerkoenig —
  // `isTankerkoenigSupported` below controls which backends accept
  // which types.
  wrongE85('wrongPetrolE85'),
  wrongE98('wrongPetrolPremiumE98'),
  wrongLpg('wrongLpg'),
  wrongStatusOpen('wrongStatusOpen'),
  wrongStatusClosed('wrongStatusClosed'),
  // Metadata reports (#484). These carry a free-text correction
  // instead of a price. TankSync only.
  wrongName('wrongName'),
  wrongAddress('wrongAddress');

  final String apiValue;
  const ReportType(this.apiValue);

  /// True when this report type needs the user to enter a corrected
  /// price. Price input replaces the text input in the form.
  bool get needsPrice =>
      this == wrongE5 ||
      this == wrongE10 ||
      this == wrongDiesel ||
      this == wrongE85 ||
      this == wrongE98 ||
      this == wrongLpg;

  /// True when this report type is a free-text metadata correction
  /// (new station name, new address). Takes a text input instead of
  /// a price input.
  ///
  /// Since #508 these also route to GitHub instead of TankSync —
  /// wrong metadata is almost always an implementation bug (the API
  /// returned the wrong field, or our parser mapped it wrong), not
  /// something a user correction can fix downstream.
  bool get needsText => this == wrongName || this == wrongAddress;

  /// True when this report type files a GitHub issue instead of hitting
  /// a community-report backend. Station name and address corrections
  /// are always implementation bugs — shipping them as community edits
  /// just hides the upstream issue, so we route the user to the
  /// pre-filled GitHub issue flow built in #500 instead.
  bool get routesToGitHub => this == wrongName || this == wrongAddress;

  /// True when this report type can be submitted to the Tankerkoenig
  /// complaint endpoint. The endpoint supports the original 5 types
  /// (E5, E10, diesel, status open, status closed). Everything else
  /// is TankSync-only.
  bool get isTankerkoenigSupported =>
      this == wrongE5 ||
      this == wrongE10 ||
      this == wrongDiesel ||
      this == wrongStatusOpen ||
      this == wrongStatusClosed;

  /// The Supabase `fuel_type` column value for this report. For price
  /// reports this is the fuel code; for status and metadata reports
  /// it's a descriptive identifier so analytics queries can filter
  /// by report kind.
  String get fuelTypeColumnValue {
    switch (this) {
      case wrongE5:
        return 'e5';
      case wrongE10:
        return 'e10';
      case wrongDiesel:
        return 'diesel';
      case wrongE85:
        return 'e85';
      case wrongE98:
        return 'e98';
      case wrongLpg:
        return 'lpg';
      case wrongStatusOpen:
        return 'status_open';
      case wrongStatusClosed:
        return 'status_closed';
      case wrongName:
        return 'name';
      case wrongAddress:
        return 'address';
    }
  }

  /// Returns the report types that should be visible on the report
  /// screen for a given country.
  ///
  /// - Germany: all 10 types (Tankerkoenig community report covers
  ///   prices and open/closed status; name/address still route to
  ///   GitHub because they're implementation bugs).
  /// - Everywhere else: only the 2 GitHub-routed types. The first 8
  ///   (price + status) have no meaningful backend outside DE —
  ///   Tankerkoenig is DE-only, and community price corrections don't
  ///   feed back into the source-of-truth country APIs.
  static List<ReportType> visibleForCountry(String countryCode) {
    if (countryCode == 'DE') return ReportType.values;
    return const [ReportType.wrongName, ReportType.wrongAddress];
  }

  /// Localized display name for this report type.
  String displayName(AppLocalizations? l10n) {
    switch (this) {
      case wrongE5:
        return l10n?.wrongE5Price ?? 'Prix Super E5 incorrect';
      case wrongE10:
        return l10n?.wrongE10Price ?? 'Prix Super E10 incorrect';
      case wrongDiesel:
        return l10n?.wrongDieselPrice ?? 'Prix Diesel incorrect';
      // TODO: add ARB keys for the new types. Inline French fallback
      // matches the primary user locale.
      case wrongE85:
        return 'Prix E85 incorrect';
      case wrongE98:
        return 'Prix Super 98 incorrect';
      case wrongLpg:
        return 'Prix GPL incorrect';
      case wrongStatusOpen:
        return l10n?.wrongStatusOpen ?? 'Affiché ouvert, mais fermé';
      case wrongStatusClosed:
        return l10n?.wrongStatusClosed ?? 'Affiché fermé, mais ouvert';
      case wrongName:
        return 'Nom de la station incorrect';
      case wrongAddress:
        return 'Adresse incorrecte';
    }
  }
}

/// Screen for submitting a community report about a station. Form state
/// (selected type, submission progress) lives in [reportFormControllerProvider];
/// the price text controller is owned locally for lifecycle reasons.
class ReportScreen extends ConsumerStatefulWidget {
  final String stationId;

  /// Reporter used for GitHub-routed report types (see #508). Defaults
  /// to a real [ErrorReporter] that launches the browser after the
  /// user confirms the consent dialog. Tests inject a fake.
  final ErrorReporter? reporter;

  const ReportScreen({
    super.key,
    required this.stationId,
    this.reporter,
  });

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _priceController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild submit-button enablement as the user types into
    // _priceController / _textController (the disabled-state depends
    // on whether the relevant field has content).
    _priceController.addListener(_onInputChanged);
    _textController.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reportFormControllerProvider.notifier).selectType(null);
    });
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  bool _hasRequiredInput(ReportType type) {
    if (type.needsPrice) return _priceController.text.trim().isNotEmpty;
    if (type.needsText) return _textController.text.trim().isNotEmpty;
    return true;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _textController.dispose();
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
    if (selectedType.needsText && _textController.text.trim().isEmpty) {
      // TODO: add ARB key for 'enterCorrection'.
      SnackBarHelper.showError(
        context,
        'Veuillez saisir la correction',
      );
      return;
    }

    notifier.setSubmitting(true);
    try {
      // #508 — name / address errors are implementation bugs, not
      // community data corrections. Route them to a pre-filled GitHub
      // issue instead of the Tankerkoenig / TankSync backends.
      if (selectedType.routesToGitHub) {
        final country = ref.read(activeCountryProvider);
        final correction = _textController.text.trim();
        final payload = ErrorReportPayload(
          errorType: 'WrongMetadataReport',
          errorMessage:
              '${selectedType.fuelTypeColumnValue} reported wrong for '
                  'station ${widget.stationId}: "$correction"',
          sourceLabel: country.apiProvider ?? country.name,
          countryCode: country.code,
          appVersion: ErrorReporterContext.currentAppVersion(),
          platform: ErrorReporterContext.currentPlatform(),
          locale: ErrorReporterContext.currentLocale(context),
          capturedAt: DateTime.now(),
        );
        final launched = await (widget.reporter ?? const ErrorReporter())
            .reportError(context, payload);
        if (mounted && launched) {
          SnackBarHelper.showSuccess(
            context,
            l10n?.reportSent ?? 'Report sent. Thank you!',
          );
          // Use Navigator.maybePop so the path works both under the
          // real GoRouter shell and under the plain MaterialApp that
          // widget tests use — context.pop() would throw
          // \`No GoRouter found in context\` in tests.
          await Navigator.of(context).maybePop();
        }
        return;
      }

      final apiKeys = ref.read(apiKeyStorageProvider);
      final apiKey = apiKeys.getApiKey();
      final price = selectedType.needsPrice
          ? double.tryParse(_priceController.text.replaceAll(',', '.'))
          : null;
      final correctionText =
          selectedType.needsText ? _textController.text.trim() : null;

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
            stationId: widget.stationId,
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

    // #508 — GitHub-routed types (wrongName / wrongAddress) need no
    // backend at all — the reporter opens the consent dialog and hands
    // off to the browser. So the radio row and submit button are
    // always usable when such a type is selected, regardless of
    // Tankerkoenig / TankSync availability.
    final visibleTypes = ReportType.visibleForCountry(country.code);
    final allVisibleRouteToGitHub =
        visibleTypes.every((t) => t.routesToGitHub);
    final selectedIsGitHubRouted =
        selectedType != null && selectedType.routesToGitHub;

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
          //
          // #508 — hide the banner when the user only sees GitHub-routed
          // types (non-DE case), because there's nothing to configure
          // and the form still works.
          if (!hasAnyBackend && !allVisibleRouteToGitHub) ...[
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
          ...visibleTypes.map(
            (type) => RadioListTile<ReportType>(
              value: type,
              groupValue: selectedType,
              title: Text(type.displayName(l10n)),
              // #508 — GitHub-routed types are always selectable. The
              // legacy price/status types remain gated on an available
              // Tankerkoenig/TankSync backend.
              onChanged: (type.routesToGitHub || hasAnyBackend)
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
          if (selectedType != null && selectedType.needsText) ...[
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('report-correction-text-field'),
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                // TODO: add ARB keys `correctName` / `correctAddress`.
                labelText: selectedType == ReportType.wrongName
                    ? 'Nom correct de la station'
                    : 'Adresse correcte',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: selectedType != null &&
                    !form.isSubmitting &&
                    _hasRequiredInput(selectedType) &&
                    (selectedIsGitHubRouted || hasAnyBackend)
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
