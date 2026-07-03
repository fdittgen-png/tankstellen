# Play Console "Foreground services" declaration — complete walkthrough (#3436)

This is the one human step standing between the app and full background trip
recording on Google Play. Everything else is already wired (#3434/#3435):
after this declaration is **approved**, set the GitHub repo variable
`FGS_FORM_APPROVED=true` (Settings → Secrets and variables → Actions →
Variables) and every Play build ships the foreground service — no code or
workflow edit.

## 1. Why this is called "foreground", not "background"

Android has no "record in background" permission. An app that keeps working
with the screen off runs a **foreground service**: a service the OS keeps
alive because it shows a **persistent notification**. That is exactly what
trip recording uses (`FOREGROUND_SERVICE_LOCATION` for GPS,
`FOREGROUND_SERVICE_CONNECTED_DEVICE` for the OBD2 auto-record watcher).
So in Play Console the relevant policy item is:

> **Play Console → (select the app) → Monitor and improve → App content
> (bottom of the left nav) → "Foreground services" declaration**

Do **NOT** fill the separate **"Location in the background"** declaration.
That one covers the `ACCESS_BACKGROUND_LOCATION` permission, which this app
deliberately does not request — a foreground service *started while the app
is visible* keeps GPS running in background on the normal "while in use"
location permission (#1498 stays parked).

## 2. Why the form is (probably) invisible right now

The App content task only appears once an artifact **declaring the FGS
permissions** exists in a track. Today's Play builds strip those permissions
(that is the point of the gate), and the upload **API** rejects an
FGS-declaring bundle with:

> `You must let us know whether your app uses any Foreground Service permissions` (403)

…until the declaration is done. The way out of the catch-22 is a **manual
browser upload**, which Play accepts into a draft release and then surfaces
the declaration task.

### Surfacing recipe

1. Build an FGS AAB locally (the keystore env vars are the same ones the CI
   workflows use):

   ```bash
   flutter build appbundle --release --flavor play \
     --build-number=<today+1, e.g. 2026070401> \
     --dart-define=FGS_FORM_APPROVED=true
   ```

2. Play Console → **Test and release → Testing → Internal testing →
   Create new release** → upload
   `build/app/outputs/bundle/playRelease/app-play-release.aab`.
   Save as **draft** — it does not need to roll out to anyone.
3. Go to **Monitor and improve → App content**. A "Foreground services"
   task now lists each declared FGS type. Fill it per section 3.
4. Submit for review. Approval is typically days, not weeks.
5. On approval: set the repo variable `FGS_FORM_APPROVED=true`, and the next
   `daily-beta` build ships the service. Run the #3439 validation matrix.

## 3. What to declare, per type

For each type Play asks: a description, a **video link** demonstrating the
feature (YouTube unlisted or Drive link works), and a use-case pick from a
preset list.

### `location`

- **Use case (preset):** journey/trip tracking initiated by the user
  (pick the closest preset; enter manually if none fits).
- **Description (copy-paste):**

  > When the user starts recording a drive (Trips tab → record button), the
  > app tracks GPS position for the duration of that trip to compute
  > distance, route and fuel consumption. Recording continues while the
  > screen is off or the user switches apps; a persistent notification with
  > the recording state is shown for the entire session and the service
  > stops immediately when the user ends the trip in the app or from the
  > notification.

- **Video shot list (≤30 s):** ① open the Trips tab, ② tap record/start,
  ③ show the persistent notification in the shade, ④ lock the screen for a
  few seconds, unlock, show the trip still recording, ⑤ stop the trip.

### `connectedDevice`

- **Use case (preset):** maintaining a connection to an external Bluetooth
  device the user paired.
- **Description (copy-paste):**

  > The app maintains a Bluetooth connection to the user's OBD2 vehicle
  > adapter during a recorded trip to read fuel-consumption telemetry. If
  > the user enables hands-free auto-recording, a service watches for that
  > specific paired adapter to come into range (engine start) to begin a
  > trip automatically. A persistent notification is shown whenever the
  > service runs, and the user can disable auto-recording at any time in
  > settings.

- **Video shot list (≤30 s):** ① show the OBD2 adapter pinned in settings
  with auto-record enabled, ② start the engine / plug the adapter, ③ show
  the notification appearing and the trip auto-starting, ④ show the
  auto-record toggle that disables it.

## 4. After approval — the full checklist

- [ ] Declaration approved in App content.
- [ ] Repo variable `FGS_FORM_APPROVED=true` set (this is the ONLY switch).
- [ ] Next daily-beta upload succeeds (the 403 disappears).
- [ ] #3439 on-device matrix run on the beta build.
- [ ] Discard the draft internal-track release if unused.

## 5. Channels that never needed any of this

- **F-Droid** — Play policy does not apply; ships the FGS since #3435.
- **dev-APK sideloads** (`dev-apk.yml`) — never reviewed by Play; always
  built with the FGS since #3435. Use these for validation *today*.
- **iOS** — background recording works via `UIBackgroundModes`
  (`location`, `bluetooth-central`); no declaration required.
