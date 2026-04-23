import '../../../search/domain/entities/brand_registry.dart';
import '../../../search/domain/entities/station.dart';

/// True when the station has a real, displayable brand — i.e. not
/// empty and not one of the sentinel strings that parsers use when
/// they cannot detect a brand (`'Station'` is the legacy sentinel,
/// `BrandRegistry.independentLabel` is the new one from #482). Used
/// everywhere the detail screen decides whether to render the brand
/// text or fall back to the street address as the title.
bool hasRealBrand(Station s) {
  if (s.brand.isEmpty) return false;
  if (s.brand == 'Station') return false;
  if (s.brand == BrandRegistry.independentLabel) return false;
  return true;
}

/// True when the station's brand is the explicit "independent" sentinel
/// (or the legacy `'Station'` value). The detail view uses this to
/// render a localised "Station indépendante" subtitle so users can tell
/// the difference between a genuine independent and a brand-detection
/// bug (#482).
bool isIndependentSentinel(Station s) =>
    s.brand == BrandRegistry.independentLabel || s.brand == 'Station';
