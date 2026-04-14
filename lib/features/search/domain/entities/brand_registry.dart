/// Registry of major fuel station brands across all supported countries.
///
/// Brands not in this list are grouped under "Others" in the brand filter.
/// This enables loyalty card filtering — e.g. show only Total stations
/// because the user has a Total card.
class BrandRegistry {
  BrandRegistry._();

  /// Major brands grouped by parent company / network.
  /// Keys are canonical brand names used in the filter UI.
  /// Values are all known variations/aliases from API data.
  static const Map<String, List<String>> brandAliases = {
    // =========================================================================
    // International brands (present in multiple countries)
    // =========================================================================
    'TotalEnergies': ['TotalEnergies', 'Total', 'Total Access', 'TotalErg',
        'TOTALENERGIES', 'TOTAL', 'TOTAL ACCESS'],
    'Shell': ['Shell', 'SHELL', 'Viva Energy'],
    'BP': ['BP', 'bp'],
    'Esso': ['Esso', 'ESSO', 'Esso Express', 'ESSO EXPRESS'],
    'AVIA': ['AVIA', 'Avia'],
    'ENI': ['ENI', 'Eni', 'Agip', 'AGIP'],
    'Q8': ['Q8', 'q8'],
    'Tamoil': ['Tamoil', 'TAMOIL'],
    'Lukoil': ['Lukoil', 'LUKOIL'],
    'Gulf': ['Gulf', 'GULF'],
    'Texaco': ['Texaco', 'TEXACO'],

    // =========================================================================
    // France 🇫🇷 — supermarkets (61% of fuel volume)
    // =========================================================================
    'E.Leclerc': ['E.Leclerc', 'Leclerc', 'LECLERC', 'E. LECLERC'],
    'Carrefour': ['Carrefour', 'CARREFOUR', 'Carrefour Market',
        'Carrefour Contact', 'CARREFOUR MARKET', 'CARREFOUR CONTACT'],
    'Intermarché': ['Intermarché', 'INTERMARCHE', 'Intermarche', 'ITM'],
    'Auchan': ['Auchan', 'AUCHAN'],
    'Système U': ['Système U', 'Super U', 'SYSTEME U', 'SUPER U',
        'U Express', 'Hyper U', 'U EXPRESS', 'HYPER U'],
    'Casino': ['Casino', 'CASINO', 'Géant Casino', 'GEANT CASINO'],
    'Netto': ['Netto', 'NETTO'],

    // France — other chains
    'Dyneff': ['Dyneff', 'DYNEFF'],
    'Vito': ['Vito', 'VITO'],

    // =========================================================================
    // Germany 🇩🇪
    // =========================================================================
    'Aral': ['Aral', 'ARAL'],
    'JET': ['JET', 'Jet'],
    'Orlen': ['Orlen', 'ORLEN', 'Star', 'STAR', 'star'], // Star rebranded to Orlen
    'HEM': ['HEM', 'Hem'],
    'bft': ['bft', 'BFT'],
    'Westfalen': ['Westfalen', 'WESTFALEN'],
    'OIL!': ['OIL!', 'OIL'],
    'Sprint': ['Sprint', 'SPRINT'],
    'Raiffeisen': ['Raiffeisen', 'RAIFFEISEN'],

    // =========================================================================
    // Austria 🇦🇹
    // =========================================================================
    'OMV': ['OMV', 'Avanti', 'AVANTI'], // Avanti = OMV discount sub-brand
    'Turmöl': ['Turmöl', 'Turmoel', 'TURMÖL', 'TURMOEL'],
    'IQ': ['IQ'],

    // =========================================================================
    // Spain 🇪🇸
    // =========================================================================
    'Repsol': ['Repsol', 'REPSOL'],
    'Cepsa': ['Cepsa', 'CEPSA', 'Moeve', 'MOEVE'], // Moeve = Cepsa rebrand in Portugal
    'Galp': ['Galp', 'GALP'],
    'Disa': ['Disa', 'DISA'],
    'Ballenoil': ['Ballenoil', 'BALLENOIL'],
    'Plenoil': ['Plenoil', 'PLENOIL'],
    'Meroil': ['Meroil', 'MEROIL'],
    'Bonarea': ['Bonarea', 'BONAREA'],

    // =========================================================================
    // Italy 🇮🇹
    // =========================================================================
    'IP': ['IP', 'API', 'API-IP'],

    // =========================================================================
    // Denmark 🇩🇰
    // =========================================================================
    'OK': ['OK', 'ok'],
    'Circle K': ['Circle K', 'CIRCLE K', 'Statoil', 'Ingo', 'INGO'], // Ingo = Circle K discount
    'Uno-X': ['Uno-X', 'UNO-X', 'Uno X'],
    'F24': ['F24'],
    'Go\'On': ['GoOn', 'Go On', 'GOON'],

    // =========================================================================
    // Portugal 🇵🇹
    // =========================================================================
    'Prio': ['Prio', 'PRIO'],

    // =========================================================================
    // United Kingdom 🇬🇧 — supermarkets dominate by volume
    // =========================================================================
    'Tesco': ['Tesco', 'TESCO'],
    'Sainsbury\'s': ['Sainsbury\'s', 'SAINSBURYS', 'Sainsburys'],
    'Asda': ['Asda', 'ASDA'],
    'Morrisons': ['Morrisons', 'MORRISONS'],

    // =========================================================================
    // Australia 🇦🇺
    // =========================================================================
    'Ampol': ['Ampol', 'AMPOL', 'Caltex', 'CALTEX'], // Caltex rebranded to Ampol
    '7-Eleven': ['7-Eleven', '7-ELEVEN', '7 Eleven'],
    'United': ['United', 'UNITED'],
    'Puma Energy': ['Puma', 'PUMA', 'Puma Energy', 'PUMA ENERGY'],
    'Liberty': ['Liberty', 'LIBERTY'],
    'Metro Petroleum': ['Metro', 'Metro Petroleum', 'METRO'],

    // =========================================================================
    // Mexico 🇲🇽
    // =========================================================================
    'Pemex': ['Pemex', 'PEMEX'],
    'Oxxo Gas': ['Oxxo Gas', 'OXXO GAS', 'OxxoGas'],
    'G500': ['G500', 'G Quinientos'],
    'Hidrosina': ['Hidrosina', 'HIDROSINA'],
    'Chevron': ['Chevron', 'CHEVRON'],
    'Arco': ['Arco', 'ARCO'],
    'Valero': ['Valero', 'VALERO'],
    'Mobil': ['Mobil', 'MOBIL'],
    'Petro-7': ['Petro-7', 'PETRO-7', 'Petro7'],

    // =========================================================================
    // Argentina 🇦🇷 — top 4 = 96% of sales
    // =========================================================================
    'YPF': ['YPF'],
    'Axion Energy': ['Axion', 'AXION', 'Axion Energy'],
    'Dapsa': ['Dapsa', 'DAPSA'],
    'Refinor': ['Refinor', 'REFINOR'],

    // =========================================================================
    // Belgium 🇧🇪 & Luxembourg 🇱🇺
    // =========================================================================
    'Maes': ['Maes', 'MAES'],
    'DATS 24': ['DATS 24', 'DATS24', 'Dats 24'],
    'Octa+': ['Octa+', 'OCTA+', 'Octaplus'],
    'Power': ['Power', 'POWER', 'Gabriels'],
    'Goedert': ['Goedert', 'GOEDERT'],
  };

