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

  // === #1627 — broad fleet coverage expansion ===
  '19X': WmiEntry(country: 'United States', brand: 'Honda'),
  '1C3': WmiEntry(country: 'United States', brand: 'Chrysler'),
  '1C6': WmiEntry(country: 'United States', brand: 'Ram'),
  '1HG': WmiEntry(country: 'United States', brand: 'Honda'),
  '1VW': WmiEntry(country: 'United States', brand: 'Volkswagen'),
  '2C3': WmiEntry(country: 'Canada', brand: 'Chrysler'),
  '2FA': WmiEntry(country: 'Canada', brand: 'Ford'),
  '2FM': WmiEntry(country: 'Canada', brand: 'Ford'),
  '2FT': WmiEntry(country: 'Canada', brand: 'Ford'),
  '2HG': WmiEntry(country: 'Canada', brand: 'Honda'),
  '2T1': WmiEntry(country: 'Canada', brand: 'Toyota'),
  '2T2': WmiEntry(country: 'Canada', brand: 'Lexus'),
  '3C4': WmiEntry(country: 'Mexico', brand: 'Fiat'),
  '3C6': WmiEntry(country: 'Mexico', brand: 'Ram'),
  '3C8': WmiEntry(country: 'Mexico', brand: 'Jeep'),
  '3FA': WmiEntry(country: 'Mexico', brand: 'Ford'),
  '3FE': WmiEntry(country: 'Mexico', brand: 'Ford'),
  '3KP': WmiEntry(country: 'Mexico', brand: 'Kia'),
  '3MZ': WmiEntry(country: 'Mexico', brand: 'Mazda'),
  '3N1': WmiEntry(country: 'Mexico', brand: 'Nissan'),
  '3VW': WmiEntry(country: 'Mexico', brand: 'Volkswagen'),
  '4JG': WmiEntry(country: 'United States', brand: 'Mercedes-Benz'),
  '4S3': WmiEntry(country: 'United States', brand: 'Subaru'),
  '4S4': WmiEntry(country: 'United States', brand: 'Subaru'),
  '4T1': WmiEntry(country: 'United States', brand: 'Toyota'),
  '4US': WmiEntry(country: 'United States', brand: 'BMW'),
  '55S': WmiEntry(country: 'United States', brand: 'Mercedes-Benz'),
  '5N1': WmiEntry(country: 'United States', brand: 'Nissan'),
  '5NM': WmiEntry(country: 'United States', brand: 'Hyundai'),
  '5NP': WmiEntry(country: 'United States', brand: 'Hyundai'),
  '5TD': WmiEntry(country: 'United States', brand: 'Toyota'),
  '5UX': WmiEntry(country: 'United States', brand: 'BMW'),
  '5XX': WmiEntry(country: 'United States', brand: 'Kia'),
  '5XY': WmiEntry(country: 'United States', brand: 'Kia'),
  '5YM': WmiEntry(country: 'United States', brand: 'BMW'),
  '6FP': WmiEntry(country: 'Australia', brand: 'Ford'),
  '7JR': WmiEntry(country: 'United States', brand: 'Volvo'),
  '8AD': WmiEntry(country: 'Argentina', brand: 'Peugeot'),
  '8AE': WmiEntry(country: 'Argentina', brand: 'Citroen'),
  '936': WmiEntry(country: 'Brazil', brand: 'Peugeot'),
  '93U': WmiEntry(country: 'Brazil', brand: 'Audi'),
  '93Y': WmiEntry(country: 'Brazil', brand: 'Renault'),
  '9BW': WmiEntry(country: 'Brazil', brand: 'Volkswagen'),
  'AAV': WmiEntry(country: 'South Africa', brand: 'Volkswagen'),
  'JDA': WmiEntry(country: 'Japan', brand: 'Daihatsu'),
  'JF3': WmiEntry(country: 'Japan', brand: 'Subaru'),
  'JHF': WmiEntry(country: 'Japan', brand: 'Honda'),
  'JHL': WmiEntry(country: 'Japan', brand: 'Honda'),
  'JM0': WmiEntry(country: 'Japan', brand: 'Mazda'),
  'JMB': WmiEntry(country: 'Japan', brand: 'Mitsubishi'),
  'JMF': WmiEntry(country: 'Japan', brand: 'Mazda'),
  'JMY': WmiEntry(country: 'Japan', brand: 'Mitsubishi'),
  'JN0': WmiEntry(country: 'Japan', brand: 'Lexus'),
  'JN3': WmiEntry(country: 'Japan', brand: 'Nissan'),
  'JN7': WmiEntry(country: 'Japan', brand: 'Infiniti'),
  'JNR': WmiEntry(country: 'Japan', brand: 'Infiniti'),
  'JS3': WmiEntry(country: 'Japan', brand: 'Suzuki'),
  'JSA': WmiEntry(country: 'Japan', brand: 'Suzuki'),
  'JTB': WmiEntry(country: 'Japan', brand: 'Toyota'),
  'JTF': WmiEntry(country: 'Japan', brand: 'Toyota'),
  'JTG': WmiEntry(country: 'Japan', brand: 'Daihatsu'),
  'JTK': WmiEntry(country: 'Japan', brand: 'Toyota'),
  'JTL': WmiEntry(country: 'Japan', brand: 'Toyota'),
  'JTM': WmiEntry(country: 'Japan', brand: 'Toyota'),
  'KL1': WmiEntry(country: 'South Korea', brand: 'Chevrolet'),
  'KL5': WmiEntry(country: 'South Korea', brand: 'Suzuki'),
  'KLA': WmiEntry(country: 'South Korea', brand: 'Daewoo'),
  'KMC': WmiEntry(country: 'South Korea', brand: 'Hyundai'),
  'KMF': WmiEntry(country: 'South Korea', brand: 'Hyundai'),
  'KMJ': WmiEntry(country: 'South Korea', brand: 'Hyundai'),
  'KNC': WmiEntry(country: 'South Korea', brand: 'Kia'),
  'KNE': WmiEntry(country: 'South Korea', brand: 'Kia'),
  'KPA': WmiEntry(country: 'South Korea', brand: 'SsangYong'),
  'KPB': WmiEntry(country: 'South Korea', brand: 'SsangYong'),
  'KPT': WmiEntry(country: 'South Korea', brand: 'SsangYong'),
  'L2C': WmiEntry(country: 'China', brand: 'Lynk & Co'),
  'L6T': WmiEntry(country: 'China', brand: 'Geely'),
  'LB3': WmiEntry(country: 'China', brand: 'Geely'),
  'LC0': WmiEntry(country: 'China', brand: 'BYD'),
  'LDC': WmiEntry(country: 'China', brand: 'Dongfeng Peugeot'),
  'LFP': WmiEntry(country: 'China', brand: 'FAW'),
  'LFV': WmiEntry(country: 'China', brand: 'Volkswagen'),
  'LGB': WmiEntry(country: 'China', brand: 'BYD'),
  'LGX': WmiEntry(country: 'China', brand: 'BYD'),
  'LJ1': WmiEntry(country: 'China', brand: 'JAC'),
  'LPA': WmiEntry(country: 'China', brand: 'Polestar'),
  'LRB': WmiEntry(country: 'China', brand: 'Buick'),
  'LSJ': WmiEntry(country: 'China', brand: 'MG'),
  'LSV': WmiEntry(country: 'China', brand: 'Volkswagen'),
  'LSY': WmiEntry(country: 'China', brand: 'Geely'),
  'LVS': WmiEntry(country: 'China', brand: 'Ford'),
  'LVT': WmiEntry(country: 'China', brand: 'NIO'),
  'LVV': WmiEntry(country: 'China', brand: 'Chery'),
  'LYV': WmiEntry(country: 'China', brand: 'Volvo'),
  'LZW': WmiEntry(country: 'China', brand: 'SAIC-GM-Wuling'),
  'MA3': WmiEntry(country: 'India', brand: 'Suzuki'),
  'MAJ': WmiEntry(country: 'India', brand: 'Ford'),
  'MAL': WmiEntry(country: 'India', brand: 'Hyundai'),
  'MDH': WmiEntry(country: 'India', brand: 'Nissan'),
  'MHF': WmiEntry(country: 'Indonesia', brand: 'Toyota'),
  'MMB': WmiEntry(country: 'Thailand', brand: 'Mitsubishi'),
  'MMC': WmiEntry(country: 'Thailand', brand: 'Mitsubishi'),
  'MR0': WmiEntry(country: 'Thailand', brand: 'Toyota'),
  'NLH': WmiEntry(country: 'Turkey', brand: 'Hyundai'),
  'NMT': WmiEntry(country: 'Turkey', brand: 'Toyota'),
  'SAR': WmiEntry(country: 'United Kingdom', brand: 'Rover'),
  'SAX': WmiEntry(country: 'United Kingdom', brand: 'Austin'),
  'SB1': WmiEntry(country: 'United Kingdom', brand: 'Toyota'),
  'SCA': WmiEntry(country: 'United Kingdom', brand: 'Rolls-Royce'),
  'SCB': WmiEntry(country: 'United Kingdom', brand: 'Bentley'),
  'SCC': WmiEntry(country: 'United Kingdom', brand: 'Lotus'),
  'SCF': WmiEntry(country: 'United Kingdom', brand: 'Aston Martin'),
  'SDB': WmiEntry(country: 'United Kingdom', brand: 'Peugeot'),
  'SDP': WmiEntry(country: 'United Kingdom', brand: 'MG'),
  'SFA': WmiEntry(country: 'United Kingdom', brand: 'Ford'),
  'SFD': WmiEntry(country: 'United Kingdom', brand: 'Alexander Dennis'),
  'SHH': WmiEntry(country: 'United Kingdom', brand: 'Honda'),
  'SHS': WmiEntry(country: 'United Kingdom', brand: 'Honda'),
  'SJK': WmiEntry(country: 'United Kingdom', brand: 'Nissan'),
  'SJN': WmiEntry(country: 'United Kingdom', brand: 'Nissan'),
  'SUF': WmiEntry(country: 'Poland', brand: 'Opel'),
  'SUL': WmiEntry(country: 'Poland', brand: 'Opel'),
  'SUW': WmiEntry(country: 'Poland', brand: 'Fiat'),
  'TMA': WmiEntry(country: 'Czech Republic', brand: 'Hyundai'),
  'TMH': WmiEntry(country: 'Czech Republic', brand: 'Hyundai'),
  'TMK': WmiEntry(country: 'Czech Republic', brand: 'Skoda'),
  'TML': WmiEntry(country: 'Czech Republic', brand: 'Skoda'),
  'TMP': WmiEntry(country: 'Czech Republic', brand: 'Skoda'),
  'TRA': WmiEntry(country: 'Hungary', brand: 'Suzuki'),
  'TRU': WmiEntry(country: 'Hungary', brand: 'Audi'),
  'TSM': WmiEntry(country: 'Hungary', brand: 'Suzuki'),
  'U5Y': WmiEntry(country: 'Slovakia', brand: 'Kia'),
  'U6Y': WmiEntry(country: 'Slovakia', brand: 'Kia'),
  'UU2': WmiEntry(country: 'Romania', brand: 'Dacia'),
  'UU3': WmiEntry(country: 'Romania', brand: 'Dacia'),
  'UU6': WmiEntry(country: 'Romania', brand: 'Dacia'),
  'VF0': WmiEntry(country: 'France', brand: 'Alpine'),
  'VF2': WmiEntry(country: 'France', brand: 'Renault'),
  'VF4': WmiEntry(country: 'France', brand: 'Renault'),
  'VF5': WmiEntry(country: 'France', brand: 'Renault'),
  'VF9': WmiEntry(country: 'France', brand: 'Bugatti'),
  'VG6': WmiEntry(country: 'France', brand: 'Renault Trucks'),
  'VR2': WmiEntry(country: 'France', brand: 'Peugeot'),
  'VR6': WmiEntry(country: 'France', brand: 'Peugeot'),
  'VR7': WmiEntry(country: 'France', brand: 'Citroen'),
  'VR8': WmiEntry(country: 'France', brand: 'DS'),
  'VR9': WmiEntry(country: 'France', brand: 'DS'),
  'VS5': WmiEntry(country: 'Spain', brand: 'Cupra'),
  'VS6': WmiEntry(country: 'Spain', brand: 'Ford'),
  'VS7': WmiEntry(country: 'Spain', brand: 'Citroen'),
  'VS9': WmiEntry(country: 'Spain', brand: 'Carrocera'),
  'VSE': WmiEntry(country: 'Spain', brand: 'Suzuki Santana'),
  'VSK': WmiEntry(country: 'Spain', brand: 'Nissan'),
  'VSN': WmiEntry(country: 'Spain', brand: 'Nissan'),
  'VSX': WmiEntry(country: 'Spain', brand: 'Cupra'),
  'VWA': WmiEntry(country: 'Spain', brand: 'Nissan'),
  'VX1': WmiEntry(country: 'United Kingdom', brand: 'Vauxhall'),
  'W0S': WmiEntry(country: 'Germany', brand: 'Opel'),
  'W1N': WmiEntry(country: 'Germany', brand: 'Mercedes-Benz'),
  'W1T': WmiEntry(country: 'Germany', brand: 'Mercedes-Benz'),
  'W1V': WmiEntry(country: 'Germany', brand: 'Mercedes-Benz'),
  'WAG': WmiEntry(country: 'Germany', brand: 'Audi'),
  'WB1': WmiEntry(country: 'Germany', brand: 'BMW Motorrad'),
  'WB3': WmiEntry(country: 'Germany', brand: 'BMW'),
  'WB5': WmiEntry(country: 'United States', brand: 'BMW'),
  'WDF': WmiEntry(country: 'Germany', brand: 'Mercedes-Benz'),
  'WDR': WmiEntry(country: 'Germany', brand: 'Setra'),
  'WF1': WmiEntry(country: 'Germany', brand: 'Ford'),
  'WF7': WmiEntry(country: 'Germany', brand: 'Ford'),
  'WMA': WmiEntry(country: 'Germany', brand: 'MAN'),
  'WMX': WmiEntry(country: 'Germany', brand: 'Mercedes-AMG'),
  'WMZ': WmiEntry(country: 'Netherlands', brand: 'Mini'),
  'WUA': WmiEntry(country: 'Germany', brand: 'Audi'),
  'WUZ': WmiEntry(country: 'Germany', brand: 'Audi'),
  'WVE': WmiEntry(country: 'Germany', brand: 'Volkswagen'),
  'WVG': WmiEntry(country: 'Germany', brand: 'Volkswagen'),
  'WVZ': WmiEntry(country: 'Germany', brand: 'Volkswagen'),
  'X4X': WmiEntry(country: 'Russia', brand: 'BMW'),
  'X7L': WmiEntry(country: 'Russia', brand: 'Renault'),
  'XTA': WmiEntry(country: 'Russia', brand: 'Lada'),
  'XTT': WmiEntry(country: 'Russia', brand: 'UAZ'),
  'YS2': WmiEntry(country: 'Sweden', brand: 'Scania'),
  'YS4': WmiEntry(country: 'Sweden', brand: 'Saab'),
  'YV2': WmiEntry(country: 'Sweden', brand: 'Volvo'),
  'YV5': WmiEntry(country: 'Sweden', brand: 'Volvo'),
  'YVV': WmiEntry(country: 'Sweden', brand: 'Polestar'),
  'Z8N': WmiEntry(country: 'Russia', brand: 'Nissan'),
  'ZA9': WmiEntry(country: 'Italy', brand: 'Lamborghini'),
  'ZAA': WmiEntry(country: 'Italy', brand: 'Autobianchi'),
  'ZAC': WmiEntry(country: 'Italy', brand: 'Jeep'),
  'ZAE': WmiEntry(country: 'Italy', brand: 'Alfa Romeo'),
  'ZAF': WmiEntry(country: 'Italy', brand: 'Alfa Romeo'),
  'ZAP': WmiEntry(country: 'Italy', brand: 'Lancia'),
  'ZAS': WmiEntry(country: 'Italy', brand: 'Maserati'),
  'ZCF': WmiEntry(country: 'Italy', brand: 'Iveco'),
  'ZFB': WmiEntry(country: 'Italy', brand: 'Fiat'),
  'ZFC': WmiEntry(country: 'Italy', brand: 'Fiat'),
  'ZFD': WmiEntry(country: 'Italy', brand: 'Fiat'),
  'ZFM': WmiEntry(country: 'Italy', brand: 'Maserati'),
  'ZFP': WmiEntry(country: 'Italy', brand: 'Fiat Professional'),
  'ZGA': WmiEntry(country: 'Italy', brand: 'Iveco'),
  'ZHL': WmiEntry(country: 'Italy', brand: 'Lamborghini'),
  'ZLA': WmiEntry(country: 'Italy', brand: 'Lancia'),
  'ZN1': WmiEntry(country: 'Italy', brand: 'Iveco'),
  'ZN6': WmiEntry(country: 'Italy', brand: 'Abarth'),
};
