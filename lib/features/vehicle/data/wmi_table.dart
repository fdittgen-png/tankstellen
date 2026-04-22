/// Offline WMI (World Manufacturer Identifier) lookup table.
///
/// The first 3 characters of a VIN encode the manufacturer and, in most
/// countries, the country of origin. This table is the offline fallback
/// for [VinDecoder] when NHTSA vPIC is unreachable — it can still tell
/// the user "Your car is a Peugeot from France" even with no network.
///
/// Reference subset derived from the public Wal33D/nhtsa-vin-decoder
/// dataset (MIT-licensed). Covers the ~50 brands most likely to appear
/// in the European + North-American + East-Asian markets — enough for
/// the onboarding UI's confirm-make prompt to hit > 95% of real users.
library;

/// One entry in the offline WMI table.
class WmiEntry {
  /// Country of manufacture (human-readable, e.g. "France", "Germany").
  /// The onboarding UI shows this verbatim, so stay with full names
  /// rather than ISO codes.
  final String country;

  /// Brand name, Title Case (e.g. "Peugeot", "BMW"). Matches the label
  /// the user would see on the badge of the car.
  final String brand;

  const WmiEntry({required this.country, required this.brand});
}

/// Lookup a VIN by its first-3-character WMI prefix. Returns `null`
/// when the prefix is unknown or the input is too short — callers
/// should treat both as "decoder could not identify the make".
WmiEntry? lookup(String vin) {
  if (vin.length < 3) return null;
  final key = vin.substring(0, 3).toUpperCase();
  return wmiTable[key];
}

