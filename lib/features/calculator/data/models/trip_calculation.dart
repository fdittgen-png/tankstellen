class TripCalculation {
  final double distanceKm;
  final double consumptionPer100Km;
  final double pricePerLiter;

  const TripCalculation({
    required this.distanceKm,
    required this.consumptionPer100Km,
    required this.pricePerLiter,
  });

  double get totalLiters => distanceKm * consumptionPer100Km / 100;
  double get totalCost => totalLiters * pricePerLiter;
}
