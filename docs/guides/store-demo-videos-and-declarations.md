<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Email: demo videos + store declarations still outstanding (Apple & Google)

> This file is a ready-to-send email plus the reference material behind it.
> Copy everything between the `--- 8< ---` markers into your mail client, or
> send the whole file. The appendices after the email are the working detail
> the recipient will need while recording and filing.

---

## --- 8< --- BEGIN EMAIL --- 8< ---

**Subject:** Sparkilo — demo videos still needed for Apple *and* Google (background recording + Bluetooth), and the store forms they unblock

Hi,

Short version: **we owe three demo videos** — one to Apple, two to Google — and until they exist, two features that are already fully built stay switched off in production. Nothing here needs code. All of it needs a phone, a car or a bench setup with the OBD2 adapter, and about an hour of screen recording.

Below: what is missing, exactly what each video has to show, how to submit it, and the store configuration that goes with it.

---

### 1. Why the videos are the blocker

Both stores have the same problem with this app: **the two features that most need review approval are the two a reviewer cannot exercise at a desk.**

- **Background trip recording** — the app keeps recording GPS with the screen off.
- **Bluetooth / OBD2 auto-record** — the app holds a connection to the user's vehicle adapter and starts a trip when the engine comes on.

A reviewer sitting in an office with no car and no adapter cannot verify either one. Both stores' answer is the same: send a video. Apple asks for it under App Review guideline 2.1; Google asks for one per foreground-service type in the Play Console declaration form. Neither will approve on a written description alone.

---

### 2. What is missing — the three videos

| # | Store | Video | Length | Recorded on |
|---|---|---|---|---|
| **V1** | Apple | One combined demo covering background location **and** Bluetooth/OBD2, including every permission prompt | 2–4 min | **A physical iPhone.** Simulator recordings are rejected. |
| **V2** | Google | Foreground service type `location` — trip recording continues with the screen off | ≤ 30 s | Any Android device |
| **V3** | Google | Foreground service type `connectedDevice` — the app holds the OBD2 Bluetooth link and auto-starts a trip | ≤ 30 s | Android device **plus the adapter** |

**Apple's is the recurring one.** Their wording is that updated demo videos will be needed **for every app submission** — not once. So V1 is not a one-off task; it is something we re-record whenever the flows change. The good news is that the plumbing to carry it is already in place: the link lives in the `DEMO_VIDEO_URL` repository secret and the release lane appends it to the review notes automatically. Once you set the secret, every future submission carries it with no further action.

---

### 3. Shot lists

#### V1 — Apple (the big one)

Record on a physical iPhone, screen recording on, ideally with a short spoken or captioned narration. It must show **every permission prompt as it appears** — do not use a device where the permissions are already granted. Reset them first (Settings → General → Transfer or Reset → Reset → Reset Location & Privacy) or use a fresh install.

1. **Cold launch** — show the app opening with no account. Say: no sign-in required, anonymous by default.
2. **Location permission** — trigger a nearby search. Show our pre-permission explainer screen, then the iOS system prompt, then "While Using the App".
3. **A normal search working** — prices appearing, so the reviewer sees the core value.
4. **Start a trip recording** — Trips tab → start. Show the recording UI.
5. **Background location prompt** — show the iOS prompt asking to always allow, and our explanation of why.
6. **Lock the screen.** Wait visibly (10–15 s). Unlock. **Show the trip still recording with an increased distance/duration.** This is the single most important shot in the video.
7. **Bluetooth permission** — go to the OBD2/adapter screen. Show the system Bluetooth prompt.
8. **Pair and connect the adapter.** Show live telemetry arriving (fuel rate, RPM — whatever renders).
9. **Auto-record** — show the setting, and if you can stage it, show the app auto-starting a trip when the adapter comes into range.
10. **Stop the trip.** Show the saved trip with its data.
11. **Privacy close-out** — open the Privacy Dashboard, show export and delete-all. This pre-empts privacy questions.

#### V2 — Google, `location` foreground service (≤ 30 s)

1. Open the Trips tab.
2. Tap record / start.
3. Pull down the notification shade — **show the persistent recording notification**.
4. Lock the screen for a few seconds, unlock.
5. Show the trip still recording.
6. Stop the trip.

#### V3 — Google, `connectedDevice` foreground service (≤ 30 s)

1. Show the OBD2 adapter pinned in settings with auto-record enabled.
2. Start the engine / plug in the adapter.
3. **Show the notification appearing and the trip auto-starting.**
4. Show the auto-record toggle that disables it — reviewers want to see the user is in control.

---

### 4. Where to host them

| Store | Accepted | Notes |
|---|---|---|
| Apple | An **unlisted** link the reviewer can open in a browser | Unlisted YouTube or a direct file link. Must not require a login. Must stay live — Apple may re-check. |
| Google | Unlisted YouTube or a Drive link | Same rule: no login wall. |

Do **not** make them public/searchable — they show internal screens and adapter serials.

---

### 5. How to submit — Google Play

