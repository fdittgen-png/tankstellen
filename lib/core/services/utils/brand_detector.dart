/// Centralized brand name detection from station names/addresses.
///
/// Replaces 3 duplicated brand detection lists across
/// Prix-Carburants, E-Control, and MITECO service implementations.
class BrandDetector {
  BrandDetector._();

  static const Map<String, String> _brands = {
    // International
    'TOTALENERGIES': 'TotalEnergies',
    'TOTAL ': 'Total',
    'SHELL': 'Shell',
    'BP ': 'BP',
    'ESSO': 'Esso',
    'AVIA': 'AVIA',

    // France
    'LECLERC': 'E.Leclerc',
    'CARREFOUR': 'Carrefour',
    'INTERMARCHE': 'Intermarché',
    'INTERMARCHÉ': 'Intermarché',
    'AUCHAN': 'Auchan',
    'SUPER U': 'Super U',
    'SYSTEME U': 'Système U',
    'SYSTÈME U': 'Système U',
    'CASINO': 'Casino',
    'VITO': 'Vito',
    'NETTO': 'Netto',
    'DYNEFF': 'Dyneff',

    // Austria
    'OMV': 'OMV',
    'JET': 'Jet',
    'ENI': 'Eni',
    'AVANTI': 'Avanti',
    'TURMÖL': 'Turmöl',
    'IQ': 'IQ',
    'GENOL': 'Genol',
    'LAGERHAUS': 'Lagerhaus',

    // Spain
    'REPSOL': 'Repsol',
    'CEPSA': 'Cepsa',
    'GALP': 'Galp',

    // Italy
    'IP': 'IP',
    'Q8': 'Q8',
    'TOTALERG': 'TotalErg',
    'TAMOIL': 'Tamoil',

    // Germany
    'ARAL': 'ARAL',
    'STAR': 'STAR',
    'HEM': 'HEM',
  };

  /// Detect brand from station name, address, or services text.
  /// Returns the brand name or [fallback] if no match.
  static String detect(String text, {String fallback = 'Station'}) {
    if (text.isEmpty) return fallback;
    final upper = text.toUpperCase();
    for (final entry in _brands.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    // Fallback: use first word
    final firstWord = text.split(RegExp(r'[\s\-]')).first;
    return firstWord.isNotEmpty ? firstWord : fallback;
  }
}
