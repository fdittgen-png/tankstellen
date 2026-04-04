Run accessibility checks on all screens. Usage: `/test-accessibility` or `/test-accessibility <screen>`

## Steps

1. **Identify target screens.** If `$ARGUMENTS` is:
   - A specific screen → test only that screen
   - Empty → test all screens listed below

2. **Screens to test:**
   - SearchScreen (`lib/features/search/presentation/screens/`)
   - FavoritesScreen (`lib/features/favorites/presentation/screens/`)
   - MapScreen (`lib/features/map/presentation/screens/`)
   - ProfileScreen (`lib/features/profile/presentation/screens/`)
   - SetupScreen (`lib/features/setup/presentation/screens/`)
   - StationDetailScreen (`lib/features/station_detail/presentation/screens/`)
   - AlertsScreen (`lib/features/alerts/presentation/screens/`)
   - CalculatorScreen (`lib/features/calculator/presentation/screens/`)

3. **For each screen, check these guidelines:**
   ```dart
   final handle = tester.ensureSemantics();

   // Android: 48x48dp minimum tap targets
   await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

   // iOS: 44x44dp minimum tap targets
   await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

   // Text contrast: 4.5:1 for normal, 3:1 for large
   await expectLater(tester, meetsGuideline(textContrastGuideline));

   // All tappable elements have semantic labels
   await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

   handle.dispose();
   ```

4. **Report:**
   ```
   ACCESSIBILITY RESULTS:

   ✓ SearchScreen — all guidelines pass
   ✗ ProfileScreen — androidTapTargetGuideline FAIL
     - IconButton at (120, 340) is 36x36, minimum 48x48
     - Fix: wrap in SizedBox(width: 48, height: 48)

   SUMMARY: X/Y screens pass all guidelines
   ```

5. **For failures:** Provide specific fix suggestions:
   - Small tap targets → add `SizedBox` or `constraints`
   - Missing labels → add `Semantics(label: '...')`
   - Low contrast → adjust color values

## Guidelines Reference
- Android tap target: 48x48dp
- iOS tap target: 44x44dp
- Text contrast (WCAG AA): 4.5:1 normal, 3:1 large (18sp+)
- All interactive elements need semantic labels for screen readers
