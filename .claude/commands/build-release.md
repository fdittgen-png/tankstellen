Build release APK + AAB for Play Store with automatic version bump and copy to OneDrive.

## Why this command exists
Build numbers uploaded to Play Console cannot be reused. Without auto-bumping, uploads
fail with "code X a déjà été utilisé" (code already used). This command guarantees
a fresh, unused build number every time.

## Steps

1. **Set up environment:**
   ```bash
   export PATH="/c/dev/flutter/bin:$PATH"
   export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-17.0.18.8-hotspot"
   export ANDROID_HOME="$LOCALAPPDATA/Android/Sdk"
   ```

2. **Read current version from pubspec.yaml:**
   Parse line `version: X.Y.Z+BUILD` to extract the current build number.

3. **Auto-bump the build number** by at least 1 (safer: +10 to jump past any manual
   uploads). Update pubspec.yaml with the new version.
   - If current is `4.3.0+4010`, new becomes `4.3.0+4011` (or higher)
   - Preserve the semantic version (X.Y.Z) unless user asks to change it

4. **Build AAB for Play Store:**
   ```bash
   flutter build appbundle --release --flavor play
   ```

5. **Build split APKs for sideloading / F-Droid:**
   ```bash
   flutter build apk --release --split-per-abi --flavor play
   ```

6. **Copy artifacts to OneDrive:**
   ```bash
   cp build/app/outputs/flutter-apk/app-*-play-release.apk "/c/Users/fditt/OneDrive/Android/"
   cp build/app/outputs/bundle/playRelease/app-play-release.aab "/c/Users/fditt/OneDrive/Android/"
   ```

7. **Commit the version bump** to master:
   ```bash
   git add pubspec.yaml
   git commit -m "chore: Bump build number to BUILD for Play Store release

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
   git push origin master
   ```

8. **Report:**
   ```
   BUILT: v4.3.0+4011

   Packages in C:\Users\fditt\OneDrive\Android\:
   - app-play-release.aab (60 MB) ← Upload this to Play Store
   - app-arm64-v8a-play-release.apk (32 MB)
   - app-armeabi-v7a-play-release.apk (28 MB)
   - app-x86_64-play-release.apk (34 MB)

   Ready to upload .aab to Play Console.
   ```

## Rules
- **Always bump the build number before building** — never rebuild with the same number
- **Always use the `play` flavor** for Play Store builds (required after #12 added flavors)
- **Never skip the commit step** — keeps pubspec.yaml in sync with Play Store history
- If Play Console still rejects as "already used", bump by +10 and rebuild

## Flavors
- `--flavor play` — Google Play Store distribution (default)
- `--flavor fdroid` — F-Droid distribution (GMS-free, uses FORCE_LOCATION_MANAGER)
