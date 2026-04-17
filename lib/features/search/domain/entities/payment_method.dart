import 'package:flutter/material.dart';

/// Payment methods that may be accepted at a fuel station.
///
/// These are inferred from the station brand; fuel APIs do not currently
/// expose per-station payment data, so we show a reasonable default set
/// that reflects what is commonly available at each brand across Europe.
enum PaymentMethod {
  cash,
  card,
  contactless,
  fuelCard,
  app,
}

/// Maps a [PaymentMethod] to its Material icon.
IconData paymentMethodIcon(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.cash => Icons.payments,
    PaymentMethod.card => Icons.credit_card,
    PaymentMethod.contactless => Icons.contactless,
    PaymentMethod.fuelCard => Icons.local_gas_station,
    PaymentMethod.app => Icons.smartphone,
  };
}

/// Infers the set of payment methods a station likely accepts from its brand.
///
/// Nearly every European fuel station accepts cash, card, and contactless
/// today; we add fuel cards for major networks and a branded app chip
/// when the brand has a known loyalty/pay app (Shell, BP, Aral, Total,
/// Esso, OMV, Eni, Repsol).
Set<PaymentMethod> inferPaymentMethods(String brand) {
  final normalized = brand.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const {PaymentMethod.cash, PaymentMethod.card};
  }

  final result = <PaymentMethod>{
    PaymentMethod.cash,
    PaymentMethod.card,
    PaymentMethod.contactless,
  };

  if (_matchesAnyBrand(normalized, _fuelCardBrands)) {
    result.add(PaymentMethod.fuelCard);
  }
  if (_matchesAnyBrand(normalized, _appBrands)) {
    result.add(PaymentMethod.app);
  }

  return result;
}

/// Returns the branded app name for a given brand, or null if unknown.
///
/// Used to surface a specific app label (e.g. "Shell App", "BPme")
/// in UI instead of a generic "App" chip.
String? brandAppName(String brand) {
  final normalized = brand.trim().toLowerCase();
  for (final entry in _brandAppNames.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return null;
}

bool _matchesAnyBrand(String brand, List<String> keys) {
  for (final key in keys) {
    if (brand.contains(key)) return true;
  }
  return false;
}

const _fuelCardBrands = [
  'shell', 'bp', 'aral', 'total', 'esso', 'omv', 'eni', 'repsol',
  'agip', 'cepsa', 'galp', 'lukoil', 'circle k', 'q8', 'avia',
];

const _appBrands = [
  'shell', 'bp', 'aral', 'total', 'esso', 'omv', 'eni', 'repsol',
];

const _brandAppNames = {
  'shell': 'Shell App',
  'bp': 'BPme',
  'aral': 'Aral Pay',
  'totalenergies': 'TotalEnergies',
  'total': 'TotalEnergies',
  'esso': 'Esso Extras',
  'omv': 'OMV Card',
  'eni': 'Eni Station',
  'repsol': 'Waylet',
};
