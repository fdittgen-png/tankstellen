import 'package:flutter/material.dart';

/// Banner shown on the report screen when neither Tankerkoenig nor
/// TankSync is configured for the active country — previously the form
/// accepted input and silently failed (#484).
///
/// Hidden when the only visible report types route directly to GitHub
/// (non-DE case) — there's nothing to configure and the form still works.
class NoBackendBanner extends StatelessWidget {
  const NoBackendBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('report-no-backend-banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 20, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Les signalements ne sont pas disponibles dans ce pays '
              'pour le moment. Activez TankSync dans les paramètres '
              'pour envoyer des signalements communautaires, ou '
              'ajoutez une clé API Tankerkoenig si vous êtes en '
              'Allemagne.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
