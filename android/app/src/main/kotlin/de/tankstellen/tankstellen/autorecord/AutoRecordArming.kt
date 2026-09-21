// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

package de.tankstellen.tankstellen.autorecord

/**
 * #4355 — the auto-record presence watcher's lifecycle decisions, lifted out
 * of [AutoRecordForegroundService] so every one of them is executable under a
 * plain JVM unit test (no Robolectric, no device, no `android.app.Service`).
 *
 * The seam deliberately contains **no** `android.*` types. Everything the
 * decisions need from the platform arrives through four injected ports:
 *
 *  - [ForegroundPromoter]  — `Service.startForeground`, as a typed outcome.
 *  - [GattArmer]           — `BluetoothDevice.connectGatt`, as a closeable handle.
 *  - [DesiredArmStateStore]— the persisted *desire* to watch an adapter.
 *  - [ArmingHost]          — the channel posts and `Service.stopSelf`.
 *
 * Three invariants this class exists to hold, all of them previously violated
 * by the inline implementation:
 *
 *  1. **Promotion gates every resource.** If the OS refuses to promote the
 *     service to the foreground, *nothing* downstream runs — no GATT, no
 *     persisted arm, no retry. The old code swallowed the refusal and opened
 *     a GATT connection from a service Android had already decided to kill.
 *  2. **A null intent is the normal sticky-restart delivery, not an error.**
 *     The desired arming is reconstructed from [DesiredArmStateStore], never
 *     from intent extras that the OS does not redeliver.
 *  3. **Every owned resource carries a monotonic generation.** A callback or
 *     a teardown tagged with a retired generation is dropped, so a late GATT
 *     transition from a previous arm cannot drive the current session and a
 *     stale stop cannot tear down a newer valid owner.
 *
 * There are no timers in the watcher: `autoConnect = true` makes the platform
 * own the retry cadence. "Zero retained timers" after a failed promotion is
 * therefore structural — the only retained resource is the GATT handle, and
 * [isArmed] pins that it is absent.
 */
class AutoRecordArming(
    private val promoter: ForegroundPromoter,
    private val armer: GattArmer,
    private val store: DesiredArmStateStore,
    private val host: ArmingHost,
) {
    /**
     * Monotonic arm counter. Seeded from [DesiredArmStateStore] on each arm so
     * it keeps increasing across process death, and bumped on every teardown
     * so in-flight callbacks from the retired arm are fenced out.
     */
    private var generation: Int = 0

    private var handle: GattHandle? = null
    private var armedMac: String? = null

    /** The generation currently permitted to post transitions. */
    val currentGeneration: Int get() = generation

    /** True while exactly one GATT owner is held. */
    val isArmed: Boolean get() = handle != null

    /** The MAC the live owner watches, or null when nothing is armed. */
    val currentMac: String? get() = armedMac

    /**
     * Handles one `Service.onStartCommand` delivery.
     *
     * @param intentMac `intent?.getStringExtra(EXTRA_MAC)` — null both for an
     *   OS sticky restart (which never redelivers extras) and for a malformed
     *   explicit start.
     */
    fun onStartCommand(intentMac: String?): StartDisposition {
        val requestedMac = resolveDesiredMac(intentMac) ?: run {
            // Disarmed, consent withdrawn, no persisted desire, or an adapter
            // the platform cannot address. Stop cleanly: no GATT, no retry,
            // and no new recording merely because the watcher was restarted.
            stopCleanly()
            return StartDisposition.NOT_STICKY
        }

        if (requestedMac.equals(armedMac, ignoreCase = true) && handle != null) {
            // Idempotent re-arm: one owner already holds this MAC, so we take
            // no second promotion and no second GATT. The acknowledgement is
            // re-posted because a duplicate Dart `start` is still waiting for
            // one (the channel parks its reply until the service acks).
            host.postPromoted(generation)
            return StartDisposition.STICKY
        }

        // #4355 defect 1 — the promotion is the gate. A refusal aborts here,
        // BEFORE any GATT resource is taken, with exactly one typed failure.
        val outcome = promoter.promote()
        if (outcome is PromotionOutcome.Refused) {
            host.postStartFailure(outcome.reason.wireName)
            stopCleanly()
            return StartDisposition.NOT_STICKY
        }

        // Retire the previous owner before taking a new one, so a re-arm can
        // never leave two GATT clients alive against the same service.
        retire()

        val gen = nextGeneration()
        armedMac = requestedMac
        store.arm(requestedMac, gen)

        val opened = armer.arm(requestedMac, gen) { type, atMillis ->
            onTransition(gen, requestedMac, type, atMillis)
        }
        if (opened == null) {
            // Promotion held but the platform refused the connection (adapter
            // off, BLUETOOTH_CONNECT revoked, unusable MAC). Stop cleanly; the
            // persisted desire survives so a later legitimate start re-arms.
            // Exactly one failure outcome, and no acknowledgement: the caller
            // must not be told it has a watcher that owns nothing.
            host.postStartFailure(PromotionFailureReason.GATT_UNAVAILABLE.wireName)
            stopCleanly()
            return StartDisposition.NOT_STICKY
        }
        handle = opened
        // Acknowledged only once the service is BOTH promoted and owns a live
        // GATT. This is what answers the parked Dart `start` reply.
        host.postPromoted(gen)
        return StartDisposition.STICKY
    }

    /**
     * A GATT transition reported by the platform callback opened for
     * [gen]. Dropped unless [gen] is still the live generation — that is the
     * whole point of the token: a late callback from a retired arm must not
     * drive the current session.
     */
    fun onTransition(gen: Int, mac: String, type: String, atMillis: Long) {
        if (gen != generation) return
        host.postTransition(
            mapOf<String, Any>(
                "type" to type,
                "mac" to mac,
                "atMillis" to atMillis,
            ),
        )
    }

    /**
     * Explicit stop / disarm / consent withdrawal. Invalidates the pending
     * connect *before* teardown, clears the restart context so a sticky
     * restart cannot reconstruct it, and stops the service.
     */
    fun disarm() {
        retire()
        store.disarm()
        host.stopSelf()
    }

    /**
     * Teardown requested by the owner of [gen]. A stale stop (one issued by an
     * already-retired generation) is refused so it cannot close a newer valid
     * owner's resources.
     *
     * @return true when [gen] was live and the disarm ran.
     */
    fun stopGeneration(gen: Int): Boolean {
        if (gen != generation) return false
        disarm()
        return true
    }

    /** `Service.onDestroy`. Retires the owner; leaves the persisted desire. */
    fun onDestroy() = retire()

    /**
     * Resolves which MAC this delivery should arm, or null when the delivery
     * must stop instead.
     */
    private fun resolveDesiredMac(intentMac: String?): String? {
        if (!intentMac.isNullOrBlank()) {
            return if (isValidMac(intentMac)) intentMac else null
        }
        // #4355 defect 2 — an OS sticky restart ALWAYS delivers a null intent.
        // Reconstruct from the persisted desire rather than trusting extras
        // the OS does not redeliver.
        val persisted = store.read() ?: return null
        if (!persisted.armed) return null
        return if (isValidMac(persisted.mac)) persisted.mac else null
    }

    /**
     * Bumps the generation and closes the owned handle. Idempotent and safe
     * from every error path: repeated cleanup leaves one valid owner or none,
     * never duplicates.
     */
    private fun retire() {
        generation++
        val open = handle
        handle = null
        armedMac = null
        open?.close()
    }

    private fun stopCleanly() {
        retire()
        host.stopSelf()
    }

    private fun nextGeneration(): Int {
        val persisted = store.read()?.generation ?: 0
        generation = maxOf(generation, persisted) + 1
        return generation
    }

    companion object {
        /**
         * The exact shape `BluetoothAdapter.getRemoteDevice` accepts. Checked
         * here so an unusable identifier never reaches a promotion or a
         * persisted arm.
         */
        private val MAC_PATTERN = Regex("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")

        fun isValidMac(mac: String?): Boolean =
            mac != null && MAC_PATTERN.matches(mac)
    }
}

