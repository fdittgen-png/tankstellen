import 'package:flutter/material.dart';

import '../../../../core/country/country_config.dart';

/// Small pill that labels a country with either "API key required" (orange)
/// or "Free — no key needed" (green). Used inside the country picker on
/// the Setup screen.
///
/// Pulled out of `setup_screen.dart` so the screen stops carrying the
/// inline private widget and so the badge can be exercised by widget
/// tests in isolation. The styling rule (orange vs green based on
/// `country.requiresApiKey`) now lives in exactly one place.
class CountryStatusBadge extends StatelessWidget {
  final CountryConfig country;

  const CountryStatusBadge({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final requiresKey = country.requiresApiKey;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              requiresKey ? Colors.orange.shade100 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          requiresKey ? 'API key required' : 'Free — no key needed',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color:
                requiresKey ? Colors.orange.shade800 : Colors.green.shade800,
          ),
        ),
      ),
    );
  }
}
