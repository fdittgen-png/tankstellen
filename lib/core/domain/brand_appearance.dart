// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'brand_registry.dart';

/// What kind of station a brand serves — used to pick the neutral
/// fallback glyph when a brand has no appearance of its own, and to tell
/// a fuel forecourt brand apart from a charging network in the filters.
enum BrandKind {
  /// Liquid-fuel forecourts only.
  fuel,

  /// Charging networks only.
  ev,

  /// Both — supermarket chains and oil majors that run chargers as well
  /// as pumps (Circle K, Lidl, TotalEnergies …).
  both,
}

/// The offline mark for one brand: a background colour and a short
/// monogram, rendered as a rounded tile by `BrandLogo` (#3930).
///
/// ## Why colours and letters, not artwork
///
/// Until #3930 every station row showed the same grey box with a generic
/// pump glyph, because the only logo source was `logo.clearbit.com` — a
/// third party that sees the user's IP on every list, so it is OFF by
/// default (#3870, Epic #3865). A brand's *colour* is a fact about the
/// brand, not artwork: no logo file, gradient or wordmark typography is
/// copied here, so the mark ships offline, in the F-Droid build, and with
/// the privacy switch off. When the switch is on and a URL resolves, the
/// real logo still wins — this tile becomes its placeholder and its error
/// widget.
///
/// The monogram is 1–3 characters that read as the brand
/// (`TotalEnergies` → `TE`, `Système U` → `U`, `E.Leclerc` → `E.L`), and
/// the foreground is computed, never stored: [foreground] picks black or
/// white by WCAG relative luminance, which guarantees ≥ 4.5:1 against any
/// background (the worst case, a mid-luminance ground, still clears 4.58).
@immutable
class BrandAppearance {
  /// The brand's own colour, used as the tile ground.
  final Color background;

  /// 1–3 characters that read as the brand.
  final String monogram;

  /// Whether the brand runs pumps, chargers, or both.
  final BrandKind kind;

  const BrandAppearance(
    this.background,
    this.monogram, {
    this.kind = BrandKind.fuel,
  });

