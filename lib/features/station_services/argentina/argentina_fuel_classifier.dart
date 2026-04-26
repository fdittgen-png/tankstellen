/// Argentine "Secretaría de Energía" open-data CSV uses product strings like:
///   - "Nafta (premium) de más de 95 Ron"
///   - "Nafta (súper) entre 92 y 95 Ron"
///   - "Gas Oil Grado 2"
///   - "Gas Oil Grado 3"
///   - "GNC"
///
/// These are classified into the five fuel columns the app renders. Kept as
/// a pure function so its edge cases (accents, whitespace, case, "95 Ron"
/// appearing in both premium and super strings, grade 2/3 ordering) can be
/// tested without HTTP / Dio / the whole service chain.
enum ArgentinaFuelCategory {
  naftaPremium,
  naftaRegular,
  dieselPremium,
  dieselRegular,
  gnc,
}

ArgentinaFuelCategory? classifyArgentinaProduct(String producto) {
  // Normalise: lowercase, collapse whitespace.
  final p = producto.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  // GNC is unambiguous.
  if (p.contains('gnc')) return ArgentinaFuelCategory.gnc;

  final isNafta = p.contains('nafta');
  final isGasOil = p.contains('gas oil') || p.contains('gasoil');

  // "super" appears inside BOTH "súper 92" AND the literal word "supermium" —
  // but only the first is nafta. Because we gate on `isNafta` the collision
  // can't happen.
  //
  // IMPORTANT: premium must win over super/92 because "Nafta (premium) de más
  // de 95 Ron" technically contains the substring "95" (as does "Nafta (súper)
  // entre 92 y 95 Ron"). Check premium markers FIRST.
  if (isNafta) {
    // Super/regular markers are checked BEFORE the premium "95 ron" fallback
    // because "Nafta (súper) entre 92 y 95 Ron" contains both "super" AND
    // "95 ron" — the word "súper" / "92" is the true signal.
    final hasSuperMarker = p.contains('super') ||
        p.contains('súper') ||
        p.contains(' 92 ') ||
        p.endsWith(' 92') ||
        p.contains('grado 2');
    if (hasSuperMarker && !p.contains('premium') && !p.contains('grado 3')) {
      return ArgentinaFuelCategory.naftaRegular;
    }
    // Premium markers or the octane hint "95 ron" → premium. (In Argentina
    // 95+ Ron is marketed as high-octane/premium.)
    if (p.contains('premium') ||
        p.contains('grado 3') ||
        p.contains('95 ron')) {
      return ArgentinaFuelCategory.naftaPremium;
    }
    // Bare "nafta" with no marker → regular.
    return ArgentinaFuelCategory.naftaRegular;
  }

  if (isGasOil) {
    if (p.contains('premium') || p.contains('grado 3')) {
      return ArgentinaFuelCategory.dieselPremium;
    }
    return ArgentinaFuelCategory.dieselRegular;
  }

  return null;
}
