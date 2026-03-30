import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../error/exceptions.dart';
import '../service_result.dart';

/// Displays a banner when data comes from cache or fallback services.
class ServiceStatusBanner extends StatelessWidget {
  final ServiceResult result;

  const ServiceStatusBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.isStale && !result.hadFallbacks) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final Color backgroundColor;
    final IconData icon;
    final String message;

    if (result.isStale) {
      backgroundColor = theme.colorScheme.errorContainer;
      icon = Icons.cloud_off;
      message = 'Offline — ${result.freshnessLabel}';
    } else if (result.hadFallbacks) {
      backgroundColor = theme.colorScheme.tertiaryContainer;
      icon = Icons.info_outline;
      message = result.fallbackSummary;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Shows error when the entire service chain failed.
/// Formats errors for humans — never shows raw Dart objects.
class ServiceChainErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ServiceChainErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  /// Extract a short, user-friendly title from the error.
  String _title(AppLocalizations? l10n) {
    if (error is NoApiKeyException) {
      return l10n?.noResults ?? 'API key required';
    }
    if (error is LocationException) {
      return l10n?.noResults ?? 'Location unavailable';
    }
    return l10n?.noResults ?? 'No stations found.';
  }

  /// Extract actionable hint text from the error chain.
  String _hint(AppLocalizations? l10n) {
    // Check for common patterns in error messages
    final msg = error.toString().toLowerCase();
    if (msg.contains('no stations found') || msg.contains('keine tankstellen')) {
      return 'Try increasing the search radius or search a different location.';
    }
    if (msg.contains('api key') || error is NoApiKeyException) {
      return 'Configure your API key in Settings.';
    }
    if (msg.contains('location') || msg.contains('gps') || error is LocationException) {
      return l10n?.locationDenied ?? 'Location unavailable. Try searching by postal code or city name.';
    }
    if (msg.contains('timeout') || msg.contains('connection')) {
      return 'Check your internet connection and try again.';
    }
    if (msg.contains('route') || msg.contains('osrm') || msg.contains('routing')) {
      return 'Route calculation failed. Check your internet connection and try again.';
    }
    return 'Try again or search by postal code / city name.';
  }

  /// Extract technical details for the expandable section.
  List<String> _technicalDetails() {
    if (error is ServiceChainExhaustedException) {
      final chain = error as ServiceChainExhaustedException;
      return chain.errors.map((e) {
        if (e is ServiceError) {
          return '${e.source.displayName}: ${e.message}';
        }
        return e.toString();
      }).toList();
    }
    return [error.toString()];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _title(l10n),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _hint(l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n?.retry ?? 'Try again'),
              ),
            const SizedBox(height: 12),
            // Expandable technical details
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  'Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                children: _technicalDetails()
                    .map((d) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          child: Text(
                            d,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
