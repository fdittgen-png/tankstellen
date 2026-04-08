import 'package:flutter/material.dart';

/// Common amenities available at fuel stations.
///
/// Parsed from API service strings (e.g. French Prix-Carburants `services_service`)
/// and displayed as icon chips on station cards and detail screens.
enum StationAmenity {
  shop,
  carWash,
  airPump,
  toilet,
  restaurant,
  atm,
  wifi,
  ev,
}

/// Maps a [StationAmenity] to its Material icon.
IconData amenityIcon(StationAmenity amenity) {
  return switch (amenity) {
    StationAmenity.shop => Icons.store,
    StationAmenity.carWash => Icons.local_car_wash,
    StationAmenity.airPump => Icons.tire_repair,
    StationAmenity.toilet => Icons.wc,
    StationAmenity.restaurant => Icons.restaurant,
    StationAmenity.atm => Icons.atm,
    StationAmenity.wifi => Icons.wifi,
    StationAmenity.ev => Icons.ev_station,
  };
}

/// Returns the l10n key label for a [StationAmenity].
///
/// Uses the localized string when available, otherwise falls back to English.
String amenityLabel(StationAmenity amenity) {
  return switch (amenity) {
    StationAmenity.shop => 'Shop',
    StationAmenity.carWash => 'Car Wash',
    StationAmenity.airPump => 'Air',
    StationAmenity.toilet => 'WC',
    StationAmenity.restaurant => 'Food',
    StationAmenity.atm => 'ATM',
    StationAmenity.wifi => 'WiFi',
    StationAmenity.ev => 'EV',
  };
}

/// Detects [StationAmenity] values from a list of free-text service strings.
///
/// Service strings come from APIs (e.g. French "Boutique alimentaire",
/// "Lavage automatique", "Gonflage", "Toilettes publiques"). This function
/// normalizes them and matches against known keywords per amenity.
Set<StationAmenity> parseAmenitiesFromServices(List<String> services) {
  if (services.isEmpty) return const {};

  final result = <StationAmenity>{};
  final joined = services.join(' ').toLowerCase();

  // Shop keywords (FR: boutique, magasin; DE: shop; ES: tienda; IT: negozio)
  if (_matchesAny(joined, _shopKeywords)) {
    result.add(StationAmenity.shop);
  }

  // Car wash (FR: lavage; DE: waschanlage; ES: lavado; IT: lavaggio)
  if (_matchesAny(joined, _carWashKeywords)) {
    result.add(StationAmenity.carWash);
  }

  // Air pump (FR: gonflage, air; DE: luftdruck; ES: aire; IT: aria)
  if (_matchesAny(joined, _airPumpKeywords)) {
    result.add(StationAmenity.airPump);
  }

  // Toilet (FR: toilettes, wc; DE: toilette; ES: aseo; IT: bagno)
  if (_matchesAny(joined, _toiletKeywords)) {
    result.add(StationAmenity.toilet);
  }

  // Restaurant / food
  if (_matchesAny(joined, _restaurantKeywords)) {
    result.add(StationAmenity.restaurant);
  }

  // ATM / cash
  if (_matchesAny(joined, _atmKeywords)) {
    result.add(StationAmenity.atm);
  }

  // WiFi
  if (_matchesAny(joined, _wifiKeywords)) {
    result.add(StationAmenity.wifi);
  }

  // EV charging
  if (_matchesAny(joined, _evKeywords)) {
    result.add(StationAmenity.ev);
  }

  return result;
}

bool _matchesAny(String text, List<String> keywords) {
  for (final kw in keywords) {
    if (text.contains(kw)) return true;
  }
  return false;
}

const _shopKeywords = [
  'boutique', 'magasin', 'shop', 'tienda', 'negozio',
  'epicerie', 'convenience', 'supermarché', 'minimarket',
];

const _carWashKeywords = [
  'lavage', 'waschanlage', 'car wash', 'carwash', 'lavado',
  'lavaggio', 'wash',
];

const _airPumpKeywords = [
  'gonflage', 'luftdruck', 'air pump', 'aire comprimido',
  'aria compressa', 'gonfleur', 'compressor',
];

const _toiletKeywords = [
  'toilette', 'wc', 'restroom', 'sanitaire', 'aseo', 'bagno',
];

const _restaurantKeywords = [
  'restaurant', 'restauration', 'food', 'snack', 'bistro',
  'cafeteria', 'vente de nourriture', 'alimentation',
];

const _atmKeywords = [
  'atm', 'dab', 'distributeur automatique de billets',
  'bancomat', 'geldautomat', 'cajero',
];

const _wifiKeywords = [
  'wifi', 'wi-fi', 'wlan', 'internet',
];

const _evKeywords = [
  'borne electrique', 'recharge', 'ev charg', 'electric vehicle',
  'ladestation', 'elektro',
];
