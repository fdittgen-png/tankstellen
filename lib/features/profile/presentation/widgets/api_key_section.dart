import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../l10n/app_localizations.dart';

class ApiKeySection extends ConsumerWidget {
  const ApiKeySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(hiveStorageProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final country = ref.watch(activeCountryProvider);
    final tankerkoenigUrl = country.apiKeyRegistrationUrl ??
        AppConstants.tankerkoenigRegistrationUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // --- Fuel Data API Key (Tankerkoenig) ---
            _buildKeyRow(
              context: context,
              theme: theme,
              icon: Icons.local_gas_station,
              title: l?.fuelPricesTankerkoenig ?? 'Fuel prices (Tankerkoenig)',
              subtitle: storage.hasApiKey()
                  ? (l?.configured ?? 'Configured')
                  : (l?.notConfigured ?? 'Not configured'),
              isConfigured: storage.hasApiKey(),
              onEdit: () => _editApiKey(context, ref, storage),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l?.requiredForFuelSearch ?? 'Required for fuel price search in Germany',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse(tankerkoenigUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    l?.register ?? 'Register free \u2192',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // --- EV Charging API Key (OpenChargeMap) ---
            _buildKeyRow(
              context: context,
              theme: theme,
              icon: Icons.ev_station,
              title: l?.evChargingOpenChargeMap ?? 'EV Charging (OpenChargeMap)',
              subtitle: storage.hasCustomEvApiKey()
                  ? (l?.customKey ?? 'Custom key')
                  : (l?.appDefaultKey ?? 'App default key'),
              isConfigured: true,
              onEdit: () => _editEvApiKey(context, ref, storage),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l?.optionalOverrideKey ?? 'Optional: override the built-in app key with your own',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://openchargemap.org/site/profile/register'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    l?.register ?? 'Register free \u2192',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConfigured,
    required VoidCallback onEdit,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isConfigured ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(subtitle),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: onEdit,
        tooltip: AppLocalizations.of(context)?.edit ?? 'Edit',
      ),
    );
  }

  Future<void> _editApiKey(
      BuildContext context, WidgetRef ref, HiveStorage storage) async {
    final controller = TextEditingController(
      text: storage.getApiKey() ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.fuelPricesApiKey ?? 'Fuel prices API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tankerkoenig API Key',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await storage.setApiKey(result);
      // Force rebuild to show updated status
      ref.invalidate(hiveStorageProvider);
    }
    controller.dispose();
  }

  Future<void> _editEvApiKey(
      BuildContext context, WidgetRef ref, HiveStorage storage) async {
    final controller = TextEditingController(
      text: storage.getEvApiKey() ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.evChargingApiKey ?? 'EV Charging API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'OpenChargeMap API Key',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await storage.setEvApiKey(result);
      // Force rebuild to show updated status
      ref.invalidate(hiveStorageProvider);
    }
    controller.dispose();
  }
}
