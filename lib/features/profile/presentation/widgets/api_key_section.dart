// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';

class ApiKeySection extends ConsumerWidget {
  const ApiKeySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(apiKeyStorageProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final country = ref.watch(activeCountryProvider);
    final tankerkoenigUrl =
        country.apiKeyRegistrationUrl ??
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
              title: l.fuelPricesTankerkoenig,
              subtitle: storage.hasApiKey()
                  ? (l.configured)
                  : (l.notConfigured),
              isConfigured: storage.hasApiKey(),
              onEdit: () => _editApiKey(context, ref, storage),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.requiredForFuelSearch,
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
                    l.register,
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
              title: l.evChargingOpenChargeMap,
              subtitle: storage.hasCustomEvApiKey()
                  ? (l.customKey)
                  : (l.appDefaultKey),
              isConfigured: true,
              onEdit: () => _editEvApiKey(context, ref, storage),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.optionalOverrideKey,
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
                    Uri.parse(
                      'https://openchargemap.org/site/profile/register',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    l.register,
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
            color: isConfigured
                ? DarkModeColors.success(context)
                : DarkModeColors.error(context),
          ),
          const SizedBox(width: 6),
          Text(subtitle),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: onEdit,
        tooltip: AppLocalizations.of(context).edit,
      ),
    );
  }

  Future<void> _editApiKey(
    BuildContext context,
    WidgetRef ref,
    ApiKeyStorage storage,
  ) async {
    final controller = TextEditingController(text: storage.getApiKey() ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).fuelPricesApiKey),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).tankerkoenigApiKeyLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await storage.setApiKey(result);
      // Force rebuild to show updated status. #3159 — mounted guard: the
      // dialog + storage awaits mean the section can be gone here, and
      // invalidating a dead WidgetRef throws a StateError under Riverpod 3.
      if (context.mounted) ref.invalidate(apiKeyStorageProvider);
    }
    controller.dispose();
  }

  Future<void> _editEvApiKey(
    BuildContext context,
    WidgetRef ref,
    ApiKeyStorage storage,
  ) async {
    final controller = TextEditingController(text: storage.getEvApiKey() ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).evChargingApiKey),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).openChargeMapApiKeyLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await storage.setEvApiKey(result);
      // Force rebuild to show updated status. #3159 — see _editApiKey.
      if (context.mounted) ref.invalidate(apiKeyStorageProvider);
    }
    controller.dispose();
  }
}