  /// Black or white — whichever contrasts more with [background].
  ///
  /// Both candidates are evaluated with the WCAG 2.1 contrast formula and
  /// the better one wins, so the monogram is legible on a Shell yellow
  /// ground and on an Aral blue one without a per-brand foreground field
  /// that could drift out of sync with the colour beside it.
  Color get foreground => _luminance(background) > _crossoverLuminance
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);

  /// The contrast ratio (1–21) of [foreground] against [background].
  ///
  /// Exposed so the unit test can assert the ≥ 4.5:1 floor for every
  /// entry in the table rather than trusting the crossover constant.
  double get contrastRatio {
    final a = _luminance(background);
    final b = _luminance(foreground);
    final lighter = a > b ? a : b;
    final darker = a > b ? b : a;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Luminance at which black and white contrast equally (≈ 4.58:1 each).
  static const double _crossoverLuminance = 0.1791;

  /// WCAG 2.1 relative luminance of [color].
  static double _luminance(Color color) {
    double channel(double raw) => raw <= 0.03928
        ? raw / 12.92
        : math.pow((raw + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// The appearance for [rawBrand], or `null` when the brand is unknown.
  ///
  /// The raw string is canonicalised through [BrandRegistry] first, so
  /// every alias an upstream API might send (`TOTAL ACCESS`, `Statoil`,
  /// `Star`) lands on the same mark. Brands the registry does not carry
  /// — charging networks whose names are generic substrings and would
  /// poison the registry's partial-match pass — are still resolvable by
  /// their exact name, case-insensitively.
  static BrandAppearance? of(String rawBrand) {
    final trimmed = rawBrand.trim();
    if (trimmed.isEmpty) return null;
    final canonical = BrandRegistry.canonicalize(trimmed) ?? trimmed;
    final direct = brandAppearances[canonical];
    if (direct != null) return direct;
    final lower = canonical.toLowerCase();
    for (final entry in brandAppearances.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }
}

/// Colour + monogram for every canonical [BrandRegistry] brand, plus the
/// European charging networks (#3931).
///
/// Keys are canonical registry names. The one exception is `Mer`, the
/// Nordic charging network, deliberately kept OUT of
/// `BrandRegistry.brandAliases`: `mer` is a substring of `Supermarché`
/// and the registry's partial-match pass would stamp it onto unrelated
/// French stations (the phantom-brand failure mode of #481 / #2922). It
/// resolves here by exact name instead, which is how an OpenChargeMap
/// operator title arrives anyway.
const Map<String, BrandAppearance> brandAppearances = {
  // ==========================================================================
  // International oil majors
  // ==========================================================================
  'TotalEnergies': BrandAppearance(Color(0xFFED0000), 'TE', kind: BrandKind.both),
  'Shell': BrandAppearance(Color(0xFFFBCE07), 'SH', kind: BrandKind.both),
  'BP': BrandAppearance(Color(0xFF009B3A), 'BP', kind: BrandKind.both),
  'Esso': BrandAppearance(Color(0xFF00539F), 'ES'),
  'AVIA': BrandAppearance(Color(0xFFE30613), 'AV'),
  'ENI': BrandAppearance(Color(0xFFFFE600), 'ENI'),
  'Q8': BrandAppearance(Color(0xFF00954E), 'Q8'),
  'Tamoil': BrandAppearance(Color(0xFFE30613), 'TM'),
  'Lukoil': BrandAppearance(Color(0xFFED1C24), 'LK'),
  'Gulf': BrandAppearance(Color(0xFFF57C00), 'GF'),
  'Texaco': BrandAppearance(Color(0xFFE31837), 'TX'),

  // ==========================================================================
  // France — supermarkets and chains
  // ==========================================================================
  'E.Leclerc': BrandAppearance(Color(0xFF0055A4), 'E.L'),
  'Carrefour': BrandAppearance(Color(0xFF004E9F), 'CF'),
  'Intermarché': BrandAppearance(Color(0xFFE2001A), 'IM'),
  'Auchan': BrandAppearance(Color(0xFFD1131C), 'AU'),
  'Système U': BrandAppearance(Color(0xFFE2001A), 'U'),
  'Casino': BrandAppearance(Color(0xFFD52B1E), 'CA'),
  'Netto': BrandAppearance(Color(0xFFFFE500), 'NT'),
  'Dyneff': BrandAppearance(Color(0xFF0091D2), 'DY'),
  'Vito': BrandAppearance(Color(0xFF005CA9), 'VI'),

  // ==========================================================================
  // Germany
  // ==========================================================================
  'Aral': BrandAppearance(Color(0xFF0069B4), 'AR'),
  'JET': BrandAppearance(Color(0xFFFFD500), 'JET'),
  'Orlen': BrandAppearance(Color(0xFFE30613), 'OR'),
  'HEM': BrandAppearance(Color(0xFF00539B), 'HEM'),
  'bft': BrandAppearance(Color(0xFF004A99), 'bft'),
  'Westfalen': BrandAppearance(Color(0xFF00549F), 'WF'),
  'OIL!': BrandAppearance(Color(0xFFE30613), 'OIL'),
  'Sprint': BrandAppearance(Color(0xFF0068B4), 'SP'),
  'Raiffeisen': BrandAppearance(Color(0xFFE2001A), 'RF'),

  // ==========================================================================
  // Austria
  // ==========================================================================
  'OMV': BrandAppearance(Color(0xFF003C7D), 'OMV'),
  'Turmöl': BrandAppearance(Color(0xFFE2001A), 'TÖ'),
  'IQ': BrandAppearance(Color(0xFF00A0E1), 'IQ'),

  // ==========================================================================
  // Spain
  // ==========================================================================
  'Repsol': BrandAppearance(Color(0xFFF7941E), 'RE'),
  'Cepsa': BrandAppearance(Color(0xFFD6001C), 'CE'),
  'Galp': BrandAppearance(Color(0xFFFF6600), 'GA'),
  'Disa': BrandAppearance(Color(0xFF00913F), 'DI'),
  'Ballenoil': BrandAppearance(Color(0xFFFFCC00), 'BL'),
  'Plenoil': BrandAppearance(Color(0xFF0091D0), 'PL'),
  'Meroil': BrandAppearance(Color(0xFF004B93), 'MR'),
  'Bonarea': BrandAppearance(Color(0xFF008B45), 'BA'),

  // ==========================================================================
  // Italy
  // ==========================================================================
  'IP': BrandAppearance(Color(0xFF0057A6), 'IP'),

  // ==========================================================================
  // Denmark / Nordics
  // ==========================================================================
  'OK': BrandAppearance(Color(0xFFD52B1E), 'OK'),
  'Circle K': BrandAppearance(Color(0xFFED1B2E), 'CK', kind: BrandKind.both),
  'Uno-X': BrandAppearance(Color(0xFFE4002B), 'UX'),
  'F24': BrandAppearance(Color(0xFF00509E), 'F24'),
  'Go\'On': BrandAppearance(Color(0xFF009640), 'GO'),

  // ==========================================================================
  // Portugal
  // ==========================================================================
  'Prio': BrandAppearance(Color(0xFF76B82A), 'PR'),

  // ==========================================================================
  // United Kingdom
  // ==========================================================================
  'Tesco': BrandAppearance(Color(0xFF00539F), 'TS'),
  'Sainsbury\'s': BrandAppearance(Color(0xFFF06C00), 'SB'),
  'Asda': BrandAppearance(Color(0xFF68A51C), 'AS'),
  'Morrisons': BrandAppearance(Color(0xFF00703C), 'MO'),

  // ==========================================================================
  // Australia
  // ==========================================================================
  'Ampol': BrandAppearance(Color(0xFF005EB8), 'AM'),
  '7-Eleven': BrandAppearance(Color(0xFFF37021), '7E'),
  'United': BrandAppearance(Color(0xFF003DA5), 'UN'),
  'Puma Energy': BrandAppearance(Color(0xFF002F87), 'PU'),
  'Liberty': BrandAppearance(Color(0xFF00447C), 'LB'),
  'Metro Petroleum': BrandAppearance(Color(0xFF00A651), 'MP'),

  // ==========================================================================
  // Mexico
  // ==========================================================================
  'Pemex': BrandAppearance(Color(0xFF006341), 'PX'),
  'Oxxo Gas': BrandAppearance(Color(0xFFE31937), 'OX'),
  'G500': BrandAppearance(Color(0xFF0072BC), 'G5'),
  'Hidrosina': BrandAppearance(Color(0xFF00953B), 'HI'),
  'Chevron': BrandAppearance(Color(0xFF0054A4), 'CH'),
  'Arco': BrandAppearance(Color(0xFF005CB9), 'ARC'),
  'Valero': BrandAppearance(Color(0xFF007A33), 'VL'),
  'Mobil': BrandAppearance(Color(0xFF0033A0), 'MB'),
  'Petro-7': BrandAppearance(Color(0xFFE31937), 'P7'),

  // ==========================================================================
  // Argentina
  // ==========================================================================
  'YPF': BrandAppearance(Color(0xFF0072CE), 'YPF'),
  'Axion Energy': BrandAppearance(Color(0xFF002B5C), 'AX'),
  'Dapsa': BrandAppearance(Color(0xFF00529B), 'DP'),
  'Refinor': BrandAppearance(Color(0xFF0F4C81), 'RN'),

  // ==========================================================================
  // Belgium / Luxembourg
  // ==========================================================================
  'Maes': BrandAppearance(Color(0xFFE2001A), 'MA'),
  'DATS 24': BrandAppearance(Color(0xFF0090D7), 'D24'),
  'Octa+': BrandAppearance(Color(0xFFEE7F00), 'O+'),
  'Power': BrandAppearance(Color(0xFFE30613), 'PW'),
  'Goedert': BrandAppearance(Color(0xFF004B93), 'GD'),

  // ==========================================================================
  // European charging networks (#3931)
  // ==========================================================================
  'Ionity': BrandAppearance(Color(0xFF00A499), 'IO', kind: BrandKind.ev),
  'Fastned': BrandAppearance(Color(0xFFFFD500), 'FN', kind: BrandKind.ev),
  'Allego': BrandAppearance(Color(0xFF00A0AF), 'AL', kind: BrandKind.ev),
  'EnBW': BrandAppearance(Color(0xFF0A4A7A), 'EB', kind: BrandKind.ev),
  'Electra': BrandAppearance(Color(0xFF00B37A), 'EL', kind: BrandKind.ev),
  'Izivia': BrandAppearance(Color(0xFF009FE3), 'IZ', kind: BrandKind.ev),
  'Freshmile': BrandAppearance(Color(0xFF5CB85C), 'FM', kind: BrandKind.ev),
  'Driveco': BrandAppearance(Color(0xFF00A651), 'DC', kind: BrandKind.ev),
  'Bump': BrandAppearance(Color(0xFF16C784), 'BU', kind: BrandKind.ev),
  'Engie Vianeo': BrandAppearance(Color(0xFF009FE3), 'VN', kind: BrandKind.ev),
  'Powerdot': BrandAppearance(Color(0xFF00A86B), 'PD', kind: BrandKind.ev),
  'Zunder': BrandAppearance(Color(0xFF0057FF), 'ZU', kind: BrandKind.ev),
  'Atlante': BrandAppearance(Color(0xFF0091D5), 'AT', kind: BrandKind.ev),
  'Be Charge': BrandAppearance(Color(0xFF76BC21), 'BC', kind: BrandKind.ev),
  'Enel X Way': BrandAppearance(Color(0xFF00A3E0), 'EX', kind: BrandKind.ev),
  'Vattenfall InCharge':
      BrandAppearance(Color(0xFFFFDA00), 'IC', kind: BrandKind.ev),
  'Tesla': BrandAppearance(Color(0xFFCC0000), 'TS', kind: BrandKind.ev),
  'Shell Recharge':
      BrandAppearance(Color(0xFFFBCE07), 'SR', kind: BrandKind.ev),
  'TotalEnergies Charge':
      BrandAppearance(Color(0xFFED0000), 'TC', kind: BrandKind.ev),
  'E.ON Drive': BrandAppearance(Color(0xFFE3000F), 'EON', kind: BrandKind.ev),
  'Lidl': BrandAppearance(Color(0xFF0050AA), 'LD', kind: BrandKind.both),
  'Aldi': BrandAppearance(Color(0xFF001E5A), 'AD', kind: BrandKind.both),
  'Kaufland': BrandAppearance(Color(0xFFE10915), 'KL', kind: BrandKind.both),

  // Registry-less networks — see the doc comment above: their names are
  // common substrings, so they stay out of `brandAliases` and resolve
  // here by exact operator title only.
  'Mer': BrandAppearance(Color(0xFF00B08B), 'ME', kind: BrandKind.ev),
};
