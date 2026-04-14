import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../data/api_key_validator.dart';
import '../../providers/api_key_validator_provider.dart';
import '../widgets/api_key_input_section.dart';
import '../widgets/country_info_card.dart';
import '../widgets/country_selector.dart';
import '../widgets/language_selector.dart';
import '../widgets/setup_continue_button.dart';
import '../widgets/setup_header.dart';

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
              const SetupHeader(),
              const SizedBox(height: 24),
              LanguageSelector(
                selected: language,
                onSelect: (lang) =>
                    ref.read(activeLanguageProvider.notifier).select(lang),
              ),
              const SizedBox(height: 24),
              CountrySelector(
                selected: country,
                onSelect: (c) =>
                    ref.read(activeCountryProvider.notifier).select(c),
              ),
              const SizedBox(height: 24),
              CountryInfoCard(country: country),
              const SizedBox(height: 24),
              if (country.requiresApiKey) ...[
                ApiKeyInputSection(
                  country: country,
                  controller: _apiKeyController,
                  formatValid: _isFormatValid,
                  l10n: l10n,
                ),
                const SizedBox(height: 24),
              ],
              SetupContinueButton(
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
