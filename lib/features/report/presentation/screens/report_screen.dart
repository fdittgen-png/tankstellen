import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

      await ReportService().submitComplaint(
        stationId: widget.stationId,
        reportType: selectedType.apiValue,
        apiKey: apiKey,
        correction: price,
      );

      // Also submit to Supabase community reports if connected
      if (selectedType.needsPrice && TankSyncClient.isConnected) {
        final syncConfig = ref.read(syncStateProvider);
        if (price != null && syncConfig.userId != null) {
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
            countryCode: 'DE',
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
    final form = ref.watch(reportFormControllerProvider);
    final selectedType = form.selectedType;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.reportPrice ?? 'Report price'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n?.whatsWrong ?? "What's wrong?",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...ReportType.values.map(
            (type) => RadioListTile<ReportType>(
              value: type,
              groupValue: selectedType,
              title: Text(type.displayName(l10n)),
              onChanged: (v) => ref
                  .read(reportFormControllerProvider.notifier)
                  .selectType(v),
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
            onPressed:
                selectedType != null && !form.isSubmitting ? _submit : null,
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
