<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0026: What iOS recording promises — the supported lifecycle, and the keychain accessibility it costs (#4357)

**Status:** Accepted
**Date:** 2026-09-20

## Context

Trip recording on iOS has never had a written contract. The platform
foundations are in place — `bluetooth-central` + `location` background
modes (`ios/Runner/Info.plist`), the Core Bluetooth state-restoration
bridge (`ios/Runner/AppDelegate.swift`), and `automotiveNavigation`
location settings with `allowBackgroundLocationUpdates: true` and
`pauseLocationUpdatesAutomatically: false`
(`lib/core/location/recording_location_settings.dart`) — but "the
foundations exist" is not the same as "here is what happens when the
user locks the phone", and support answers, release copy and the test
suite were each guessing separately.

Two concrete seams made that guessing expensive.

**The keychain.** `HiveCipherLoader` reads the AES key for every
PII-bearing Hive box out of `FlutterSecureStorage`. The active-trip box
— the WAL meta row a running recording writes — is one of them. The
plugin's iOS default accessibility is `kSecAttrAccessibleWhenUnlocked`:
readable **only while the screen is unlocked**. A trip recorded with the
screen off, or a background relaunch performed by Core Bluetooth state
restoration, therefore asks for its own storage key and is refused. And
the answer to that refusal used to be indistinguishable from the answer
to a genuinely lost key — which matters enormously, because acting on an
absent key means minting a replacement and opening the boxes with it,
and Hive's crash recovery answers an undecryptable box by **truncating
it to zero bytes, silently** (#4118, measured at 93 bytes in, 0 out).

**The WAL.** `ActiveTripSampleWal.append` writes through an `IOSink`,
whose only channel for a write failure is its `done` future. Nothing
read that future. A protected-data refusal, a full disk or a deleted
container left the WAL reporting `isWritable: true` with a climbing
`appendedCount`, and the repository stripped those samples out of the
Hive snapshot row on the strength of that answer. That is
unacknowledged buffering labelled durable.

**Restoration identity.** `willRestoreState:` hands back whatever
peripherals the OS was holding. Nothing compared those UUIDs against the
trip that was actually running, so an early callback was dropped, a
duplicate acted on twice, a late one could revive a stopped trip, and a
foreign adapter (a shared garage ELM327, a previously paired car) could
be adopted by a trip it has nothing to do with.

## Decision

### 1. The supported lifecycle

One row per transition. "What the app does" is the contract; "Evidence"
says how it is known — **CI** is proven by a test in this repository,
**device** is pending the #4357b / S10 physical matrix and is *not*
claimed here.

| Transition | What the app does | What the user sees | Evidence |
|---|---|---|---|
| **Leaves the recording form** (navigates elsewhere in the app) | Nothing changes. Acquisition, the WAL and the trip identity are owned by the session, not by the screen. Re-entering the form never starts a second controller. | The trip keeps running; returning shows it where it was. | CI |
| **App backgrounded** (home gesture, another app) | Core Location keeps delivering under `allowBackgroundLocationUpdates` + the `location` background mode; the BLE link stays with `bluetooth-central`. Samples keep appending to the WAL. | The recording continues; iOS shows its own location indicator. | CI for the WAL/session half; **device** for actual delivery cadence |
| **Device locked** (screen off, process alive) | Same as backgrounded. From #4357 the Hive key is readable while locked, so the snapshot/meta row keeps being written. | Recording continues; unlocking shows an unbroken trip. | **device** — this is the acceptance case S10 owns |
| **OS suspension** (system reclaims CPU) | Best effort only, via Core Location background delivery and Core Bluetooth events. No promise of continuous Dart execution; gaps are recorded as gaps, never interpolated. | Possible delivery gaps, shown as gaps. | **device** |
| **OS termination** (memory pressure) | Core Bluetooth state restoration may relaunch the app in the background. **Recovering the recorded data is the promise; continuous sampling is not.** A restored peripheral binds only to the current or recoverable trip identity — a conflicting one is refused. | The trip is offered for recovery with an explicit interruption boundary. | CI for restoration ordering + identity fencing; **device** for the relaunch itself |
| **User force-quit** (swipe from the app switcher) | Nothing. iOS withdraws state restoration for a force-quit, by design; no relaunch, no background work. Whatever reached the WAL is recovered on the next manual launch. | On next launch, the interrupted trip is offered for recovery. | CI for the recovery read; **device** to distinguish it from OS termination |

Two invariants cut across every row: **Stop is authoritative** — a
queued restoration event or source callback after Stop, consent
withdrawal or a superseding session is refused, never adopted — and
**a gap is never hidden**, because a recording that lies about its own
coverage is worse than one that admits an interruption.

### 2. Keychain accessibility moves to `afterFirstUnlockThisDeviceOnly`

`kSecureStorageIosOptions`
(`lib/core/storage/secure_storage_options.dart`) sets
`KeychainAccessibility.first_unlock_this_device` and is applied at every
`FlutterSecureStorage` construction in `lib/`, enforced by
`test/lint/secure_storage_options_test.dart` exactly as the Android
`resetOnError: false` constant already is.

This is the only security-relevant change in the #4351 programme, and it
was approved explicitly. It widens key availability from "while the
device is unlocked" to "after the first unlock since boot, on this
device only". The window given up is real: between a cold boot and the
user's first unlock, items that were previously sealed by the screen
lock are now sealed only by the boot state. The window bought is the
entire premise of background recording — without it a locked device
cannot decrypt the Hive cipher, so a trip recorded with the screen off
loses its storage key.

The `ThisDeviceOnly` half is load-bearing, not decoration: it keeps the
key out of encrypted backups and device-to-device transfers, so a key
can never arrive on a second device alongside box files it was not
written for. That is precisely the mismatch #4118 is about, and a
mismatched key truncates rather than fails.

### 3. A locked read is a retryable verdict, not a lost key

`HiveCipherLoader` asks `isCupertinoProtectedDataAvailable()` **before**
the keychain read (the call is platform-gated inside the plugin, so it
costs nothing off iOS/macOS). An explicit `false` throws
`StorageInitException.protectedDataUnavailable` immediately — no read,
no verdict, no minted key, no box open. A keychain error that still gets
through is classified narrowly: only `errSecInteractionNotAllowed`
(-25308) and an explicit `protected_data_unavailable` code count;
everything else stays a cause-unknown fault, because calling a permanent
fault transient is how a user retries forever.

`StorageKeyLostException` therefore keeps its meaning: the key is
genuinely gone. The retryable branch structurally cannot reach the
truncating path.

### 4. A WAL write failure is observable

`ActiveTripSampleWal` watches each sink's `done` future and records
every open/write/close fault as an `ActiveTripWalFault`, exposed as
`lastFault` and on a broadcast `faults` stream. `isDurable` — a sink is
open **and** nothing has failed — is the predicate that may be read as
"what was appended is on disk". `isWritable` keeps its old meaning (is
there a sink to append to), because flipping it mid-trip would make the
stop path fall back to an in-memory list that only starts at the fault
and discard the lines that did reach the file. Routing `isDurable` into
the snapshot-strip and read-back decisions is S6's persistence
observation (#4354); this ADR fixes the seam, not its consumer.

Flush and close are bounded (5 s): a flush behind a failed open never
completes, and an unbounded one hangs the stop path.

### 5. Restoration binds to an identity or is refused

`IosRestorationIdentityFence` decides, with no clock and no channel:
**deferred** before an identity is bound (an early callback is the
normal shape of a relaunch, so it is held — boundedly — and judged when
the trip arms), **admitted** once for the bound adapter,
**duplicateIgnored** for a repeat, **refusedUnknownAdapter** for any
other peripheral, and **refusedAfterStop** for anything delivered after
the owner stopped. A refusal costs the peripheral every action: no
pending connect is re-armed and no `AdapterConnected` is emitted.

## Consequences

- Between boot and first unlock, secrets that previously required an
  unlocked screen now require only a booted-and-once-unlocked device.
  Accepted deliberately; recorded here so a future reviewer finds the
  reasoning rather than re-deriving it.
- Every `FlutterSecureStorage` call site in `lib/` now carries both
  option constants. The lint fails a construction that passes only one,
  so the convention cannot regress at the next call site.
- Existing keychain items keep the accessibility they were written with
  until they are rewritten; the change takes effect per item on its next
  write. A user who never rewrites the Hive key keeps `whenUnlocked`
  until a fresh install. That is not a correctness problem — the
  protected-data branch handles it — but it does mean the benefit
  arrives gradually on upgraded installs.
- `appendedCount` stops at the first fault instead of climbing, so
  existing telemetry that reads it now means "lines a healthy sink
  accepted".
- The lifecycle table's device rows are **pending**, not claimed.
  #4357b / S10 owns the physical matrix: locked-screen acquisition for
  20–30 minutes, protected-data availability while locked (including
  pre-first-unlock), OS-terminated relaunch as distinct from force-quit,
  battery cost, and Low Power Mode as a separately reported condition.
  Nothing here may be quoted as that evidence.
- macOS is out of scope. `mOptions` is untouched; desktop keychain
  behaviour is a separate question with a separate failure mode.

## Alternatives Considered

**Leave accessibility at `whenUnlocked` and buffer in memory while
locked.** Rejected: unacknowledged memory buffering is exactly what
#4357 forbids being labelled durable, and a process the OS may terminate
at any moment is the worst possible place to hold the only copy of a
trip.

**Use `first_unlock` without `ThisDeviceOnly`.** Rejected: identical
availability, but the key then travels in encrypted backups and device
transfers — reintroducing the key/box mismatch that truncates boxes
(#4118).

**Make a protected-data failure a `StorageKeyLostException` and let the
recovery screen offer a retry.** Rejected: the key-loss screen tells the
user their data is unrecoverable and offers to clear it. Showing that
for a locked phone invites the user to destroy a perfectly intact
history.

**Flip `isWritable` false on a WAL fault.** Rejected for now: it is the
routing answer several non-owned call sites key on, and flipping it
mid-trip makes the stop path return a fallback list that starts at the
fault, discarding what did reach disk. `isDurable` is added alongside it
instead, and S6 rewires the consumers in one place.

**Emit an `AdapterConnected` directly from a restoration event.**
Rejected: restoration says the OS kept a peripheral, not that a link is
live. The connection-state watch remains the single source of that
truth; admission only re-arms the pending connect.

**Assert `Info.plist` background modes as acceptance.** Rejected
explicitly by #4357: a source or plist assertion is not screen-lock
evidence. Those assertions are cheap regression guards and nothing more.
