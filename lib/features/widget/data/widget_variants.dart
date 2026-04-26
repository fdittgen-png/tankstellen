/// Valid widget content-variant identifiers (#1121).
///
/// Mirrors [widgetColorSchemes] in shape — a flat const list so callers (the
/// configure activity, JSON encoders, tests) can enumerate the supported
/// values without a dependency on Riverpod or Flutter. Keep in sync with the
/// `VARIANT_*` constants in `StationWidgetRenderer.kt` and the radio-group
/// ids in `WidgetConfigActivity.kt`.
///
/// Variants:
///
/// - `default` — the original widget body. Each row shows the current price
///   and address. The behaviour shipped in #607.
/// - `predictive` — adds a second compact line per row with a "best time to
///   fill" hint derived from the local price-history prediction
///   (`pricePredictionProvider`). Falls back to the default rendering when
///   the predictor returns null or the potential saving is negligible — see
///   [buildPredictivePayload].
const widgetVariants = <String>[
  'default',
  'predictive',
];

/// Default variant when the user has not yet picked one. Matches the
/// `DEFAULT_VARIANT` constant in `StationWidgetRenderer.kt`.
const defaultWidgetVariant = 'default';

/// Predictive variant identifier. Pulled out as a const so renderers and
/// tests can branch without re-typing the literal.
const predictiveWidgetVariant = 'predictive';
