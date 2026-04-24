/// Valid widget color-scheme identifiers, matching the Android drawable set.
///
/// Kept in sync with
/// `android/app/src/main/res/values/widget_color_schemes.xml` and the
/// `drawableForScheme` mapping in `StationWidgetRenderer.kt`. The Phase 1
/// of #607 palette is placeholder and will be swapped by the designer in a
/// follow-up PR; when schemes are added or removed here, update the Kotlin
/// `drawableForScheme` branch and the Android `values/` + `drawable/` +
/// `drawable-night/` resources in the same PR.
///
/// Consumed by the widget configure activity (#610) and by widget-related
/// tests that need to enumerate the supported schemes.
const widgetColorSchemes = <String>[
  'system',
  'light',
  'dark',
  'blue',
  'green',
  'orange',
];

/// Default scheme when the user has not yet picked one. Matches the
/// `DEFAULT_COLOR_SCHEME` constant in `StationWidgetRenderer.kt`.
const defaultWidgetColorScheme = 'system';