The Play side has a catch-22 that will waste an afternoon if you hit it cold, so read this before touching the console.

**The problem:** the Foreground services declaration form only appears in the console once an artifact that *declares* the foreground-service permissions exists in a track. But the publishing API **rejects** such an artifact with a 403 (`You must let us know whether your app uses any Foreground Service permissions`) until the form is filled. Form needs artifact; artifact needs form.

**The way out is a manual browser upload,** which the console accepts into a draft where the API would refuse.

1. Build a foreground-service-enabled bundle locally:
   ```bash
   flutter build appbundle --release --flavor play \
     --build-number=<a number above the last published one> \
     --dart-define=FGS_FORM_APPROVED=true
   ```
2. Play Console → **Test and release → Testing → Internal testing → Create new release** → upload
   `build/app/outputs/bundle/playRelease/app-play-release.aab`.
   **Save as draft.** It does not need to roll out to anybody.
3. Go to **Monitor and improve → App content**. A **Foreground services** task now appears, listing each declared type.
4. Fill it in — description and video link per type. Both descriptions are already drafted in
   `docs/guides/play-fgs-declaration.md`; copy them verbatim.
5. Submit for review. Turnaround is typically days.
6. **On approval:** set the repository variable `FGS_FORM_APPROVED=true`
   (Settings → Secrets and variables → Actions → Variables). That is the **only** switch — the next daily build ships the foreground service with no code or workflow change.
7. Discard the draft internal release if it is not needed.

**Important:** do **not** fill the separate *"Location in the background"* declaration. That one covers the `ACCESS_BACKGROUND_LOCATION` permission, which this app deliberately does not request — a foreground service started while the app is visible keeps GPS running on the ordinary "while in use" permission. Filling it would commit us to a permission we do not want and a stricter review.

---

### 6. How to submit — Apple

1. **Record V1** and upload it somewhere with a stable unlisted link.
2. **Set the repository secret** `DEMO_VIDEO_URL` to that link
   (`gh secret set DEMO_VIDEO_URL -R fdittgen-png/tankstellen`).
   From that moment the release lane appends it to the beta review notes on every submission automatically — that is the whole integration.
3. **Set `BETA_CONTACT_PHONE`** if it is not already set. The App Review contact phone is mandatory and the lane deliberately refuses to invent one — if the secret is empty, the contact block is skipped entirely and review will come back asking for it.
4. **Push the review information ahead of the build** so the first external build does not wait on a form:
   ```bash
   gh workflow run ios-beta-review.yml
   ```
5. **Ship the build:**
   ```bash
   gh workflow run ios-testflight.yml -f distribute=true
   ```
   `distribute=true` pushes it to the external group, which is what triggers Beta App Review. Internal-only builds skip review entirely.
6. For a **full App Store submission** (not just TestFlight), the same video link goes in App Store Connect → the version → **App Review Information → Notes**, along with the contact block.

---

### 7. Store configuration that goes with this

#### Google Play Console — outstanding

| Item | Where | State |
|---|---|---|
| **Foreground services declaration** | Monitor and improve → App content | **Blocked on V2 + V3.** The unblock for background recording. |
| Data safety | App content | Answers are drafted in `docs/play-store/DATA_SAFETY.md` — transcribe them into the form |
| Privacy policy URL | App content / Store settings | Must point at `https://fdittgen-png.github.io/tankstellen/privacy-policy/`. **Verify it resolves** — the docs site moved once and the console field does not follow automatically. |
| Content rating | App content | Questionnaire; straightforward for a utility app |
| Target audience & content | App content | Not directed at children |
| Ads declaration | App content | No ads |
| Store listing text/graphics | Grow → Store presence | Already automated — `play-store-listing.yml` publishes from `fastlane/metadata/android/`. Feature graphic must be **camelCase `featureGraphic.png`, exactly 1024×500**, or it is silently ignored. |
| Testers | Test and release → Testing | See §8 |

#### Apple App Store Connect — outstanding

| Item | Where | State |
|---|---|---|
| **Demo video link** | App Review Information → Notes (and the TestFlight beta review info) | **Blocked on V1.** Required with *every* submission. |
| App Review contact | Same screen | Needs `BETA_CONTACT_PHONE`; never fabricate it |
| Background modes justification | Review notes | Covered by V1 plus the notes the lane already generates |
| Privacy nutrition label | App Privacy | Derive from the same source as the Play data-safety answers so they cannot disagree |
| Privacy manifest | In the binary | Ours plus any SDK that needs one. A missing manifest is rejected **at upload**, so it fails fast. |
| Listing metadata | App Store → the version | Automated — `app-store-listing.yml` runs `deliver` from `ios/fastlane/metadata/`. Note Italian is locale `it`, **not** `it-IT`; `it-IT` is rejected. |
| App Groups capability | Developer Portal, **manually** | Must be enabled on both the app and the widget-extension App IDs. **There is no API for this** — portal only. |
| External tester group | TestFlight | See §8 |

