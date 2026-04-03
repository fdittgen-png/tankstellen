import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_report_service.dart';

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

class ReportScreen extends ConsumerStatefulWidget {
  final String stationId;
  const ReportScreen({super.key, required this.stationId});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  ReportType? _selectedType;
  final _priceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedType == null) return;
    if (_selectedType!.needsPrice && _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l10n?.enterValidPrice ?? 'Please enter a valid price')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiKeys = ref.read(apiKeyStorageProvider);
      final apiKey = apiKeys.getApiKey();

      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {'User-Agent': AppConstants.userAgent},
      ));

      await dio.post(
        ApiConstants.complaintEndpoint,
        data: {
          'id': widget.stationId,
          'type': _selectedType!.apiValue,
          if (_selectedType!.needsPrice)
            'correction': double.tryParse(
              _priceController.text.replaceAll(',', '.'),
            ),
          'apikey': apiKey,
        },
      );

      // Also submit to Supabase community reports if connected
      if (_selectedType!.needsPrice && TankSyncClient.isConnected) {
        final syncConfig = ref.read(syncStateProvider);
        final price = double.tryParse(
          _priceController.text.replaceAll(',', '.'),
        );
        if (price != null && syncConfig.userId != null) {
          // Map report type to fuel type string
          final fuelType = switch (_selectedType!) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.reportSent ?? 'Report sent. Thank you!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.retry ?? "Error"}: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          ...ReportType.values.map((type) => RadioListTile<ReportType>(
                value: type,
                groupValue: _selectedType,
                title: Text(type.displayName(l10n)),
                onChanged: (v) => setState(() => _selectedType = v),
              )),
          if (_selectedType != null && _selectedType!.needsPrice) ...[
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
                _selectedType != null && !_isSubmitting ? _submit : null,
            child: _isSubmitting
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
