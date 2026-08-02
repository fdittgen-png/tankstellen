**12 · Device**

# NFC & RFID

> NFC has one design decision that dominates all the others: what your code does when it cannot read a tag. Get that wrong and you ship a surface where "I tapped my card and nothing happened" is unanswerable — which, on a wall-mounted tablet nobody can attach a debugger to, is the end of the investigation.

**Chunk prefix** nfc **Updated** 2026-08-01 **Depends on** 01 Foundations · 04 Robustness

#### On this page

1. [Platform reality](#reality)
1. [Three-state availability](#status)
1. [Session lifecycle on a long-lived kiosk](#session)
1. [UID normalisation as a credential contract](#uid)
1. [What an NFC UID is and is not](#security)
1. [Enrolment and revocation](#enrolment)
1. [Kiosk mode around the reader](#kiosk)
1. [NDEF versus raw UID](#ndef)
1. [Testing an NFC surface](#testing)

<!-- chunk: nfc.reality | tags: nfc,platform,capabilities -->

## Platform reality

NFC is an Android feature with an iOS asterisk, and for the tablet-on-a-wall use case it is Android only.

|   | Android | iOS | Desktop / web |
| --- | --- | --- | --- |
| Read a tag UID | Yes | iPhone 7+ with the Core NFC entitlement | No |
| Background tag dispatch | Yes — the OS can launch your app on a tap | Limited; background reads only on newer models, NDEF only | No |
| Continuous polling | Yes | **No** — each read is a modal, user-initiated session | No |
| Tablets | Common | **iPads have no NFC hardware at all** | — |
| Entitlement needed | A manifest permission | A provisioning-profile entitlement | — |

> **[RULE]**

> **For an always-on tap surface, target Android and hide the path everywhere else.** iOS cannot poll continuously — every read is a modal sheet the user must dismiss — and no iPad has the hardware. Treat every other platform as `unsupported` and hide the affordance rather than shipping a button that opens a sheet and does nothing.

```xml
<!-- Android -->
<uses-permission android:name="android.permission.NFC" />
<!-- required:false — the app must still install on devices without NFC -->
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

> **[TRAP]**

> **Symptom: the app is not installable on a large share of devices.** Declaring `android.hardware.nfc` without `required="false"` makes the store filter out every device with no NFC chip. Same for camera, Bluetooth and location hardware. Always declare optional hardware as optional and check availability at runtime.

<!-- chunk: nfc.status | tags: nfc,diagnostics,api-design -->

## Three-state availability

A boolean `isAvailable` is not enough. There are three distinct reasons a tap will not read, and each needs a different message, so the API must distinguish them.

```dart
/// The precise NFC state of THIS device. The kiosk sheet shows it so a
/// silent tap path is diagnosable at the wall.
enum NfcStatus {
  /// Adapter present and enabled — a session can read taps.
  ready,

  /// Adapter present but turned OFF in the device's system settings.
  off,

  /// No NFC here: non-Android platform, or no adapter hardware.
  unsupported,
}

class NfcUidReader {
  /// Resolved fresh on every call — the user can toggle NFC while the
  /// sheet is open, and a cached answer would be wrong.
  Future<NfcStatus> status() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return NfcStatus.unsupported;
    }
    try {
      return switch (await NfcManager.instance.checkAvailability()) {
        NfcAvailability.enabled  => NfcStatus.ready,
        NfcAvailability.disabled => NfcStatus.off,
        _                        => NfcStatus.unsupported,
      };
    } catch (e, st) {
      debugPrint('nfc availability check failed: $e\n$st');
      TraceLogger.instance
          .error('nfc', 'availability check failed', error: e, stackTrace: st);
      return NfcStatus.unsupported;
    }
  }
}
```

> **[WHY]**

> This comes directly from a field report: *"the RFID was not read"*, with no way to tell whether the tablet lacked the hardware, had NFC switched off in system settings, or had a session that failed to start. Three different problems, three different fixes, one indistinguishable symptom. The enum turns a support conversation into a glance at the screen.

| State | What the UI says | What it offers |
| --- | --- | --- |
| `ready` | "Hold the card to the back of the device." | The tap target, plus manual entry |
| `off` | "NFC is switched off in this device's settings — turn it on to read cards." | A button opening system NFC settings, plus manual entry |
| `unsupported` | Nothing about NFC at all | Manual entry only; the tap path is hidden entirely |

> **[RULE]**

> **Resolve the status fresh on every call, never cache it.** The user can toggle NFC in the notification shade while your sheet is open — which is exactly what they will do after reading your `off` message. A cached `off` would then persist and make your own instruction appear not to work.

<!-- chunk: nfc.session | tags: nfc,lifecycle,kiosk,robustness -->

## Session lifecycle on a long-lived kiosk

A wall tablet opens the same sheet hundreds of times a day, and each open must leave the reader in a known state — which means stopping before starting, and never letting a failed start pass silently.

```dart
/// Starts a read session; [onUid] fires with the normalised UID of the
/// first tag presented. Returns whether a session is actually up, so the
/// UI can say so rather than showing a tap icon over a dead reader.
Future<bool> startRead({required ValueChanged<String> onUid}) async {
  // A previous sheet's unawaited stop() may still be in flight on a
  // long-lived tablet — stop first, ourselves, unconditionally.
  await stop();
  try {
    await _startSession(onUid);
    return true;
  } catch (e, st) {
    debugPrint('nfc start failed, retrying: $e\n$st');
    TraceLogger.instance
        .error('nfc', 'start failed, retrying', error: e, stackTrace: st);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      await _startSession(onUid);
      return true;
    } catch (e, st) {
      TraceLogger.instance
          .error('nfc', 'start retry failed', error: e, stackTrace: st);
      return false;                      // caller MUST surface this
    }
  }
}
```

Four properties, each of which was added after a real failure:

| Property | The failure it prevents |
| --- | --- |
| **Stop before start, always** | A previous sheet's teardown still in flight leaves the adapter claimed and the new session fails |
| **One retry with a short delay** | The adapter needs a moment after a stop; a bare retry succeeds where an immediate start does not |
| **Returns a boolean** | The sheet used to show a tap icon over a dead reader forever. A start that can fail must report it. |
| **Traced at every step** | A wall tablet has no debugger. The trace log is the only forensic record. |

> **[RULE]**

> **Never show a tap affordance unless a session is confirmed running.** This is [honest degradation](04-robustness.html#honest) applied to a hardware surface: a tap icon is a promise that a tap will be read. If `startRead` returns false, show the failure and the manual-entry fallback — do not show the icon and hope.

Also stop the session on route pop, on app background, and on a successful read. An orphaned session on Android will intercept taps intended for another app.

<!-- chunk: nfc.uid | tags: nfc,uid,contract,normalisation -->

## UID normalisation as a credential contract

The tag UID is bytes. The moment it becomes a credential, its textual form is a contract between the reader, the storage layer and the server — so normalise it in exactly one place and write the rule down.

```dart
/// The badge credential contract, shared with the server-side
/// `register_nfc_badge` function: lowercase hex, no separators.
///   [0x04, 0xA2, 0x2B, 0x7C]  →  "04a22b7c"
String normaliseUid(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
```

> **[TRAP]**

> **Symptom: a card enrolled on one device is not recognised on another.** The same tag can be rendered as `04A22B7C`, `04:a2:2b:7c`, `04-A2-2B-7C`, or byte-reversed depending on the platform, the plugin version and the technology the tag was discovered under. If enrolment and verification use different formatters — or one of them was written before the other — the comparison silently never matches.

> **Countermeasures:** one normalisation function, called on both paths; the rule stated in a comment at the function *and* in the server-side function that stores it; and a unit test with real captured byte arrays asserting the exact expected string. Never compare raw byte lists across a network boundary.

> **[RULE]**

> **Store a hash, not the UID, if the credential is sensitive.** A UID is a bearer token for whatever it unlocks. If your threat model includes a leaked database, store a salted hash and compare hashes — the reader normalises and hashes, the server compares. You lose the ability to display "card ending 7c", which is usually an acceptable trade.

<!-- chunk: nfc.security | tags: security,threat-model,nfc -->

## What an NFC UID is and is not

A UID is an identifier, not an authenticator. Design the feature so that is acceptable, or use cryptographic tags.

| Property | Reality |
| --- | --- |
| Uniqueness | Usually, on genuine tags. Not guaranteed — some cards use random UIDs per session, and clones exist. |
| Cloneability | **Trivial.** Writable-UID cards and phone emulators are cheap and widely available. |
| Readable by others | Yes. Any phone can read the UID of a card in someone's pocket at close range. |
| Authentication strength | **None.** Comparable to knowing a username. |

> **[RULE]**

> **Match the mechanism to the consequence.** A UID is fine for a convenience action in a semi-trusted physical space — checking in at a desk, logging an activity — where the worst case is a nuisance and the space itself provides the real access control. It is *not* fine for unlocking a door, authorising a payment, or anything an attacker would spend five minutes to defeat. For those, use a tag with mutual authentication and a proper key hierarchy, or a different mechanism entirely.

Compensating controls that are cheap and worth having even for low-stakes uses:

- **Bind the tap to a physical context.** A kiosk in a known location constrains who can tap; a phone in a pocket does not.
- **Make the action auditable and visible.** The person whose badge was used should see the resulting event, so misuse is noticed.
- **Make it reversible.** A check-in can be undone; a payment cannot.
- **Rate-limit per badge.** Twenty taps a minute is not a person.
- **Allow instant revocation** — see below.

<!-- chunk: nfc.enrolment | tags: nfc,enrolment,admin -->

## Enrolment and revocation

Enrolment is an administrative action performed on a trusted device: an authorised user opens a member's record, taps the card, and the normalised UID is stored against that member.

| Requirement | Detail |
| --- | --- |
| **Authorised roles only** | Enforced server-side in the registration function, not by hiding the button. See [page 07](07-supabase.html#rpc). |
| **One badge per person, per space** | A unique index on the normalised UID within the tenant. Enrolling an already-registered card must fail with a named error, not create a duplicate. |
| **Show what was read** | Display the normalised UID during enrolment so the operator can confirm the right card was tapped. |
| **Instant revocation** | Removing a badge takes effect on the next tap. If the kiosk caches a badge list for offline operation, that cache needs a short TTL and a revocation push. |
| **Manual alternative** | An operator on a device without NFC must still be able to type a UID. Otherwise enrolment is blocked by hardware. |
| **Audit the enrolment** | Who enrolled which badge for whom, and when. Badge assignment is a privilege grant. |

> **[TRAP]**

> **Symptom: a revoked badge keeps working at the kiosk.** An offline-capable kiosk that caches the badge list will honour a revoked badge until the cache expires. Decide explicitly: either the kiosk requires connectivity for a tap (simple, correct, fails when the network does), or it caches with a short TTL and you accept a bounded revocation window — and you write that window into the admin UI so nobody assumes revocation is instant when it is not.

<!-- chunk: nfc.kiosk | tags: kiosk,android,ux -->

## Kiosk mode around the reader

A tap surface usually lives inside a kiosk mode — a restricted state on a shared device — and that has its own requirements independent of NFC.

- **Entering kiosk mode is authenticated; leaving it is too.** A device PIN held separately from user credentials is the usual shape, so an operator can lock the tablet into the surface and only they can unlock it.
- **No navigation out.** No back affordance to the rest of the app, no deep links accepted, no share sheet.
- **No personal data on screen at rest.** The idle state shows the space, not a member. A name appears only in direct response to that member's own tap, and clears on a timer.
- **Auto-return to idle.** Every screen returns to the tap prompt after a short timeout, so the last user's result is not left visible.
- **Keep the screen on, and handle the reboot.** A wall tablet needs a wake lock, and needs to come back into kiosk mode after a power cut without an operator present.
- **Show the diagnostic state.** The three-state NFC status, connectivity, and the last successful sync — small, in a corner. This is what makes a remote support call possible.

> **[WHY]**

> A kiosk is a screen in a shared room. Anything it displays is displayed to everyone who walks past, indefinitely. The default state must therefore be information-free, and every transient state must expire on its own — you cannot rely on the user to navigate away, because the interaction model is "tap and walk off".

<!-- chunk: nfc.ndef | tags: nfc,ndef,tags -->

## NDEF versus raw UID

Two ways to use a tag, with different trade-offs.

|   | Raw UID | NDEF payload |
| --- | --- | --- |
| Works with | Any tag, including existing access cards | Tags you write yourself |
| Setup | Enrol the card the user already carries | Write each tag before deployment |
| Content | An identifier only | A URI, text, or your own record type |
| Background launch | Limited | The OS can launch your app from a URI record |
| iOS support | Weaker | Better — NDEF is the supported path |
| Tamper resistance | UID is factory-set on genuine tags | Payload is rewritable unless locked |

Use raw UIDs when people already carry cards you want to reuse. Use NDEF with a URI record when you are deploying tags yourself and want a tap to open your app at a specific place — a tag on a desk, a machine, a shelf. The URI should be the same deep link your [QR payload](11-barcode-qr.html#payload) uses, so one handler serves both.

> **[RULE]**

> **Lock NDEF tags after writing them if they are deployed in public.** An unlocked tag can be rewritten by anyone with a phone, turning your desk label into a link to anywhere. Locking is irreversible, so verify the payload before you lock — and keep a spare.

<!-- chunk: nfc.testing | tags: testing,nfc,fakes -->

## Testing an NFC surface

No emulator has an NFC radio. Everything above the reader is testable; the reader itself needs an injectable seam and a hardware checklist.

```dart
abstract class NfcReader {
  Future<NfcStatus> status();
  Future<bool> startRead({required ValueChanged<String> onUid});
  Future<void> stop();
}

class FakeNfcReader implements NfcReader {
  FakeNfcReader({this.state = NfcStatus.ready, this.startSucceeds = true});

  NfcStatus state;
  bool startSucceeds;
  ValueChanged<String>? _sink;
  int startCount = 0, stopCount = 0;

  @override
  Future<NfcStatus> status() async => state;

  @override
  Future<bool> startRead({required ValueChanged<String> onUid}) async {
    startCount++;
    if (!startSucceeds) return false;
    _sink = onUid;
    return true;
  }

  @override
  Future<void> stop() async { stopCount++; _sink = null; }

  /// Test-only: simulate a card being presented.
  void tap(String uid) => _sink?.call(uid);
}
```

> **[CHECK]**

> Six widget tests that cover the whole surface: **(1)** `ready` shows the tap affordance; **(2)** `off` shows the settings hint and hides the tap icon; **(3)** `unsupported` hides the NFC path entirely and shows manual entry; **(4)** a failed start surfaces an error rather than a tap icon; **(5)** a tap with a known UID performs the action; **(6)** a tap with an unknown UID shows a clear "card not recognised" and keeps the session open.

Plus a unit test for [normalisation](#uid) against real captured byte arrays, and a short hardware checklist per release: enrol a card, tap it, tap an unknown card, revoke and re-tap, toggle NFC off mid-session, and reboot the kiosk device.

#### Sources for this page

- One project's `NfcUidReader`: the three-state `NfcStatus` enum with its field-report rationale, the stop-before-start plus one-retry session logic, the boolean return so a dead reader is surfaced, the lowercase-hex-no-separators UID contract shared with the server-side registration function, and the Android-only platform gate.
- The same project's kiosk feature: the device PIN, the kiosk gate screen, and the RFID/NFC badge feature toggle whose description states the Android + NFC hardware requirement.

The security assessment of UIDs, the enrolment requirements table and the NDEF comparison are general domain knowledge rather than observations from either project. The fake-reader code is illustrative.