/// The curated WMI prefix → manufacturer table. Keys are the upper-
/// case first-3 VIN characters (ISO 3779 / SAE J272 WMI).
///
/// Where a brand uses several plant-specific WMIs that share the same
/// first-3 prefix, we list the common ones. Where plants are in
/// different countries, each country gets its own entry.
const Map<String, WmiEntry> wmiTable = {
  // === PSA group (Peugeot / Citroën / DS / Opel) ===
  'VF3': WmiEntry(country: 'France', brand: 'Peugeot'),
  'VR3': WmiEntry(country: 'France', brand: 'Peugeot'),
  'VF7': WmiEntry(country: 'France', brand: 'Citroen'),
  'VR1': WmiEntry(country: 'France', brand: 'Citroen'),
  'W0L': WmiEntry(country: 'Germany', brand: 'Opel'),
  'W0V': WmiEntry(country: 'Germany', brand: 'Opel'),

  // === Renault / Dacia ===
  'VF1': WmiEntry(country: 'France', brand: 'Renault'),
  'VF6': WmiEntry(country: 'France', brand: 'Renault'),
  'VF8': WmiEntry(country: 'Romania', brand: 'Dacia'),
  'UU1': WmiEntry(country: 'Romania', brand: 'Dacia'),

  // === Volkswagen Group ===
  'WVW': WmiEntry(country: 'Germany', brand: 'Volkswagen'),
  'WV1': WmiEntry(country: 'Germany', brand: 'Volkswagen'),
  'WV2': WmiEntry(country: 'Germany', brand: 'Volkswagen'),
  'WAU': WmiEntry(country: 'Germany', brand: 'Audi'),
  'TMB': WmiEntry(country: 'Czech Republic', brand: 'Skoda'),
  'VSS': WmiEntry(country: 'Spain', brand: 'SEAT'),
  'WP0': WmiEntry(country: 'Germany', brand: 'Porsche'),
  'WP1': WmiEntry(country: 'Germany', brand: 'Porsche'),

  // === BMW / Mini ===
  'WBA': WmiEntry(country: 'Germany', brand: 'BMW'),
  'WBS': WmiEntry(country: 'Germany', brand: 'BMW M'),
  'WBY': WmiEntry(country: 'Germany', brand: 'BMW i'),
  'WMW': WmiEntry(country: 'Germany', brand: 'MINI'),

  // === Mercedes-Benz / Smart ===
  'WDB': WmiEntry(country: 'Germany', brand: 'Mercedes-Benz'),
  'WDC': WmiEntry(country: 'Germany', brand: 'Mercedes-Benz'),
  'WDD': WmiEntry(country: 'Germany', brand: 'Mercedes-Benz'),
  'W1K': WmiEntry(country: 'Germany', brand: 'Mercedes-Benz'),
  'WME': WmiEntry(country: 'Germany', brand: 'Smart'),

  // === Ford (Germany + USA) ===
  'WF0': WmiEntry(country: 'Germany', brand: 'Ford'),
  '1FA': WmiEntry(country: 'United States', brand: 'Ford'),
  '1FB': WmiEntry(country: 'United States', brand: 'Ford'),
  '1FC': WmiEntry(country: 'United States', brand: 'Ford'),
  '1FD': WmiEntry(country: 'United States', brand: 'Ford'),
  '1FM': WmiEntry(country: 'United States', brand: 'Ford'),
  '1FT': WmiEntry(country: 'United States', brand: 'Ford'),

  // === GM (USA) ===
  '1GC': WmiEntry(country: 'United States', brand: 'Chevrolet'),
  '1G1': WmiEntry(country: 'United States', brand: 'Chevrolet'),
  '1GT': WmiEntry(country: 'United States', brand: 'GMC'),
  '1GB': WmiEntry(country: 'United States', brand: 'Chevrolet'),

  // === Chrysler / Jeep / RAM ===
  '1C4': WmiEntry(country: 'United States', brand: 'Chrysler'),
  '1J4': WmiEntry(country: 'United States', brand: 'Jeep'),
  '1J8': WmiEntry(country: 'United States', brand: 'Jeep'),

  // === Tesla ===
  '5YJ': WmiEntry(country: 'United States', brand: 'Tesla'),
  '7SA': WmiEntry(country: 'United States', brand: 'Tesla'),
  'XP7': WmiEntry(country: 'Germany', brand: 'Tesla'),
  'LRW': WmiEntry(country: 'China', brand: 'Tesla'),

  // === Toyota / Lexus ===
  'JTD': WmiEntry(country: 'Japan', brand: 'Toyota'),
  'JTE': WmiEntry(country: 'Japan', brand: 'Toyota'),
  'JTN': WmiEntry(country: 'Japan', brand: 'Toyota'),
  'JTH': WmiEntry(country: 'Japan', brand: 'Lexus'),
  'JTJ': WmiEntry(country: 'Japan', brand: 'Lexus'),
  'VNK': WmiEntry(country: 'France', brand: 'Toyota'),

  // === Honda / Acura ===
  'JHM': WmiEntry(country: 'Japan', brand: 'Honda'),
  'JHG': WmiEntry(country: 'Japan', brand: 'Honda'),
  'JH4': WmiEntry(country: 'Japan', brand: 'Acura'),

  // === Nissan / Infiniti ===
  'JN1': WmiEntry(country: 'Japan', brand: 'Nissan'),
  'JN6': WmiEntry(country: 'Japan', brand: 'Nissan'),
  'JN8': WmiEntry(country: 'Japan', brand: 'Nissan'),
  'JNK': WmiEntry(country: 'Japan', brand: 'Infiniti'),

  // === Mazda ===
  'JM1': WmiEntry(country: 'Japan', brand: 'Mazda'),
  'JM3': WmiEntry(country: 'Japan', brand: 'Mazda'),
  'JMZ': WmiEntry(country: 'Japan', brand: 'Mazda'),

  // === Subaru ===
  'JF1': WmiEntry(country: 'Japan', brand: 'Subaru'),
  'JF2': WmiEntry(country: 'Japan', brand: 'Subaru'),

  // === Mitsubishi ===
  'JA3': WmiEntry(country: 'Japan', brand: 'Mitsubishi'),
  'JA4': WmiEntry(country: 'Japan', brand: 'Mitsubishi'),

  // === Fiat / Alfa Romeo / Ferrari / Lamborghini / Maserati ===
  'ZFA': WmiEntry(country: 'Italy', brand: 'Fiat'),
  'ZAR': WmiEntry(country: 'Italy', brand: 'Alfa Romeo'),
  'ZFF': WmiEntry(country: 'Italy', brand: 'Ferrari'),
  'ZHW': WmiEntry(country: 'Italy', brand: 'Lamborghini'),
  'ZAM': WmiEntry(country: 'Italy', brand: 'Maserati'),

  // === Volvo / Saab ===
  'YV1': WmiEntry(country: 'Sweden', brand: 'Volvo'),
  'YV4': WmiEntry(country: 'Sweden', brand: 'Volvo'),
  'YS3': WmiEntry(country: 'Sweden', brand: 'Saab'),

  // === Hyundai / Kia ===
  'KMH': WmiEntry(country: 'South Korea', brand: 'Hyundai'),
  'KM8': WmiEntry(country: 'South Korea', brand: 'Hyundai'),
  'KNA': WmiEntry(country: 'South Korea', brand: 'Kia'),
  'KNB': WmiEntry(country: 'South Korea', brand: 'Kia'),
  'KND': WmiEntry(country: 'South Korea', brand: 'Kia'),

  // === Land Rover / Jaguar ===
  'SAL': WmiEntry(country: 'United Kingdom', brand: 'Land Rover'),
  'SAJ': WmiEntry(country: 'United Kingdom', brand: 'Jaguar'),
};
