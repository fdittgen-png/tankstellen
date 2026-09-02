// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Maps fuel station and charging network brand names to their logo
/// image URLs.
///
/// Uses favicon/logo services that don't require API keys.
/// Falls back to `null` for unknown brands, so the UI can show the
/// offline colour + monogram mark (`BrandAppearance`, #3930) instead.
/// Nothing here is reached unless the user switched internet logos ON in
/// Settings → Privacy (#3870) — the marks are the default.
class BrandLogoMapper {
  BrandLogoMapper._();

  /// Brand name (normalized lowercase) → domain for logo lookup.
  ///
  /// Only brands with a known, stable website domain are listed.
  /// The domain is used with logo.clearbit.com (free, no API key).
  static const Map<String, String> _brandDomains = {
    // International
    'totalenergies': 'totalenergies.com',
    'total': 'totalenergies.com',
    'shell': 'shell.com',
    'bp': 'bp.com',
    'esso': 'esso.com',
    'avia': 'avia-international.com',
    'eni': 'eni.com',
    'agip': 'eni.com',
    'q8': 'q8.com',
    'tamoil': 'tamoil.com',

    // France
    'e.leclerc': 'e.leclerc',
    'leclerc': 'e.leclerc',
    'carrefour': 'carrefour.fr',
    'intermarché': 'intermarche.com',
    'intermarche': 'intermarche.com',
    'auchan': 'auchan.fr',
    'super u': 'magasins-u.com',
    'système u': 'magasins-u.com',
    'systeme u': 'magasins-u.com',
    'casino': 'groupe-casino.fr',
    'netto': 'netto.fr',
    'dyneff': 'dyneff.fr',

    // Germany
    'aral': 'aral.de',
    'star': 'star.de',
    'hem': 'hem-tankstelle.de',
    'jet': 'jet-tankstellen.de',

    // Austria
    'omv': 'omv.com',
    'avanti': 'avanti.at',

    // Spain
    'repsol': 'repsol.com',
    'cepsa': 'cepsa.com',
    'galp': 'galp.com',

    // Italy
    'ip': 'gruppoapi.com',
    'totalerg': 'totalenergies.com',

    // Belgium / Luxembourg
    'lukoil': 'lukoil.com',
    'dats 24': 'dats24.be',

    // International — remaining majors (#3931)
    'texaco': 'texaco.com',
    'chevron': 'chevron.com',
    'mobil': 'mobil.com',
    'valero': 'valero.com',
    'arco': 'arco.com',

    // Germany / Austria — remaining chains (#3931)
    'orlen': 'orlen.pl',
    'bft': 'bft.de',
    'westfalen': 'westfalen.com',
    'oil!': 'oil-tankstellen.de',
    'turmöl': 'turmoel.at',
    'turmoel': 'turmoel.at',

    // Spain / Portugal (#3931)
    'ballenoil': 'ballenoil.es',
    'prio': 'prio.pt',

    // Denmark (#3931)
    'ok': 'ok.dk',
    'circle k': 'circlek.com',

    // United Kingdom (#3931)
    'tesco': 'tesco.com',
    'sainsbury\'s': 'sainsburys.co.uk',
    'sainsburys': 'sainsburys.co.uk',
    'asda': 'asda.com',
    'morrisons': 'morrisons.com',

    // Australia (#3931)
    'ampol': 'ampol.com.au',
    '7-eleven': '7eleven.com.au',
    'united': 'unitedpetroleum.com.au',
    'puma energy': 'pumaenergy.com',

    // Americas (#3931)
    'pemex': 'pemex.com',
    'ypf': 'ypf.com',
    'axion energy': 'axionenergy.com',

    // ==========================================================================
    // European EV charging networks (#3931)
    // ==========================================================================
    'ionity': 'ionity.eu',
    'fastned': 'fastned.nl',
    'allego': 'allego.eu',
    'enbw': 'enbw.com',
    'izivia': 'izivia.com',
    'freshmile': 'freshmile.com',
    'driveco': 'driveco.com',
    'tesla': 'tesla.com',
    'shell recharge': 'shell.com',
    'totalenergies charge': 'totalenergies.com',
    'e.on drive': 'eon.com',
    'vattenfall incharge': 'vattenfall.com',
    'lidl': 'lidl.com',
    'kaufland': 'kaufland.com',
  };

  /// The set of brand keys this mapper owns a logo domain for.
  ///
  /// Exposed (#2186) so a guard test can assert every key is a known
  /// `BrandRegistry` canonical name or alias — preventing the logo map
  /// and the brand registry from drifting apart (e.g. listing `star`
  /// here after Star was folded into Orlen in the registry). Behaviour
  /// is unchanged: [logoUrl] still keys off the raw lowercased brand.
  static Iterable<String> get knownBrandKeys => _brandDomains.keys;

  /// Returns a logo URL for the given [brand], or `null` if unknown.
  ///
  /// Uses Clearbit Logo API (free, no key required, returns 128px PNG).
  /// Example: `https://logo.clearbit.com/shell.com?size=128`
  static String? logoUrl(String brand) {
    if (brand.isEmpty) return null;
    final normalized = brand.toLowerCase().trim();
    final domain = _brandDomains[normalized];
    if (domain == null) return null;
    return 'https://logo.clearbit.com/$domain?size=128';
  }

  /// Whether a logo is available for the given [brand].
  static bool hasLogo(String brand) => logoUrl(brand) != null;
}