/** What `onStartCommand` must return to the OS. */
enum class StartDisposition { STICKY, NOT_STICKY }

/** Why the OS did not promote the presence service to the foreground. */
enum class PromotionFailureReason(val wireName: String) {
    /**
     * Android 12+ refused a background start
     * (`ForegroundServiceStartNotAllowedException`). Distinguished by name so
     * the reason reaching Dart is accurate rather than a generic label.
     */
    NOT_ALLOWED_IN_BACKGROUND("notAllowedInBackground"),

    /** `FOREGROUND_SERVICE*` permission not held (`SecurityException`). */
    PERMISSION_DENIED("permissionDenied"),

    /** Any other `IllegalStateException` out of `startForeground`. */
    ILLEGAL_STATE("illegalState"),

    /**
     * Promotion held, but the platform refused the connection: no Bluetooth
     * adapter, `BLUETOOTH_CONNECT` not granted, or an unusable MAC.
     */
    GATT_UNAVAILABLE("gattUnavailable"),
}

/** Result of asking the OS to promote the service. */
sealed interface PromotionOutcome {
    /** The OS accepted: the service is in the foreground. */
    data object Promoted : PromotionOutcome

    /** The OS refused. [reason] is what reaches Dart. */
    data class Refused(val reason: PromotionFailureReason) : PromotionOutcome
}

/** `Service.startForeground`, as an outcome instead of an exception. */
fun interface ForegroundPromoter {
    fun promote(): PromotionOutcome
}

/** One owned GATT client. [close] must be idempotent and must not throw. */
fun interface GattHandle {
    fun close()
}

/** `BluetoothDevice.connectGatt`, returning null when the platform refuses. */
fun interface GattArmer {
    /**
     * @param generation the token the platform callback must report back, so
     *   [AutoRecordArming] can fence a late transition from a retired arm.
     */
    fun arm(
        mac: String,
        generation: Int,
        onTransition: (type: String, atMillis: Long) -> Unit,
    ): GattHandle?
}

/**
 * The persisted *desire* to watch an adapter — the only thing a sticky restart
 * may reconstruct from. Holds no credentials: a paired adapter MAC the app
 * already stores, plus the arm counter.
 */
data class DesiredArmState(
    val mac: String,
    val generation: Int,
    val armed: Boolean,
)

/** Storage for [DesiredArmState]. */
interface DesiredArmStateStore {
    /** The persisted desire, or null when nothing was ever armed. */
    fun read(): DesiredArmState?

    /** Records an accepted arm at [generation]. */
    fun arm(mac: String, generation: Int)

    /** Clears the armed flag; the generation is kept so it stays monotonic. */
    fun disarm()
}

/** Everything [AutoRecordArming] needs from the hosting `Service`. */
interface ArmingHost {
    /** A `{type, mac, atMillis}` adapter transition for the Dart stream. */
    fun postTransition(event: Map<String, Any>)

    /** The OS promoted the service; [generation] identifies the arm. */
    fun postPromoted(generation: Int)

    /** A single explicit failure outcome; [reason] is a [PromotionFailureReason] wire name. */
    fun postStartFailure(reason: String)

    /** `Service.stopForeground` + `Service.stopSelf`. */
    fun stopSelf()
}
