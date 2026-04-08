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
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../data/api_key_validator.dart';
import '../../providers/api_key_validator_provider.dart';

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
          SnackBarHelper.showError(context, l10n?.invalidApiKey(result.errorMessage ?? '') ?? 'Invalid API key: ${result.errorMessage}');
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

  Widget? _buildFormatIndicator() {
    if (_isFormatValid == null) return null;
    if (_isFormatValid!) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    return const Icon(Icons.error_outline, color: Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              const SizedBox(height: 24),

              // ── Language selector ──
              Text(
                l10n?.language ?? 'Language',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: AppLanguages.all.map((lang) {
                  final isSelected = lang.code == language.code;
                  return Semantics(
                    label: 'Language ${lang.nativeName}${isSelected ? ", selected" : ""}',
                    child: ChoiceChip(
                      label: Text(lang.nativeName),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(activeLanguageProvider.notifier).select(lang);
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Country selector ──
              Text(
                l10n?.country ?? 'Country',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Countries.all.map((c) {
                  final isSelected = c.code == country.code;
                  return Semantics(
                    label: 'Country ${c.name}${isSelected ? ", selected" : ""}',
                    child: ChoiceChip(
                      label: Text('${c.flag} ${c.name}'),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(activeCountryProvider.notifier).select(c);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Country-specific info ──
              Semantics(
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
                            // Status badge
                            ExcludeSemantics(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: country.requiresApiKey
                                      ? Colors.orange.shade100
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  country.requiresApiKey
                                      ? 'API key required'
                                      : 'Free — no key needed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: country.requiresApiKey
                                        ? Colors.orange.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ),
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
              ),
              const SizedBox(height: 24),

              // ── API key input (only if required) ──
              if (country.requiresApiKey) ...[
                Text(
                  'API key setup (optional)',
                  style: theme.textTheme.titleMedium,
                ),
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
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: l10n?.apiKeyLabel ?? 'API Key',
                    hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                    prefixIcon: const Icon(Icons.key),
                    border: const OutlineInputBorder(),
                    suffixIcon: _buildFormatIndicator(),
                    errorText: _isFormatValid == false
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
                const SizedBox(height: 24),
              ],

              // ── Continue button ──
              Semantics(
                button: true,
                label: _isLoading
                    ? 'Loading'
                    : (country.requiresApiKey && _apiKeyController.text.trim().isEmpty
                        ? 'Continue with demo data'
                        : 'Continue'),
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _continue,
                  icon: const Icon(Icons.arrow_forward),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          country.requiresApiKey &&
                                  _apiKeyController.text.trim().isEmpty
                              ? 'Continue with demo data'
                              : 'Continue',
                        ),
                ),
              ),

              const SizedBox(height: 24),
              if (country.attribution != null)
                Text(
                  country.attribution!,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
