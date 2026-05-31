// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../utils/brand_logo_mapper.dart';

/// Displays a brand logo for a fuel station, with automatic fallback
/// to a generic fuel pump icon when no logo is available or loading fails.
///
/// Uses [BrandLogoMapper] to resolve brand names to logo URLs. Logos are
/// disk-cached and decoded at the display size (#1761): a logo is
/// fetched and decoded once, then reused from disk across scroll-away
/// and app restarts instead of re-downloading.
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
    final l10n = AppLocalizations.of(context);

    // #1687 — a screen reader previously announced nothing for the
    // logo on every station card. `image: true` marks it as a
    // graphic; the label names the brand it depicts.
    return Semantics(
      label: l10n?.brandLogoLabel(brand) ?? '$brand logo',
      image: true,
      child: url == null
          ? _fallbackIcon(theme)
          : _networkLogo(context, url, theme),
    );
  }

  Widget _networkLogo(BuildContext context, String url, ThemeData theme) {
    // Decode at the display target size — brand logos are routinely
    // shipped far larger than the 48dp slot, so decoding at full
    // resolution wasted memory on every card (#1761).
    final cachePx = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: AppRadius.md,
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        memCacheWidth: cachePx,
        memCacheHeight: cachePx,
        placeholder: (context, _) => _placeholder(theme),
        errorWidget: (context, _, _) => _fallbackIcon(theme),
      ),
    );
  }

  /// Calm static placeholder shown while the logo loads — a soft
  /// surface-coloured box. A spinner is overkill for a 48dp slot and
  /// would animate indefinitely.
  Widget _placeholder(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.md,
      ),
    );
  }

  Widget _fallbackIcon(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.md,
      ),
      child: Icon(
        Icons.local_gas_station,
        size: size * 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
