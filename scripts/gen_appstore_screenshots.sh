#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT
#
# App Store screenshot batch runner (#3521).
#
# Runs integration_test/appstore_screenshots_test.dart once per shot in a
# FRESH `flutter drive` process. A single shared process cannot capture more
# than the first shot: re-initialising Hive between testWidgets bodies leaves
# every subsequent run with an empty result list and a stray tip snackbar.
#
# Usage:
#   scripts/gen_appstore_screenshots.sh <simulator-udid>
#
# Output: build/appstore_screenshots/<locale>_<mode>_search.png at the
# simulator's native resolution. On an iPhone 17 Pro Max that is 1320×2868 —
# exactly the App Store 6.9" iPhone slot, which covers all iPhone sizes.
# Copy the results into ios/fastlane/screenshots/<locale>/ (deliver layout).

set -euo pipefail

UDID="${1:?usage: $0 <simulator-udid> (see: flutter devices)}"

# Keep in sync with the `shots` list in the test target.
SHOTS=(
  en-US_light
  en-US_dark
  de-DE_light
  de-DE_dark
  fr-FR_light
  fr-FR_dark
  es-ES_light
  it_light
  pt-PT_light
)

for shot in "${SHOTS[@]}"; do
  echo "=== capturing $shot"
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/appstore_screenshots_test.dart \
    --dart-define=SHOT="$shot" \
    -d "$UDID"
done

echo "=== done"
ls -la build/appstore_screenshots/
