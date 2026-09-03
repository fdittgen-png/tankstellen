// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../domain/brand_appearance.dart';
import '../domain/brand_logo_manifest.dart';
import '../providers/privacy_controls_provider.dart';
import '../theme/app_radius.dart';
import '../utils/brand_logo_mapper.dart';

/// Displays the mark for a fuel station brand or a charging network.
///
/// Four renderings, in order of preference:
///
/// 1. **The bundled logo** (#3940) — the brand's real mark, shipped
///    inside the app from [BrandLogoManifest]. Free-licensed files only
///    (public domain / CC-BY / CC-BY-SA / CC0, audited file-by-file on
///    Wikimedia Commons), so it needs no network call and is completely
///    independent of the internet-logos privacy switch. About sixty of
///    the registry's brands have one; the rest genuinely have no
///    free-licensed logo and fall through.
/// 2. **The real logo over the network** — only when the user switched
///    internet logos ON in Settings → Privacy (#3870) *and*
///    [BrandLogoMapper] resolves a domain. Disk-cached and decoded at the
///    display size (#1761). Unchanged by #3940, but now reached only for
///    brands with no bundled file.
/// 3. **The offline brand mark** (#3930) — the brand's own colour with a
///    1–3 character monogram, from [BrandAppearance]. It is also the
///    network logo's placeholder and its error widget, so a slow or dead
///    CDN degrades to the brand's colour rather than to a grey hole.
/// 4. **The neutral tile** — a surface-coloured box with a pump or a
///    charging glyph, for a brand nothing recognises. [kind] picks the
///    glyph.
class BrandLogo extends ConsumerWidget {
  /// The brand name (e.g. "Shell", "TotalEnergies", "Ionity"). Raw
  /// upstream spellings are fine — the mark canonicalises them.
  final String brand;

  /// How much WIDER than [size] a bundled logo may grow, as a multiple
  /// of it. Commons hosts wordmarks, not emblems, and several are very
  /// wide (Fastned ≈ 7.6:1, TotalEnergies ≈ 6.6:1): letterboxed into a
  /// square they collapse to an unreadable strip — worse for
  /// recognition than the monogram they replaced. A caller whose layout
  /// can absorb the extra width (the list card's Row) passes > 1 so a
  /// wordmark keeps its height and spends width instead. Callers that
  /// reserve a fixed square in their own measurements (the station
  /// detail header, which feeds `station_header_metrics`) keep 1.
  final double maxWidthFactor;

  /// The size of the mark (width and height). Defaults to 48.
  final double size;

  /// What the caller is showing: a forecourt or a charging point. Only
  /// decides the neutral fallback glyph — a brand with its own mark
  /// renders the same either way.
  final BrandKind kind;

  const BrandLogo({
    super.key,
    required this.brand,
    this.size = 48,
    this.maxWidthFactor = 1,
    this.kind = BrandKind.fuel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // #3940 — a bundled, free-licensed logo wins over everything else: it
    // is the brand's real mark, it costs no request, and it renders with
    // the privacy switch OFF (which is its default).
    final bundled = BrandLogoManifest.of(brand);
    // #3870 (Epic #3865) — internet logos (logo.clearbit.com) only when the
    // user switched them on in Settings → Privacy; the monogram otherwise.
    final remote = ref.watch(remoteBrandLogosProvider);
    final url = bundled == null && remote
        ? BrandLogoMapper.logoUrl(brand)
        : null;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // #1687 — a screen reader previously announced nothing for the
    // logo on every station card. `image: true` marks it as a
    // graphic; the label names the brand it depicts. A brandless
    // station announces what the neutral tile actually depicts
    // instead of an empty "  logo" (#3930).
    final label = brand.trim().isEmpty
        ? (kind == BrandKind.ev
              ? l10n.brandMarkEvGeneric
              : l10n.brandMarkFuelGeneric)
        : l10n.brandLogoLabel(brand);

    return Semantics(
      label: label,
      image: true,
      child: switch ((bundled, url)) {
        (final BrandLogoAsset logo, _) => _bundledLogo(logo, theme),
        (_, final String remoteUrl) => _networkLogo(context, remoteUrl, theme),
        _ => _mark(theme),
      },
    );
  }

  /// The bundled free-licensed logo (#3940), letterboxed on a white
  /// ground.
  ///
  /// White, not the surface colour: Commons hosts wordmarks drawn for
  /// print, several of them black (the bft and Morrisons marks), so a
  /// theme-coloured ground would swallow them in dark mode. The assets
  /// are already rendered at the display budget by
  /// `tool/fetch_brand_logos.dart`, so there is no decode-at-size dance
  /// to do here. A missing or corrupt asset degrades to the monogram
  /// rather than to Flutter's broken-image glyph.
  Widget _bundledLogo(BrandLogoAsset logo, ThemeData theme) {
    // Height is fixed; width follows the image's own ratio between one
    // and [maxWidthFactor] squares. With the default factor of 1 this is
    // exactly the old square. The image is unconstrained in width inside
    // those bounds, so `BoxFit.contain` fills the height rather than
    // shrinking to fit a square it never fitted.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: size,
        maxWidth: size * maxWidthFactor,
        minHeight: size,
        maxHeight: size,
      ),
      child: Container(
        padding: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: AppRadius.md,
        ),
        child: Image.asset(
          logo.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, _, _) => _mark(theme),
        ),
      ),
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
        placeholder: (context, _) => _mark(theme),
        errorWidget: (context, _, _) => _mark(theme),
      ),
    );
  }

  /// The offline mark: the brand's colour + monogram when the brand is
  /// known, the neutral tile otherwise.
  Widget _mark(ThemeData theme) {
    final appearance = BrandAppearance.of(brand);
    return appearance == null
        ? _neutralTile(theme)
        : _monogramTile(appearance);
  }

  /// Colour + monogram (#3930). The foreground is computed from the
  /// background's luminance, so every brand clears the 4.5:1 floor
  /// without a hand-maintained text colour beside each entry.
  Widget _monogramTile(BrandAppearance appearance) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: appearance.background,
        borderRadius: AppRadius.md,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size * 0.1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            appearance.monogram,
            maxLines: 1,
            style: TextStyle(
              color: appearance.foreground,
              fontSize: size * 0.44,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Nothing recognises this brand — a calm surface box with the glyph
  /// for what the caller is showing.
  Widget _neutralTile(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.md,
      ),
      child: Icon(
        kind == BrandKind.ev ? Icons.ev_station : Icons.local_gas_station,
        size: size * 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
