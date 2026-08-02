**14 · Platforms**

# iOS / iPhone

> iOS costs more per release than every other channel combined, and almost all of it is signing and review. The engineering is not hard; the failure modes are opaque, the feedback loop runs in tens of minutes on billed runners, and several of them present as a job that hangs in silence.

**Chunk prefix** ios **Updated** 2026-08-01 **Depends on** 09 Confidentiality · 10 Bluetooth

#### On this page

1. [Identities and what cannot be re-issued](#identities)
1. [Signing with fastlane match](#match)
1. [The keychain hang](#keychain)
1. [A CI job that survives](#ci)
1. [App Store Connect API-key limits](#asc)
1. [Background modes](#background)
1. [Widget and share extensions](#extensions)
1. [Privacy manifests and usage strings](#privacy)
1. [The review-rejection playbook](#review)
1. [Release checklist](#checklist)

<!-- chunk: ios.identities | tags: apple,identity,secrets -->

## Identities and what cannot be re-issued

Write down which account owns what, because iOS involves at least four identities and confusing two of them wastes a day.

| Identity | Note |
| --- | --- |
| **Apple Developer account** | Frequently *not* the same address as your code-hosting account. Record it explicitly. |
| **Team ID** | Ten characters. Appears in the fastlane app file, the match file and the Xcode project. |
| **Bundle identifier** | Almost never equal to the Android application id. Each extension has its own, derived from the host's. |
| **App Store Connect API key** | A `.p8` file plus a key id and an issuer id. |

> **[RULE]**

> **Three pieces of material here are irreplaceable. Back them up off-machine, today.**

- **The App Store Connect `.p8` private key** — downloadable exactly once. Apple will not re-issue it.
- **The certificate-repository passphrase** — without it, the encrypted repository is permanently unreadable. One project lost one and had to stand up an entirely separate certificate repository rather than re-encrypt a repository a sibling app depended on.
- **The distribution certificate's private key**, if it exists only in a local keychain and not in the certificate repository.

> Keep an explicit "irreplaceable material" list in your release documentation naming where each backup lives.

<!-- chunk: ios.match | tags: fastlane,match,signing -->

## Signing with fastlane match

Certificates and profiles live encrypted in a private repository; CI fetches them read-only and never mints anything.

```ruby
# Matchfile
# SSH, not HTTPS: a fine-grained token kept returning 403 even with
# read-only contents scope. CI loads a read-only deploy key via an
# ssh-agent action; humans use their own key.
git_url("git@github.com:org/app-ios-certs.git")
storage_mode("git")
type("appstore")

# EVERY signed target, or the archive fails with "No profile for …".
# A widget extension is a separate code-signed target with its own App ID.
app_identifier([
  "de.example.app",
  "de.example.app.WidgetExtension",
])
team_id("XXXXXXXXXX")

# CI is ALWAYS read-only. Only a human on a trusted machine may create
# certificates — that touches the developer portal and the encrypted repo.
readonly(ENV["CI"] == "true")
```

| Lane | Runs where | Purpose |
| --- | --- | --- |
| `match_bootstrap` | Workstation only | One-time: create certificates and push them to the repository |
| `match_appstore` | CI | Read-only fetch before building |
| `match_sync_appstore` | CI, on demand | **Repair:** write-mode, appstore type only, generates *missing* profiles without forcing new certificates. This is what you run when a new signed target has no profile. |

> **[TRAP]**

> **Symptom: "No matching provisioning profiles found" after adding an extension.** A new signed target needs its own App ID and its own profile. Add the identifier to the match file and run the repair lane — a plain read-only fetch cannot create what does not exist.

> **[TRAP]**

> **Symptom: the archive fails on a missing entitlement after a profile regeneration.** If the host app and an extension share an app group, **both App IDs must have the App Groups capability enabled in the developer portal** — and there is *no App Store Connect API endpoint for app groups*. It is a manual, portal-only step. Regenerated profiles carry the entitlement only if the capability is enabled first. Note this in the runbook; it is invisible from automation and will be rediscovered otherwise.

<!-- chunk: ios.keychain | tags: ci,keychain,codesign,hang -->

## The keychain hang

> **[TRAP]**

> **Symptom: the CI job produces no output after the signing step and eventually hits the job timeout. No error, no stack, nothing.** Without a dedicated keychain, match imports the certificate into the runner's login keychain — which on a headless machine is locked and whose password nothing knows. `codesign` then raises a GUI permission prompt that nobody can answer, and the job sits in silence until it is killed. Match usually logs a warning about being unable to configure the imported item to prevent a UI prompt; that warning is the only clue and it is easy to miss.

> **The fix is one line in the fastlane `before_all`:**

> ```ruby
> before_all do
>   setup_ci if ENV["CI"] == "true"   # creates + unlocks a temporary keychain
> end
> ```

> It is a no-op locally, so developer workflows are unaffected. This is the single highest-value line in an iOS CI configuration, and it is how one project's first TestFlight build died.

> **[TRAP]**

> **Symptom: "CocoaPods is installed but broken."** A Ruby-setup action switches the active Ruby, and the system CocoaPods installation's gem home no longer matches. Reinstall pods under the active Ruby — with a committed `Gemfile` and `Gemfile.lock` and `bundle exec` everywhere — rather than relying on whatever the runner image ships.

<!-- chunk: ios.ci | tags: ci,macos,workflow -->

## A CI job that survives

macOS runners bill at a multiple of Linux, so iOS jobs are dispatch-triggered or scheduled — never on every pull request.

```yaml
jobs:
  build-and-upload:
    # PINNED, not macos-latest: the latest label migrates to a new major
    # on a published date and takes the Xcode/SDK selection with it.
    runs-on: macos-15
    timeout-minutes: 60
    permissions:
      contents: write        # the post-upload tag push
    steps:
      - uses: actions/checkout@v7

      # Apple rejects uploads built with an SDK older than the current
      # major, so track the newest stable Xcode explicitly.
      - uses: maxim-lobanov/setup-xcode@v1
        with: { xcode-version: latest-stable }

      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }

      # Read-only deploy key for the certificate repository.
      - uses: webfactory/ssh-agent@v0.9.0
        with: { ssh-private-key: "${{ secrets.MATCH_DEPLOY_KEY }}" }

      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: "3.41.9" }

      - name: Compute a monotonic build number
        id: bn
        run: echo "n=$(( 1000000 + ( $(date -u +%s) - 1751760000 ) / 60 ))" >> "$GITHUB_OUTPUT"

      - run: bundle exec fastlane ios release_testflight
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APP_STORE_CONNECT_API_KEY_BASE64: ${{ secrets.APP_STORE_CONNECT_API_KEY_BASE64 }}
          APP_STORE_CONNECT_API_KEY_ID:     ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID:  ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
          FLUTTER_BUILD_NUMBER: ${{ steps.bn.outputs.n }}
```

| Detail | Why |
| --- | --- |
| Pin the runner image | `macos-latest` migrates on a published date and changes your Xcode and SDK without a commit |
| Newest stable Xcode | Apple rejects uploads built against an SDK older than the current major |
| Build number via Flutter's flag | Set the project's version field to Flutter's build-number variable and pass `--build-number`; the Xcode versioning tool does not work reliably in this arrangement |
| Same scheme as the other store | One number identifies a build everywhere — see [page 05](05-traceability.html#build-to-commit) |
| Cache pods on the lockfile | Pod resolution is a large share of the job |
| Upload debug symbols as an artifact | You will need them to symbolicate a crash months later |
| Tag the commit after upload | Otherwise the shipped build maps to nothing |

<!-- chunk: ios.asc | tags: app-store-connect,api,limits -->

## App Store Connect API-key limits

The API key does most things and cannot do several important ones. Knowing which in advance saves a cycle each.

| Task | API? | Note |
| --- | --- | --- |
| Upload a build to TestFlight | Yes | The main path |
| Manage beta groups and testers | Yes | With caveats — see [page 20](20-testers-google-groups.html) |
| Push listing metadata | Yes | Never auto-submit for review |
| Set beta review information | Yes | Ahead of a build, so the first external build sails through |
| **Create an app record** | **No** | *"The resource 'apps' does not allow 'CREATE'"*, whatever the key's role. Create it in the web UI. |
| **Enable App Groups on an App ID** | **No** | Portal-only, manual |
| **Create a Developer ID certificate** | **No** | Account holder only — see [page 15](15-macos.html) |
| Manage users and access | Conditionally | An app-manager-scoped key *cannot*, by design. Degrade with a warning rather than failing. |

> **[TRAP]**

> **Symptom: the first TestFlight upload fails because no app record exists.** Unlike the other store, which binds a package on first upload, Apple needs the record created beforehand. Automate a lane that *verifies* the record rather than creating it: have it report which bundle identifier the key can see, and list every app it can see if the expected one is missing. That turns a confusing failure into a readable one.

> **[RULE]**

> **Any lane that mutates live App Store Connect state is dispatch-only, never scheduled.** Adding a tester sends a real invitation email to a real person. Pushing listing metadata changes a public page. These are outward-facing actions and they belong behind a deliberate human trigger.

<!-- chunk: ios.background | tags: background,plist,capabilities -->

## Background modes

iOS grants background execution as narrow, purpose-scoped capabilities that must be declared, justified in review, and designed around.

```xml
<key>UIBackgroundModes</key>
<array>
  <string>location</string>           <!-- continued location updates -->
  <string>bluetooth-central</string>  <!-- keep a BLE peripheral connected -->
  <string>fetch</string>              <!-- opportunistic background refresh -->
  <string>processing</string>         <!-- scheduled longer tasks -->
</array>
```

| Mode | What you actually get |
| --- | --- |
| `location` | Continued updates while a session is active. The status bar shows an indicator. Review will ask what it is for. |
| `bluetooth-central` | An established BLE connection survives backgrounding; state restoration can relaunch the app for a known peripheral. |
| `fetch` | Occasional short windows, scheduled by the OS on its own judgement. **Not** a timer. |
| `processing` | Longer tasks, typically while charging and idle. Also not a timer. |

> **[TRAP]**

> **Symptom: a background task that works reliably on Android fires unpredictably or not at all on iOS.** Background task scheduling on iOS is *advisory*. The OS decides, based on usage patterns, battery and charge state, and it deprioritises apps the user opens rarely — which is exactly the profile of a utility app. Design for "this will run sometimes, possibly not for a day" and make the foreground path authoritative. Never promise the user a background frequency you cannot guarantee.

> **[RULE]**

> **Every background capability must be justified in review, and a demo video is the most effective justification.** Reviewers cannot reproduce a Bluetooth-plus-background-location feature on a desk with no hardware. A short recording on a physical device, showing the feature and every permission prompt, converts a rejection into an approval. See [the playbook](#review).

<!-- chunk: ios.extensions | tags: widgets,extensions,app-groups -->

## Widget and share extensions

Each extension is a separate target with its own bundle identifier, its own provisioning profile, and its own entry in the match configuration.

| Concern | Detail |
| --- | --- |
| **App group** | The host↔extension data bridge. Enable the capability on *both* App IDs in the portal — no API for it. |
| **Shared storage** | A shared user-defaults suite keyed on the group id. Keep the payload small and pre-rendered — an extension has a tight memory budget and cannot run your whole app. |
| **Writing from Flutter** | Write the widget's data whenever the underlying value changes, not when the widget asks. The extension must never need to start your Dart runtime. |
| **Deep links from a widget** | A tap must route correctly whether the app is cold or warm. Test both — the cold path is the one that breaks. |
| **Adding the target** | Script it. Hand-editing the Xcode project file is error-prone and unreviewable; a script that adds the target and its sources is diffable and repeatable. |
| **Share extension** | Receives content from other apps. Declare the accepted types narrowly, and hand off to the host app rather than doing real work in the extension. |

> **[TRAP]**

> **Symptom: the widget shows placeholder data forever, or shows correct data that never updates.** Almost always the app group: either not enabled on both identifiers, or the suite name differs by a character between the Dart side and the Swift side. Log the resolved group identifier on both sides once and compare them — this is five minutes and it is otherwise an afternoon.

<!-- chunk: ios.privacy | tags: privacy,plist,compliance -->

## Privacy manifests and usage strings

Every permission needs a usage string, and those strings are read by reviewers and by users.

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Finds stations near you. Your position stays on the device.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Records your trip while the screen is off. Never shared.</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Connects to your adapter to read live data from the vehicle.</string>
<key>NSCameraUsageDescription</key>
<string>Scans codes and reads receipts. Images are processed on-device.</string>
```

> **[RULE]**

> **Write usage strings as one specific sentence plus, where true, the privacy guarantee.** "This app needs location access" is generic and invites a rejection asking what for. Naming the feature and stating that the data stays on the device answers the reviewer's question before it is asked.

Additionally, recent SDK requirements mean your app — and each third-party SDK that requires one — needs a **privacy manifest** declaring data collection and any required-reason API usage. A missing manifest is rejected at *upload*, not in review, which at least fails fast. Audit your dependency list against the required-reason list before a submission, and re-audit after any dependency bump.

<!-- chunk: ios.review | tags: app-review,rejection,compliance -->

## The review-rejection playbook

Three rejection grounds account for most of what a privacy-focused utility app with hardware features will encounter. All three are avoidable in advance.

### Guideline 5.1.1 — permission gating

> **[RULE]**

> **A pre-permission explainer screen must be Continue-only and must always proceed.** You may explain why you want a permission. You may not make the app unusable until it is granted. The screen gets one Continue button, and tapping it advances whether or not the user later grants anything. A "Grant / Cancel" pair where Cancel dead-ends is the exact shape that gets rejected.

### Guideline 3.1.1 — payments

> **[RULE]**

> **No links to external donation or purchase flows on iOS.** A donation link that is fine on other channels must be hidden in the iOS build. Implement it as a single visibility flag consulted by every surface that could render such a link, so adding a new surface cannot reintroduce the violation.

### Guideline 2.1 — demonstrate hardware features

> **[RULE]**

> **Supply a demo video with *every* submission when your app uses background location, Bluetooth, or any hardware a reviewer cannot exercise at a desk.** Apple's own wording is that updated demo videos will be needed for every submission — not once. Requirements: recorded on a **physical device**, showing the feature working end to end, and showing **every permission prompt** as it appears.

> Automate carrying the link. Keep it in a repository secret and append it to the review notes from the lane, so it ships with every build without anyone remembering:

> ```ruby
> BETA_REVIEW_NOTES_BASE =
>   "App uses anonymous auth on launch — no sign-in or account needed to " \
>   "use any feature. Free, ad-free, open-source.".freeze
>
> def beta_review_notes
>   video = ENV["DEMO_VIDEO_URL"]
>   return BETA_REVIEW_NOTES_BASE if video.nil? || video.strip.empty?
>   "#{BETA_REVIEW_NOTES_BASE} Demo video (physical iOS device, includes the " \
>   "background-location and Bluetooth flows with all permission prompts): " \
>   "#{video.strip}"
> end
> ```

> Degrade rather than fail when the secret is unset — a fork or a first run should still be able to build.

Two supporting practices: fill the beta review contact block from secrets and **never fabricate a phone number** (return nil and skip the field instead); and push localised beta review information ahead of the build with a no-build lane, so the first external build does not sit waiting for a form.

<!-- chunk: ios.checklist | tags: release,checklist -->

## Release checklist

| # | Check |
| --- | --- |
| 1 | Build number strictly exceeds the last uploaded one |
| 2 | Built with the current major SDK |
| 3 | Every signed target has a valid profile; app-group capability enabled on all of them |
| 4 | Every declared background mode is actually used, and justified in the notes |
| 5 | Every usage string is specific and current |
| 6 | Privacy manifest present, for the app and for every SDK that needs one |
| 7 | **A fresh demo video is recorded and linked**, on a physical device, showing every permission prompt |
| 8 | No external purchase or donation link is reachable in this build |
| 9 | Pre-permission screens are Continue-only and always proceed |
| 10 | Debug symbols archived; the commit tagged |
| 11 | App icon has no alpha channel (flatten it; the validator rejects transparency) |

> **[CHECK]**

> Before the first external build, run the no-build lane that pushes beta review information and confirm in the console that the contact block, the localised descriptions and the demo-video link are all present. Discovering a missing field after a build has been uploaded costs a full review cycle.

#### Sources for this page

- One project's iOS fastlane configuration: the match file with both signed targets and the CI-read-only rule, the `setup_ci` keychain fix and the incident that produced it, the repair lane for missing profiles, the localised beta review descriptions, and the demo-video link assembled from a repository secret.
- Its App Store rejection playbook covering guidelines 5.1.1, 3.1.1 and 2.1, and its note that app groups have no App Store Connect API endpoint.
- The other project's iOS workflow: the pinned runner image, the newest-stable Xcode requirement, the CocoaPods-under-active-Ruby fix, the SSH deploy key after token 403s, and the finding that an API key may not create an app record.

The background-mode table and the privacy-manifest requirement are standard platform behaviour, included because they constrain what the rest of the page can promise.
