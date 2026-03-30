/// Canonical fuel types across all countries.
/// Each country maps its API values to these canonical types.
enum FuelType {
  e5('e5', 'Super E5'),
  e10('e10', 'Super E10'),
  e98('e98', 'Super 98'),
  diesel('diesel', 'Diesel'),
  dieselPremium('diesel_premium', 'Diesel Premium'),
  e85('e85', 'E85 / Bioéthanol'),
  lpg('lpg', 'GPL / LPG'),
  cng('cng', 'GNV / CNG'),
  hydrogen('hydrogen', 'Hydrogène / H2'),
  electric('electric', 'Electric ⚡'),
  all('all', 'All');

  final String apiValue;
  final String displayName;

  const FuelType(this.apiValue, this.displayName);

  static FuelType fromString(String value) {
    return FuelType.values.firstWhere(
      (e) => e.apiValue == value.toLowerCase(),
      orElse: () => FuelType.all,
    );
  }
}

/// Returns fuel types available for a given country code.
List<FuelType> fuelTypesForCountry(String countryCode) {
  switch (countryCode) {
    case 'DE':
      return [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all];
    case 'FR':
      return [
        FuelType.e10, FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.e85, FuelType.lpg, FuelType.electric, FuelType.all,
      ];
    case 'AT':
      return [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all];
    case 'ES':
      return [
        FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
        FuelType.dieselPremium, FuelType.lpg, FuelType.electric, FuelType.all,
      ];
    case 'IT':
      return [
        FuelType.e5, FuelType.diesel, FuelType.lpg, FuelType.cng, FuelType.electric, FuelType.all,
      ];
    default:
      return [FuelType.e5, FuelType.e10, FuelType.diesel, FuelType.electric, FuelType.all];
  }
}