#### Both — the compliance rules we already learned the hard way

- **Pre-permission screens are Continue-only and always proceed.** Never gate the app behind a grant. (This was a real 5.1.1 rejection.)
- **No external donation or purchase links in the iOS build.** Guideline 3.1.1. Ours are behind a visibility flag; keep it that way.
- **Verify the privacy-policy URL resolves** in both consoles before each submission.

---

### 8. Testers, while you are in there

- **Google Play:** the cleanest way to manage a closed-testing list is a **Google Group** — create one, add the group's email address as the tester list in Play Console → Testing → Closed testing → Testers, and from then on you manage membership in Google Groups rather than in the console. Members must join with the same Google account they use on their device.
- **Apple:** internal testers (≤ 100) get builds instantly with no review, but must be App Store Connect users first. External testers need no Apple account, but the first build to an external group goes through Beta App Review — which is precisely where V1 is needed. An external group can also have a **public link** with a tester cap, which is the closest equivalent to Play's opt-in URL.
- `gh workflow run ios-testers.yml -f email=someone@example.com` handles the Apple side idempotently.

---

### 9. Suggested order of work

1. Record **V2** and **V3** first — 30 seconds each, no car strictly required if you can bench the adapter, and they unblock the Google side which has the longer catch-22.
2. Do the Play manual-upload dance and file the Foreground services declaration.
3. Record **V1** — the long one. Reset permissions on the device first.
4. Set `DEMO_VIDEO_URL` and `BETA_CONTACT_PHONE`, run `ios-beta-review.yml`, then ship an external TestFlight build.
5. When Google approves: set `FGS_FORM_APPROVED=true` and run the on-device validation matrix on the next beta build.

Everything else — listings, metadata, screenshots — is already automated and does not need a human in the loop.

Shout if you want me to draft the exact text for any of the console fields; the two Play descriptions are already written and can be pasted straight in.

Best,
Florian

## --- 8< --- END EMAIL --- 8< ---

---

## Appendix A — copy-paste text for the Play declaration

These are the descriptions to paste into the Foreground services form, one per
declared type. They are reproduced from `docs/guides/play-fgs-declaration.md`,
which remains the authoritative source.

### Type `location`

**Use case (preset):** journey / trip tracking initiated by the user — pick the
closest preset, enter manually if none fits.

> When the user starts recording a drive (Trips tab → record button), the app
> tracks GPS position for the duration of that trip to compute distance, route
> and fuel consumption. Recording continues while the screen is off or the user
> switches apps; a persistent notification with the recording state is shown for
> the entire session and the service stops immediately when the user ends the
> trip in the app or from the notification.

### Type `connectedDevice`

**Use case (preset):** maintaining a connection to an external Bluetooth device
the user paired.

> The app maintains a Bluetooth connection to the user's OBD2 vehicle adapter
> during a recorded trip to read fuel-consumption telemetry. If the user enables
> hands-free auto-recording, a service watches for that specific paired adapter
> to come into range (engine start) to begin a trip automatically. A persistent
> notification is shown whenever the service runs, and the user can disable
> auto-recording at any time in settings.

---

## Appendix B — recording checklist

Applies to all three videos.

- [ ] **Physical device** (mandatory for Apple; strongly preferred for Google).
- [ ] Permissions **reset or freshly installed**, so every prompt is captured.
- [ ] Screen recording at device resolution; no cropping that hides the status bar
      (the location indicator in the status bar is evidence).
- [ ] Notification shade opened where the video needs to prove a persistent
      notification exists.
- [ ] Real data, not a demo dataset — a reviewer who spots placeholder content
      will ask about it.
- [ ] No personal data on screen: no real email address, no home address as the
      trip start, no adapter serial in shot.
- [ ] Uploaded **unlisted**, link tested in a private browser window with no login.
- [ ] Link recorded in the relevant secret / console field.

---

## Appendix C — the two switches, once approved

| Store | Approval | Switch | Effect |
|---|---|---|---|
| Google | Foreground services declaration approved | Repository **variable** `FGS_FORM_APPROVED=true` | The next `daily-beta` build ships the foreground service. No code change. |
| Apple | n/a — the video is per-submission | Repository **secret** `DEMO_VIDEO_URL` | Appended to the review notes on every subsequent submission automatically. |

After the Google switch is flipped, run the on-device validation matrix on the
resulting beta build before promoting it — the foreground service changes GPS
delivery behaviour and that is exactly the path worth re-verifying on real
hardware.

---

## Appendix D — channels that need none of this

- **F-Droid** — store policy does not apply; the libre build has shipped the
  foreground service since the gate was introduced.
- **Dev-APK sideloads** (`dev-apk.yml`) — never reviewed; always built with the
  foreground service. **Use these to validate the feature today**, before either
  store approval lands.
- **iOS background recording itself** — works via `UIBackgroundModes`
  (`location`, `bluetooth-central`) and needs no separate declaration form. Only
  the review-notes video is required.
