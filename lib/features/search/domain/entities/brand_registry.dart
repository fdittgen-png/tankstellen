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
    // International
    'TotalEnergies': ['TotalEnergies', 'Total', 'Total Access', 'TOTALENERGIES', 'TOTAL'],
    'Shell': ['Shell', 'SHELL'],
    'BP': ['BP', 'bp'],
    'Esso': ['Esso', 'ESSO'],
    'AVIA': ['AVIA', 'Avia'],
    'ENI': ['ENI', 'Eni', 'Agip', 'AGIP'],

    // France — supermarkets
    'E.Leclerc': ['E.Leclerc', 'Leclerc', 'LECLERC', 'E. LECLERC'],
    'Carrefour': ['Carrefour', 'CARREFOUR', 'Carrefour Market', 'Carrefour Contact'],
    'Intermarché': ['Intermarché', 'INTERMARCHE', 'Intermarche', 'ITM'],
    'Auchan': ['Auchan', 'AUCHAN'],
    'Système U': ['Système U', 'Super U', 'SYSTEME U', 'SUPER U', 'U Express', 'Hyper U'],
    'Casino': ['Casino', 'CASINO', 'Géant Casino'],
    'Netto': ['Netto', 'NETTO'],

    // Germany
    'Aral': ['Aral', 'ARAL'],
    'JET': ['JET', 'Jet'],
    'STAR': ['STAR', 'Star', 'star'],
    'HEM': ['HEM', 'Hem'],

    // Austria
    'OMV': ['OMV'],
    'Avanti': ['Avanti', 'AVANTI'],

    // Spain
    'Repsol': ['Repsol', 'REPSOL'],
    'Cepsa': ['Cepsa', 'CEPSA'],
    'Galp': ['Galp', 'GALP'],

    // Italy
    'IP': ['IP'],
    'Q8': ['Q8'],
    'Tamoil': ['Tamoil', 'TAMOIL'],

    // Belgium/Luxembourg
    'Lukoil': ['Lukoil', 'LUKOIL'],

    // France — other chains
    'Dyneff': ['Dyneff', 'DYNEFF'],
    'Vito': ['Vito', 'VITO'],
  };

  /// The "Others" label for independent/unrecognized brands.
  static const othersLabel = 'Others';

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
