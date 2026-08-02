**15 · Platforms**

# macOS

> Adding a macOS target to an existing Flutter app takes an afternoon. Making the resulting app openable by someone who downloads it takes considerably longer, and the reason is notarisation — which is no longer optional and whose absence produces a file that simply refuses to run.

**Chunk prefix** mac **Updated** 2026-08-01 **Depends on** 14 iOS

#### On this page

1. [Two distribution channels, two certificates](#channels)
1. [Notarisation is not optional](#notarisation)
1. [The certificate only the account holder can create](#accountholder)
1. [The sandbox decision](#sandbox)
1. [Secure storage and error −34018](#keychain)
1. [Packaging a DMG](#packaging)
1. [CI that degrades honestly](#ci)
1. [Adapting a mobile UI](#adapting)

<!-- chunk: mac.channels | tags: macos,distribution,signing -->

## Two distribution channels, two certificates

Decide the channel first; it determines the certificate, the entitlements and whether the sandbox is negotiable.

|   | Direct download (DMG) | Mac App Store |
| --- | --- | --- |
| Certificate | **Developer ID Application** | **Apple Distribution** (Mac) |
| Sandbox | Optional | **Mandatory** |
| Hardened runtime | **Required** (for notarisation) | Handled by the store |
| Notarisation | **Required** | Not applicable |
| Review | None | Full review |
| Update mechanism | Yours to build | The store |
| Time to first release | Days | Weeks |

> **[RULE]**

> **For a companion desktop build of a mobile app, ship a notarised DMG.** The store adds review latency and a mandatory sandbox for an audience that is usually a fraction of your mobile users. The DMG path is faster, has no review, and — once the automation exists — costs nothing per release. Revisit only if desktop becomes a primary channel.

Both certificates can live in the same fastlane certificate repository alongside your iOS ones; fetch the Developer ID one with the platform set to macOS. Apple's per-team certificate limits are counted per type, so adding a Developer ID certificate does not consume an iOS distribution slot.

<!-- chunk: mac.notarisation | tags: notarisation,gatekeeper,macos -->

## Notarisation is not optional

Since macOS 15, an application Apple has not notarised is **refused outright** on a downloading Mac — and the old right-click-Open bypass is gone.

> **[WHY]**

> Historically an unsigned Mac app was merely inconvenient: a scary dialog and a right-click. That is no longer true. Without notarisation you are not shipping a slightly awkward download — you are shipping a file people cannot open at all, with an error message that suggests the file is damaged. Notarisation moved from "polish" to "the build is useless without it".

The pipeline, in order — and the order matters:

```bash
set -euo pipefail
APP="build/macos/Build/Products/Release/MyApp.app"

# 1. Sign nested code FIRST — frameworks, dylibs, helpers — then the bundle
#    LAST. Signing the outer bundle first invalidates when the inner code
#    is signed afterwards.
find "$APP/Contents/Frameworks" -name "*.framework" -o -name "*.dylib" | while read -r f; do
  codesign --force --timestamp --options runtime \
           --sign "$DEVELOPER_ID" "$f"
done

# 2. The bundle, with the hardened runtime and the entitlements.
codesign --force --timestamp --options runtime \
         --entitlements macos/Runner/Release.entitlements \
         --sign "$DEVELOPER_ID" "$APP"

# 3. Verify BEFORE spending time on notarisation.
codesign --verify --deep --strict --verbose=2 "$APP"

# 4. Package.
hdiutil create -volname "MyApp" -srcfolder "$APP" -ov -format UDZO MyApp.dmg
codesign --force --timestamp --sign "$DEVELOPER_ID" MyApp.dmg

# 5. Notarise the DMG and WAIT for the verdict.
xcrun notarytool submit MyApp.dmg \
  --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER" \
  --wait

# 6. Staple the ticket so the app opens offline.
xcrun stapler staple MyApp.dmg

# 7. Assert Gatekeeper accepts it — so a build that would be refused on
#    someone's Mac fails HERE instead.
spctl --assess --type open --context context:primary-signature -vv MyApp.dmg
```

> **[RULE]**

> **Step 7 is the point of the whole script.** Signing and notarising without asserting the verdict means you discover the failure from a user. The `spctl` assessment is the same check the OS performs on open, so a green CI run means the artifact will actually launch.

> **[TRAP]**

> **Symptom: notarisation is rejected with "the signature does not include a secure timestamp" or "the executable does not have the hardened runtime enabled".** Both come from missing `codesign` flags. `--timestamp` and `--options runtime` are required on *every* signature, including nested frameworks. Add them to a helper function rather than repeating them, so one call site cannot omit them.

> **[TRAP]**

> **Symptom: notarisation succeeds, but the app still refuses to open on a machine with no network.** The ticket was not stapled. Notarisation registers the artifact with Apple; stapling attaches the proof to the file so Gatekeeper can verify offline. Without it, an offline user is blocked.

<!-- chunk: mac.accountholder | tags: certificates,apple,portal -->

## The certificate only the account holder can create

> **[TRAP]**

> **Symptom: creating a Developer ID certificate through the API fails with *"This operation can only be performed by the Account Holder"*.** No App Store Connect API key can mint a Developer ID certificate, whatever its role. It is a deliberate restriction — that certificate signs software distributed outside the store, so Apple ties it to the person legally responsible for the account.

> **The one-time manual step:**

> ```bash
> fastlane match import --type developer_id
> ```

1. Sign in to Xcode as the *account holder*.
1. Settings → Accounts → Manage Certificates → **+** → **Developer ID Application**.
1. Import it into the shared certificate repository:

> After that CI can fetch it read-only like any other. Write this into the runbook — it is invisible from automation and will otherwise be rediscovered under time pressure.

<!-- chunk: mac.sandbox | tags: entitlements,sandbox,macos -->

## The sandbox decision

Outside the Mac App Store the sandbox is optional. Enable it anyway unless something concrete requires otherwise — but know what it costs before you do.

```xml
<!-- macos/Runner/Release.entitlements -->
<dict>
  <key>com.apple.security.app-sandbox</key><true/>
  <key>com.apple.security.network.client</key><true/>

  <!-- Only what you actually use. Each one is a question you may be asked. -->
  <key>com.apple.security.files.user-selected.read-write</key><true/>
  <key>com.apple.security.device.bluetooth</key><true/>
  <key>com.apple.security.personal-information.location</key><true/>

  <!-- Required by the keychain — see below. -->
  <key>keychain-access-groups</key>
  <array><string>$(AppIdentifierPrefix)de.example.app</string></array>
</dict>
```

| Sandboxed | Not sandboxed |
| --- | --- |
| File access limited to what the user picks in a panel | Full filesystem access subject to normal permissions |
| Keychain is per-app and needs an access group | Broader keychain access |
| Network needs an explicit entitlement | Unrestricted |
| Required for the store; a credible security posture for a privacy-focused app | Simpler; occasionally the only way to do something |

> **[RULE]**

> **Keep `Debug` and `Release` entitlements in sync, and diff them in review.** The default Flutter macOS project ships separate files, and the classic failure is a capability that works in debug and is missing in release — discovered after signing, when the feedback loop is at its longest.

<!-- chunk: mac.keychain | tags: keychain,secure-storage,error-34018 -->

## Secure storage and error −34018

> **[TRAP]**

> **Symptom: secure storage throws `-34018` (`errSecMissingEntitlement`) on macOS while the identical code works on iOS.** The macOS keychain requires the app to declare a keychain access group, and the entitlement must be present in the build configuration you are actually running. Three distinct causes, checked in this order:

1. **No `keychain-access-groups` entitlement.** Add it to *both* the debug and release entitlement files, using `$(AppIdentifierPrefix)` plus your bundle identifier.
1. **Running an unsigned debug build.** Entitlements only take effect on a signed binary. `flutter run -d macos` with no signing identity configured produces a binary whose entitlements are inert. Configure at least a development signing identity in the Xcode project.
1. **Bundle identifier mismatch.** The access group must correspond to the actual bundle identifier. A stale identifier from a project template silently breaks the match.

> This one error accounts for the majority of "my Flutter app works everywhere except macOS" reports involving stored credentials.

> **[CHECK]**

> Verify what the built binary actually carries, rather than what the file says it should:

> ```bash
> codesign -d --entitlements - build/macos/Build/Products/Release/MyApp.app
> ```

> If `keychain-access-groups` is absent from that output, the entitlement file is not reaching the build — which is a project-configuration problem, not a code problem.

<!-- chunk: mac.packaging | tags: dmg,packaging,distribution -->

## Packaging a DMG

A DMG is a disk image containing the app bundle and, conventionally, a symlink to `/Applications` so the user can drag one onto the other.

```bash
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"      # the drag target

hdiutil create -volname "MyApp" -srcfolder "$STAGE" \
               -ov -format UDZO "MyApp.dmg"
```

| Consideration | Guidance |
| --- | --- |
| **Sign the DMG too** | Not only the app inside it. Notarisation applies to the container you distribute. |
| **Name it with the version** | `MyApp-1.4.2.dmg`. Users keep downloads; an ambiguous name generates support questions. |
| **Universal binary** | Build for both architectures unless you have a reason not to. A user on the other architecture running under translation is a support case waiting to happen. |
| **Updates** | Direct distribution has no update mechanism. At minimum, check a version endpoint on launch and link to the download page. A full self-updater is a large project — be sure you want it. |
| **Attach it to a release** | On a version tag, attach the DMG to the release so the download link is stable and versioned. |

<!-- chunk: mac.ci | tags: ci,degradation,workflow -->

## CI that degrades honestly

A macOS build job must handle three situations: full secrets available, no signing identity, and a fork pull request with no secrets at all — and it must not lie about which one happened.

```yaml
jobs:
  macos:
    runs-on: macos-15
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: "3.41.9" }

      - name: Fetch the Developer ID certificate
        continue-on-error: true          # a fork PR legitimately cannot
        run: bundle exec fastlane match_developer_id
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}

      - run: flutter build macos --release

      - name: Sign, notarise, staple, verify
        id: sign
        continue-on-error: true
        run: bash scripts/sign_and_notarize_macos.sh

      - name: Name the artifact for what it is
        run: |
          if [ "${{ steps.sign.outcome }}" != "success" ]; then
            mv MyApp.dmg MyApp-unsigned.dmg
            echo "::warning::No Developer ID available — this DMG is UNSIGNED \
            and macOS will refuse to open it. Build it locally with signing \
            secrets, or download the signed release artifact."
          fi

      - uses: actions/upload-artifact@v4
        with: { name: macos-dmg, path: "*.dmg" }
```

> **[RULE]**

> **An artifact that cannot do its job says so in its own filename.** A file called `MyApp.dmg` that macOS refuses to open is worse than one called `MyApp-unsigned.dmg` with a warning attached — the first generates a bug report about a corrupt download, the second is self-explanatory. This is [honest degradation](04-robustness.html#honest), and the DMG case is where the principle was named.

Trigger the job on dispatch, on pull requests touching the macOS directory or the signing script, and on version tags. Not on every push — macOS runner minutes bill at a multiple of Linux.

<!-- chunk: mac.adapting | tags: desktop,ui,adaptation -->

## Adapting a mobile UI

The build succeeding is not the same as the app being usable. A phone layout on a desktop window is technically running and practically unpleasant.

| Area | What to do |
| --- | --- |
| **Window sizing** | Set a sensible minimum size in the native window controller. A Flutter desktop window defaults to a size that fits nothing. |
| **Layout** | Break at width, not at platform. The same responsive rules that give you a tablet layout give you a desktop one. |
| **Navigation** | A bottom tab bar is wrong on desktop. Switch to a rail or a sidebar above a breakpoint. |
| **Input** | Keyboard shortcuts, hover states, right-click menus, text selection. Desktop users expect all four. |
| **Unavailable capabilities** | No camera in many cases, no NFC, no telephony. Hide those surfaces rather than showing a failing button — the same [three-state availability](12-nfc-rfid.html#status) discipline. |
| **Files** | Real save and open panels; drag-and-drop into the window. This is where a desktop build genuinely beats the mobile one. |
| **Plugin coverage** | Check every plugin has a macOS implementation before promising the target. A missing implementation usually throws at runtime, not at build time. |

> **[CHECK]**

> Run the desktop build in CI on any pull request that touches shared code, even if you do not distribute from that run. A `dart:io` import that reaches web code, or a plugin with no desktop implementation, then fails in CI rather than in front of a user. Compilation is cheap insurance for a secondary platform nobody remembers to test.

#### Sources for this page

- One project's macOS workflow and its signing script: nested-frameworks-first signing, hardened runtime, `notarytool` submission with wait, stapling, and the `spctl` assertion so a build that would be refused fails in CI.
- Its recorded finding that an App Store Connect API key cannot create a Developer ID certificate — the account-holder restriction and the Xcode plus `match import` workaround.
- The same project's honest-degradation naming rule for unsigned DMGs, and its statement that since macOS 15 an un-notarised downloaded app is refused outright with no right-click bypass.

The keychain `-34018` diagnosis and the UI-adaptation table are general platform knowledge; the entitlements snippet is illustrative.
