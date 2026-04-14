import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../data/api_key_validator.dart';
import '../../providers/api_key_validator_provider.dart';
import '../widgets/country_status_badge.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;

  /// Tracks whether the current API key input has valid UUID format.
  /// `null` means the field is empty (no validation state shown).
  bool? _isFormatValid;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _apiKeyController.addListener(_onApiKeyChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _apiKeyController.removeListener(_onApiKeyChanged);
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onApiKeyChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final text = _apiKeyController.text.trim();
      setState(() {
        if (text.isEmpty) {
          _isFormatValid = null;
        } else {
          _isFormatValid = ApiKeyValidator.isValidUuidFormat(text);
        }
      });
    });
  }

  Future<void> _continue() async {
    final country = ref.read(activeCountryProvider);

    if (country.requiresApiKey) {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        // Skip without key — demo mode
        await _finishSetup();
        return;
      }
      // Validate key
      await _validateAndSaveKey(apiKey);
    } else {
      // Country doesn't need API key — go straight in
      await _finishSetup();
    }
  }

  Future<void> _validateAndSaveKey(String apiKey) async {
    setState(() => _isLoading = true);
    try {
      final validator = ref.read(apiKeyValidatorProvider);
      final result = await validator.validate(apiKey);
      if (!result.isValid) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          SnackBarHelper.showError(
              context,
              l10n?.invalidApiKey(result.errorMessage ?? '') ??
                  'Invalid API key: ${result.errorMessage}');
        }
        return;
      }
      final apiKeys = ref.read(apiKeyStorageProvider);
      await apiKeys.setApiKey(apiKey);
      await _finishSetup();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finishSetup() async {
    final settings = ref.read(settingsStorageProvider);
    await settings.skipSetup();

    final country = ref.read(activeCountryProvider);
    final language = ref.read(activeLanguageProvider);

    final profileRepo = ref.read(profileRepositoryProvider);
    final profile = await profileRepo.ensureDefaultProfile();

    // Persist chosen country/language onto the profile
    final updated = profile.copyWith(
      countryCode: country.code,
      languageCode: language.code,
    );
    await profileRepo.updateProfile(updated);
    ref.read(activeProfileProvider.notifier).refresh();

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(activeCountryProvider);
    final language = ref.watch(activeLanguageProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const _SetupHeader(),
              const SizedBox(height: 24),
              _LanguageSelector(
                selected: language,
                onSelect: (lang) =>
                    ref.read(activeLanguageProvider.notifier).select(lang),
              ),
              const SizedBox(height: 24),
              _CountrySelector(
                selected: country,
                onSelect: (c) =>
                    ref.read(activeCountryProvider.notifier).select(c),
              ),
              const SizedBox(height: 24),
              _CountryInfoCard(country: country),
              const SizedBox(height: 24),
              if (country.requiresApiKey) ...[
                _ApiKeyInputSection(
                  country: country,
                  controller: _apiKeyController,
                  formatValid: _isFormatValid,
                  l10n: l10n,
                ),
                const SizedBox(height: 24),
              ],
              _ContinueButton(
                isLoading: _isLoading,
                country: country,
                apiKeyEmpty: _apiKeyController.text.trim().isEmpty,
                onPressed: _continue,
              ),
              const SizedBox(height: 24),
              if (country.attribution != null)
                Text(
                  country.attribution!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Setup sections — private widgets kept in-file so they share the screen's
// l10n/theme assumptions and are easy to find while editing the flow.
// ---------------------------------------------------------------------------

class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Semantics(
          excludeSemantics: true,
          child: Icon(
            Icons.local_gas_station,
            size: 72,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            l10n?.welcome ?? 'Fuel Prices',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.welcomeSubtitle ?? 'Find the cheapest fuel near you.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelect;

  const _LanguageSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n?.language ?? 'Language', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AppLanguages.all.map((lang) {
            final isSelected = lang.code == selected.code;
            return Semantics(
              label:
                  'Language ${lang.nativeName}${isSelected ? ", selected" : ""}',
              child: ChoiceChip(
                label: Text(lang.nativeName),
                selected: isSelected,
                onSelected: (_) => onSelect(lang),
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CountrySelector extends StatelessWidget {
  final CountryConfig selected;
  final ValueChanged<CountryConfig> onSelect;

  const _CountrySelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n?.country ?? 'Country', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Countries.all.map((c) {
            final isSelected = c.code == selected.code;
            return Semantics(
              label: 'Country ${c.name}${isSelected ? ", selected" : ""}',
              child: ChoiceChip(
                label: Text('${c.flag} ${c.name}'),
                selected: isSelected,
                onSelected: (_) => onSelect(c),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CountryInfoCard extends StatelessWidget {
  final CountryConfig country;

  const _CountryInfoCard({required this.country});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${country.name}, data source: ${country.apiProvider ?? 'Demo'}, '
          '${country.requiresApiKey ? 'API key required' : 'Free, no key needed'}, '
          'fuel types: ${country.fuelTypes.join(', ')}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            country.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Data: ${country.apiProvider ?? 'Demo'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  CountryStatusBadge(country: country),
                ],
              ),
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: Text(
                  'Fuel types: ${country.fuelTypes.join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ApiKeyInputSection extends StatelessWidget {
  final CountryConfig country;
  final TextEditingController controller;
  final bool? formatValid;
  final AppLocalizations? l10n;

  const _ApiKeyInputSection({
    required this.country,
    required this.controller,
    required this.formatValid,
    required this.l10n,
  });

  Widget? _buildFormatIndicator() {
    if (formatValid == null) return null;
    if (formatValid!) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    return const Icon(Icons.error_outline, color: Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('API key setup (optional)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Register for a free API key, or skip to explore '
          'the app with demo data.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (country.apiKeyRegistrationUrl != null)
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(country.apiKeyRegistrationUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: Text('${country.apiProvider} Registration'),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n?.apiKeyLabel ?? 'API Key',
            hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
            prefixIcon: const Icon(Icons.key),
            border: const OutlineInputBorder(),
            suffixIcon: _buildFormatIndicator(),
            errorText: formatValid == false
                ? (l10n?.apiKeyFormatError ??
                    'Invalid format — expected UUID (8-4-4-4-12)')
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'By entering an API key you accept the terms of '
          '${country.apiProvider}. Data redistribution is prohibited.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool isLoading;
  final CountryConfig country;
  final bool apiKeyEmpty;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.isLoading,
    required this.country,
    required this.apiKeyEmpty,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final usingDemo = country.requiresApiKey && apiKeyEmpty;
    final label = usingDemo ? 'Continue with demo data' : 'Continue';
    return Semantics(
      button: true,
      label: isLoading ? 'Loading' : label,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: const Icon(Icons.arrow_forward),
        label: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
