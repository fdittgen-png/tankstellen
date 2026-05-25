<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Drop zone

Drop fresh phone captures here. Any filename, any order. Then run `/play-store-shots` and the skill will:

1. List what's in this directory.
2. Pattern-match each filename against the slot conventions in the parent `README.md`.
3. For ambiguous captures, prompt you for the slot number.
4. Move + rename to `../published/<NN-slot-name>.png`.
5. Mirror into `../../metadata/android/{en-US,de-DE,fr-FR}/images/phoneScreenshots/<NN>_<slot-name>.png` (per fastlane supply convention).
6. Remove the original from this directory.

This directory should be empty most of the time — when there's stuff in here, it means a capture batch hasn't been integrated yet.

`.gitkeep` lives here so the directory survives a fresh checkout.
