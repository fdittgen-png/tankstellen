import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/api_key_validator.dart';

/// Third onboarding step: optional API key entry (only shown when country requires it).
class ApiKeyStep extends ConsumerStatefulWidget {
  /// Controller for the API key text field, owned by the parent wizard.
  final TextEditingController apiKeyController;

  const ApiKeyStep({super.key, required this.apiKeyController});

  @override
  ConsumerState<ApiKeyStep> createState() => _ApiKeyStepState();
}

class _ApiKeyStepState extends ConsumerState<ApiKeyStep> {
  /// Tracks whether the current API key input has valid UUID format.
  /// `null` means the field is empty (no validation state shown).
  bool? _isFormatValid;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    widget.apiKeyController.addListener(_onApiKeyChanged);
    // Initialize format validation for pre-filled values
    _evaluateFormat(widget.apiKeyController.text.trim());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.apiKeyController.removeListener(_onApiKeyChanged);
    super.dispose();
  }

  void _onApiKeyChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _evaluateFormat(widget.apiKeyController.text.trim());
    });
  }

  void _evaluateFormat(String text) {
    setState(() {
      if (text.isEmpty) {
        _isFormatValid = null;
      } else {
        _isFormatValid = ApiKeyValidator.isValidUuidFormat(text);
      }
    });
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
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.key,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.apiKeySetup ?? 'API key setup',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.onboardingApiKeyDescription ??
                'Register for a free API key, or skip to explore the app with demo data.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (country.apiKeyRegistrationUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
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
            ),
          TextField(
            controller: widget.apiKeyController,
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
            l10n?.apiKeyNote ??
                'Free registration. Data from government price transparency agencies.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (country.attribution != null)
            Text(
              country.attribution!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
