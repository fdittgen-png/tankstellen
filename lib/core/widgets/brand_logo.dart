import 'package:flutter/material.dart';

import '../utils/brand_logo_mapper.dart';

/// Displays a brand logo for a fuel station, with automatic fallback
/// to a generic fuel pump icon when no logo is available or loading fails.
///
/// Uses [BrandLogoMapper] to resolve brand names to logo URLs.
class BrandLogo extends StatelessWidget {
  /// The brand name (e.g. "Shell", "TotalEnergies", "ARAL").
  final String brand;

  /// The size of the logo (width and height). Defaults to 48.
  final double size;

  const BrandLogo({
    super.key,
    required this.brand,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final url = BrandLogoMapper.logoUrl(brand);
    final theme = Theme.of(context);

    if (url == null) {
      return _fallbackIcon(theme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(theme),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.local_gas_station,
        size: size * 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
