**21 · Runtime**

# Background execution & always-visible UI

> Two opposite problems that turn out to be the same problem. Running with the app *not* visible, and keeping something visible when the user is doing something else, are both requests for an exemption from the normal application lifecycle — and every operating system grants them narrowly, on conditions, and revokes them without warning.

**Chunk prefix** bg **Updated** 2026-08-01 **Depends on** 13 Android · 14 iOS · 10 Bluetooth

#### On this page

1. [What each platform actually allows](#matrix)
1. [Android: the foreground service](#android-fgs)
1. [Android: batching, Doze and OEM killers](#android-throttle)
1. [iOS: background modes and their limits](#ios-bg)
1. [F-Droid and push without proprietary services](#fdroid-bg)
1. [One flag for the whole feature](#gate)
1. [Keeping the screen on](#screen-on)
1. [Pinning the app in the foreground](#pinning)
1. [Small always-visible tiles](#tiles)
1. [Testing background behaviour](#testing)

<!-- chunk: bg.matrix | tags: background,platform,capabilities -->

## What each platform actually allows

Start here, because the honest answer constrains the feature you can design.

| Capability | Android (store) | Android (libre) | iOS | Desktop |
| --- | --- | --- | --- | --- |
| Continuous GPS with the screen off | Yes, with a foreground service **+ an approved declaration** | Yes, no declaration needed | Yes, with the `location` background mode | Yes, app just keeps running |
| Hold a Bluetooth link in background | Yes, foreground service + declaration | Yes | Yes for BLE, `bluetooth-central`; **no** classic RFCOMM | Yes |
| Sustained CPU work in background | Yes, inside the service | Yes | **No** — short windows only | Yes |
| Wake on a schedule | Yes, deferred and batched | Yes | Advisory only; the OS decides | Yes |
| Wake on a device appearing | Yes, scan with a pending intent | Yes | BLE state restoration for a known peripheral | n/a |
| Relaunch after reboot | Yes, boot receiver | Yes | **No** | Login item |
| Push without a proprietary service | Store push, or self-hosted | **Self-hosted only** | Apple push (the only option) | n/a |
| Store paperwork | A per-type declaration **with a video** | None | Justification in review, usually a video | None |

> **[RULE]**

> **Design the feature to degrade to foreground-only, and say so in the interface.** Background execution is a privilege granted by two operating systems and two review teams, any of which can narrow it in a future version. A feature that is worthless without it is a feature built on someone else's policy. Recording that continues in the background and *also* works while you watch it is resilient; recording that only exists in the background is a liability.

> **[WHY]**

> The operating-system restrictions are identical — it is the same Android. What differs is store *policy*: a catalog that reviews for freedom rather than for background-usage justification imposes no declaration. This has a practical consequence worth exploiting: a sideloaded or libre build can validate the whole background feature **today**, while the store declaration is still in review. Do not wait on paperwork to test your own code.

<!-- chunk: bg.android-fgs | tags: foreground-service,android,notification -->

## Android: the foreground service

Android has no "run in the background" permission. What it has is a **foreground service**: a service the system keeps alive because it displays a persistent notification. The name is confusing and the mechanism is the entire background story.

| Type | Permission | Use |
| --- | --- | --- |
| `location` | `FOREGROUND_SERVICE_LOCATION` | Trip or activity recording the user started |
| `connectedDevice` | `FOREGROUND_SERVICE_CONNECTED_DEVICE` | Holding a link to a paired Bluetooth device |
| `dataSync` | `FOREGROUND_SERVICE_DATA_SYNC` | A user-initiated upload or sync |
| `mediaPlayback` | `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Audio |

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />

<service
    android:name=".autorecord.RecordingForegroundService"
    android:foregroundServiceType="location|connectedDevice"
    android:exported="false" />
```

> **[WHY]**

> A foreground service **started while the app is visible** keeps receiving location updates on the ordinary *while in use* permission. You do not need `ACCESS_BACKGROUND_LOCATION` unless the app must locate the user when it has never been opened. Skipping it avoids a separate and stricter store declaration, avoids a permission a large share of users refuse, and materially improves your privacy declaration. One project deliberately does not request it and documents that decision next to the manifest entry — worth copying, including the comment.

Notification requirements that are not optional:

- It must appear promptly after the service starts and remain for the whole session.
- It must be **localised** — it is user-facing text and falls under the same rule as everything else.
- It should carry a stop action, so the user can end the session without opening the app.
- It should show live state (elapsed time, distance), because a static notification reads as stuck.

> **[RULE]**

> **The service stops the instant the user ends the session** — from the app or from the notification. A foreground service that outlives its purpose is the single most common cause of a battery complaint, and store vitals will flag it before your users do.

<!-- chunk: bg.android-throttle | tags: doze,battery,oem,throttling -->

## Android: batching, Doze and OEM killers

> **[TRAP]**

> **Symptom: location and sensor callbacks arrive in bursts roughly every five seconds once the screen is off, instead of continuously.** Android batches background delivery aggressively to save power. A foreground service is the documented lever that restores continuous delivery — which is why a feature can look correct in the foreground and produce a coarse, gappy track in the background.

> **Countermeasures:** request the foreground service for the duration of the session; ask the location client for the cadence you actually need rather than accepting defaults; and, on the analysis side, treat gaps as expected — interpolate and mark the segment rather than assuming the user teleported.

Beyond the platform, several manufacturers add their own aggressive process management that ignores the standard rules.

| Layer | Effect | What you can do |
| --- | --- | --- |
| **Doze / app standby** | Defers work when the device is idle | A foreground service is exempt while it runs |
| **Battery optimisation** | Restricts background work per app | You may *request* an exemption — do it only when the user enables the feature, with an explanation, and never at launch |
| **OEM process killers** | Kill the app regardless of a foreground service | Nothing programmatic. Detect the manufacturer and link the user to the relevant setting. |
| **"Remove permissions if unused"** | Revokes permissions for apps unopened for months | Ask the user to exempt the app if it is genuinely a background-first tool |

> **[RULE]**

> **Detect an interrupted session and recover rather than pretending it did not happen.** Persist a session marker at start; on the next launch, if the marker is present and no clean stop was recorded, you were killed. Offer to resume or to save what was captured — and make sure those buttons actually work, which is [the affordance-test rule](03-tdd-and-testing.html#bugfix): one project shipped exactly this recovery banner with two silent no-op buttons because the recovery path left the controller null.

> **[CHECK]**

> Test the kill path explicitly: start a session, then `adb shell am kill <package>`, then relaunch. You should get the recovery offer, and taking it should produce a usable result. This is a two-minute test that covers the most common real-world failure of any recording feature.

<!-- chunk: bg.ios-bg | tags: ios,background-modes,limits -->

## iOS: background modes and their limits

```xml
<key>UIBackgroundModes</key>
<array>
  <string>location</string>           <!-- continued location updates -->
  <string>bluetooth-central</string>  <!-- keep a BLE peripheral connected -->
  <string>fetch</string>              <!-- opportunistic refresh -->
  <string>processing</string>         <!-- longer scheduled tasks -->
</array>
```

| Mode | Reliable? | Reality |
| --- | --- | --- |
| `location` | **Yes**, while a session is active | The status bar shows an indicator. This is the dependable one. |
| `bluetooth-central` | **Yes** for an established connection | State restoration can relaunch the app for a known peripheral |
| `fetch` | **No** | Occasional short windows chosen by the OS. Not a timer. |
| `processing` | **No** | Typically while charging and idle. Also not a timer. |
| Significant location change | Mostly | Coarse, event-driven; can relaunch a terminated app. Good for "did the user start driving", useless for a track. |

> **[TRAP]**

> **Symptom: a background task that runs like clockwork on Android fires unpredictably or not at all on iOS.** Background task scheduling on iOS is *advisory*. The system decides based on usage patterns, battery and charge state, and it deprioritises apps the user opens rarely — precisely the profile of a utility app. Design for "this will run sometimes, possibly not for a day", make the foreground path authoritative, and never promise the user a background frequency.

> **Corollary for alerting features:** if you need a guaranteed delivery latency on iOS, the only mechanism that provides it is a push from your own server. Background fetch will not do it, and building a feature that assumes otherwise produces a promise you cannot keep.

Two further iOS realities worth stating plainly: there is **no launch-at-boot**, so a session cannot resume automatically after a restart; and **classic Bluetooth is unavailable** for arbitrary devices, so a dongle that only speaks serial profile has no iOS story at all.

<!-- chunk: bg.fdroid | tags: fdroid,push,unifiedpush,libre -->

## F-Droid and push without proprietary services

The libre build has the same OS-level capabilities and no store-policy layer — but it also has no proprietary push service, which changes how anything server-initiated has to work.

| Need | Store build | Libre build |
| --- | --- | --- |
| Background recording | Foreground service + approved declaration | Foreground service, shipped unconditionally |
| Scheduled local work | The platform work scheduler | Identical — it is not a proprietary component |
| Server-initiated notification | The store's push service | **A self-hosted or federated push protocol** |
| Local notifications | Platform API | Identical |

> **[RULE]**

> **If a channel forbids the proprietary push service, adopt an open push protocol rather than dropping the feature.** A distributor-based protocol — where the user runs or chooses a push distributor app and your app registers an endpoint with it — gives server-initiated notifications with no proprietary dependency. One project ships exactly this. The trade is that the user must have a distributor installed, so detect its absence and degrade to polling with an explanation rather than silently never notifying.

> **[WHY]**

> If one channel has reliable push, one has an optional distributor, and iOS has push but no reliable background fetch, then a design that assumes uniform delivery is wrong on at least two of the three. The workable shape is a *tiered* one: an on-device evaluation loop that runs whenever the app is alive or a foreground service is running, plus push where it is available as an accelerator. State the delivery expectation per channel in your own documentation so nobody promises a latency the channel cannot meet.

<!-- chunk: bg.gate | tags: feature-flag,build,lockstep -->

## One flag for the whole feature

Background execution touches Dart code, the manifest and store paperwork. Those three must never disagree, so drive all of them from a single build-time flag.

```bash
flutter build appbundle --release --flavor play \
  --dart-define=FGS_FORM_APPROVED=true
```

| Half | What the flag does |
| --- | --- |
| **Dart** | A compile-time constant turns true, so the recorder requests the foreground service |
| **Gradle** | The flavor manifest swaps to an overlay that declares the permissions and the service |

```kotlin
// Flutter forwards --dart-define to Gradle as a comma-separated list of
// base64 "KEY=VALUE" entries. Decoding it lets ONE flag flip both halves.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { runCatching {
            String(Base64.getDecoder().decode(it)).split("=", limit = 2)
                .let { p -> if (p.size == 2) p[0] to p[1] else null }
        }.getOrNull() }
        ?.toMap() ?: emptyMap()

val fgsApproved = (dartDefines["FGS_FORM_APPROVED"]
    ?: System.getenv("FGS_FORM_APPROVED") ?: "false")
    .let { it.equals("true", true) || it == "1" }

sourceSets {
    getByName("play").manifest.srcFile(
        if (fgsApproved) "src/play/AndroidManifestFgsApproved.xml"
        else             "src/play/AndroidManifest.xml")
}
```

> **[RULE]**

> **The default build must ship with zero foreground-service permissions**, so an upload can never be rejected while the declaration is pending. Add an audit script that asserts this and run it in CI — a gate that can silently regress is not a gate. After approval, one repository variable flips it for every subsequent build with no code change.

The libre flavor takes the overlay unconditionally: no store policy applies there, so there is nothing to gate.

<!-- chunk: bg.screen-on | tags: wakelock,screen,driving-mode -->

## Keeping the screen on

The opposite requirement: the app is visible and must *stay* visible — a driving view, a kiosk, a live dashboard.

```dart
/// A facade so the platform call has a seam for tests, and so the
/// enable/disable calls are reference-counted rather than racing.
class WakelockFacade {
  int _holders = 0;

  Future<void> acquire() async {
    if (_holders++ == 0) await WakelockPlus.enable();
  }

  Future<void> release() async {
    if (--_holders <= 0) {
      _holders = 0;
      await WakelockPlus.disable();
    }
  }
}
```

> **[RULE]**

> **Reference-count the wake lock and release it on every exit path.** Two screens that both want the screen on will otherwise fight: the second to disable turns it off while the first still needs it. And a wake lock left held after the user leaves the screen drains the battery until the app is killed — which store vitals will report as an excessive-wake-lock warning, a metric that affects your listing.

Scope it tightly. Hold it while a recording session is active or a driving view is on screen; release it on pause, on navigation away, and in `dispose`. Make it a user-visible setting if the feature is long-running — some people will want the screen to sleep even during a session.

<!-- chunk: bg.pinning | tags: screen-pinning,kiosk,lock-task -->

## Pinning the app in the foreground

Two different things get called "pinning", and they have very different scopes.

|   | User-initiated screen pinning | Managed lock-task mode |
| --- | --- | --- |
| Who enables it | The user, from the recents view | A device owner / management profile |
| Setup | Enable it once in system settings | Device provisioning |
| Exit | A gesture, optionally requiring the device PIN | Only the app or the administrator |
| Survives reboot | No | Yes |
| Right for | Handing your phone to someone; a temporary kiosk | A permanently dedicated device |
| iOS equivalent | **Guided Access** — user-enabled, accessibility setting | Supervised-device single-app mode |

> **[RULE]**

> **Build your own in-app kiosk mode rather than depending on OS pinning.** OS pinning is a user setting you cannot enable programmatically without device-owner privileges, and it is unavailable or differently-named on iOS. What you *can* control is your own app: a mode entered and left with a separate device PIN, with no navigation out, no deep links accepted, no share sheet, an idle timeout back to a neutral screen, and a wake lock held for the duration. Then OS pinning becomes an optional hardening step the operator may add, not a dependency.

The kiosk rules that matter most, all of which follow from the screen being in a shared room: the idle state must show no personal data; every transient state must expire on its own, because the interaction model is "tap and walk away"; and a small corner should show diagnostic state — connectivity, hardware availability, last sync — because that is what makes remote support possible. See [page 12](12-nfc-rfid.html#kiosk).

<!-- chunk: bg.tiles | tags: picture-in-picture,live-activity,widget,overlay -->

## Small always-visible tiles

When the user is doing something else but still needs a glanceable readout, there are four mechanisms and they are not interchangeable.

| Mechanism | Platform | Shows | Good for |
| --- | --- | --- | --- |
| **Picture-in-picture** | Android | A small floating window over other apps, resizable, with actions | A live readout while the user navigates elsewhere |
| **Live Activity** | iOS | Lock screen and the dynamic island | The iOS analogue of PiP for status, though it is not an interactive window |
| **Persistent notification** | Both | Shade / lock screen, with actions | The universal fallback. Free with a foreground service. |
| **Home-screen widget** | Both | The home screen, refreshed periodically | Glanceable state when the app is not running at all |

### Picture-in-picture, in practice

PiP is what most people mean by "keep it visible as a small tile". It is an Android activity mode: the activity enters PiP, the system shrinks it into a floating window, and it keeps rendering.

```xml
<activity
    android:name=".MainActivity"
    android:supportsPictureInPicture="true"
    android:resizeableActivity="true"
    android:configChanges="screenSize|smallestScreenSize|screenLayout|orientation" />
```

| Design point | Detail |
| --- | --- |
| **Design for the small size, not a scaled-down screen** | A PiP window is roughly a business card. One large number and one label. A shrunk full screen is unreadable. |
| **Make the content context-adaptive** | One project's driving overlay shows live consumption when telemetry is available, distance when it is GPS-only mid-trip, and elapsed time during the pre-roll — one slot, the most useful value for the current state. |
| **Allow a mode flip** | The same overlay flips to a large price layout when the driver comes within a station's radius. A tile that changes at the right moment is far more valuable than one that shows one thing forever. |
| **Handle the lifecycle** | Entering PiP is a configuration change. Nothing may reinitialise, and the underlying session must be unaffected. |
| **Provide a way back** | Tapping the window restores the app. Make that obvious. |

> **[RULE]**

> **Ship a way to test the tile without reproducing its trigger.** An overlay that only appears when you are driving within a certain distance of something is nearly untestable — so add a control that pushes a synthetic trigger for thirty seconds. One project has exactly this in its privacy dashboard, and it converted an "only verifiable in a moving car" surface into one anyone can check from a desk. This is a general principle: any state that requires the physical world to reach deserves a synthetic entry point.

### Live Activities and widgets

A Live Activity is a separate iOS extension target with its own timeline, updated from the app or by push. Treat it like the widget: keep the payload small and pre-rendered, write it whenever the underlying value changes, and never require the extension to start your Dart runtime.

For home-screen widgets, three things break most often: the shared storage identifier differing by a character between the two languages; the tap deep link failing on a cold start while working warm; and the refresh path assuming the app is running. Log the resolved shared-storage identifier on both sides once and compare — five minutes that otherwise costs an afternoon. See [page 14](14-ios.html#extensions).

<!-- chunk: bg.testing | tags: testing,background,validation -->

## Testing background behaviour

Almost none of this is reachable from a widget test. Split it into what is testable and a short device checklist for what is not.

| Layer | How |
| --- | --- |
| Session state machine | Unit tests: start, pause, interrupt, recover, stop |
| Interrupted-session recovery | Unit test the marker logic; widget-test the recovery banner and **tap both its buttons** |
| Wake-lock reference counting | Unit test the facade: two acquires, one release, still held |
| Gap handling in the analysis | Unit tests over recorded traces with deliberate gaps |
| The default manifest carries no service permissions | An audit script in CI |
| Everything else | The device checklist below |

> **[CHECK]**

> Per release, on real hardware, for any background feature. Roughly twenty minutes and it covers what no automated test reaches.

1. Start a session; lock the screen for five minutes; unlock — **is the data continuous or gapped?**
1. Start a session; switch to another app for five minutes; return.
1. Start a session; open the PiP tile; use another app; confirm it updates.
1. Start a session; kill the app (`adb shell am kill`); relaunch — **is recovery offered, and does taking it work?**
1. Start a session; toggle the relevant radio off and on mid-session.
1. Start a session; let the battery saver engage.
1. Stop from the notification rather than from the app.
1. Reboot mid-session (Android) — confirm the state is sane afterwards.
1. On a device from a manufacturer with aggressive process management, repeat steps 1 and 4.

> **[RULE]**

> **Validate on a build that actually contains the fix, and check the build number first.** Both projects record background-layer fixes marked "needs on-device validation" that sat unvalidated across releases. A green CI run cannot observe a radio or a doze transition. And when someone reports a background feature still broken, the first question is which build they are on — a stale testing-channel build is the most common answer.

#### Sources for this page

- One project's foreground-service work: the two declared types with their permissions, the single build-time flag decoding dart-defines in Gradle to swap the manifest overlay, the default-zero-permissions guard with its audit script, and the documented decision not to request background location because a foreground service started while visible does not need it.
- Its driving-mode picture-in-picture overlay — the context-adaptive primary readout, the flip to a large price layout on approach, and the synthetic thirty-second test trigger in the privacy dashboard — plus its wake-lock facade and Live Activity coordinator.
- Its recorded background-batching symptom, its interrupted-session recovery banner (including the incident where both recovery buttons were silent no-ops), and its note that sideloaded and libre builds can validate the feature while the store declaration is pending.
- The other project's adoption of a distributor-based open push protocol in place of a proprietary push service, for a build that must stay free of it.

The OEM-process-killer row and the pinning comparison are general platform knowledge. The wake-lock facade snippet is an illustrative reconstruction of the described reference-counting behaviour.