  /// The "Others" label for independent/unrecognized brands.
  static const othersLabel = 'Others';

  /// Sentinel brand used by country parsers when the upstream API has no
  /// brand field at all (Prix Carburants, and similar) and the heuristic
  /// address/services detector cannot find a recognisable brand keyword.
  ///
  /// Detail views should render this as a localised "Station indépendante"
  /// row (French) / "Independent station" (English) so the user can tell
  /// the difference between a genuinely brandless station and a missing
  /// data bug (#482). Filter chips still bucket this into [othersLabel]
  /// via [canonicalize] — the sentinel is purely a display signal.
  static const independentLabel = 'Independent';

  /// All canonical brand names (sorted).
  static List<String> get allBrands {
    final brands = brandAliases.keys.toList()..sort();
    return brands;
  }

  /// Map a raw brand string from API data to its canonical name.
  /// Returns null if the brand is not recognized (→ "Others").
  static String? canonicalize(String rawBrand) {
    final trimmed = rawBrand.trim();
    if (trimmed.isEmpty) return null;

    for (final entry in brandAliases.entries) {
      for (final alias in entry.value) {
        if (trimmed.toLowerCase() == alias.toLowerCase()) {
          return entry.key;
        }
      }
    }

    // Partial match — brand name contains the canonical name
    final lower = trimmed.toLowerCase();
    for (final entry in brandAliases.entries) {
      for (final alias in entry.value) {
        if (lower.contains(alias.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return null; // Unknown → "Others"
  }

  /// Group stations by canonical brand. Unrecognized brands go to "Others".
  static Map<String, int> countByBrand(List<String> rawBrands) {
    final counts = <String, int>{};
    for (final raw in rawBrands) {
      final canonical = canonicalize(raw) ?? othersLabel;
      counts[canonical] = (counts[canonical] ?? 0) + 1;
    }
    return counts;
  }
}
