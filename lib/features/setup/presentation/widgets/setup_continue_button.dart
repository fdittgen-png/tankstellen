import 'package:flutter/material.dart';

import '../../../../core/country/country_config.dart';

/// "Continue" CTA at the bottom of the setup screen. Switches its label
/// between "Continue with demo data" and "Continue" depending on whether
/// the active [CountryConfig] requires an API key and whether the user
/// has actually entered one. Renders a spinner while [isLoading] is true
/// and disables the button. Pulled out of `setup_screen.dart` so the
/// screen no longer carries this widget block inline and so the
/// label-switching + loading state can be exercised by widget tests.
class SetupContinueButton extends StatelessWidget {
  final bool isLoading;
  final CountryConfig country;
  final bool apiKeyEmpty;
  final VoidCallback onPressed;

  const SetupContinueButton({
    super.key,
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
