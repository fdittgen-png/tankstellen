// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

package de.tankstellen.tankstellen.autorecord

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * #4355 — executable regressions for the auto-record presence watcher's
 * lifecycle, one test per checkbox in the issue.
 *
 * These are plain JVM tests: [AutoRecordArming] holds every decision and
 * takes all four platform ports as constructor arguments, so `startForeground`
 * is injectable and a refused promotion is a *value*, not a device condition.
 *
 * DEVICE-ONLY, deliberately not faked here: that a real OS sticky restart
 * delivers a null intent, and that a real OEM accepts the promotion at all.
 * What is proven here is that a null-intent delivery is handled correctly
 * WHEN it happens — not that Android produces one.
 */
class AutoRecordArmingTest {

    private companion object {
        const val MAC_A = "AA:BB:CC:DD:EE:01"
        const val MAC_B = "AA:BB:CC:DD:EE:02"
    }

    // ---------------------------------------------------------------- fakes

    private class FakeHandle(val mac: String, val generation: Int) : GattHandle {
        var closeCount = 0
        override fun close() {
            closeCount++
        }
    }

    private class FakeArmer : GattArmer {
        /** Opened handles, in order. */
        val opened = mutableListOf<FakeHandle>()

        /** Every (mac, generation) the seam asked to connect. */
        val attempts = mutableListOf<Pair<String, Int>>()

        /** The transition callbacks handed over, by generation. */
        val callbacks = mutableMapOf<Int, (String, Long) -> Unit>()

        /** When true, the platform refuses the connection. */
        var refuse = false

        override fun arm(
            mac: String,
            generation: Int,
            onTransition: (type: String, atMillis: Long) -> Unit,
        ): GattHandle? {
            attempts += mac to generation
            callbacks[generation] = onTransition
            if (refuse) return null
            val handle = FakeHandle(mac, generation)
            opened += handle
            return handle
        }
    }

    private class FakeStore(private var state: DesiredArmState? = null) : DesiredArmStateStore {
        val writes = mutableListOf<DesiredArmState>()
        var disarmCount = 0

        override fun read(): DesiredArmState? = state

        override fun arm(mac: String, generation: Int) {
            val next = DesiredArmState(mac = mac, generation = generation, armed = true)
            state = next
            writes += next
        }

        override fun disarm() {
            disarmCount++
            state = state?.copy(armed = false)
        }
    }

    private class FakeHost : ArmingHost {
        val transitions = mutableListOf<Map<String, Any>>()
        val promoted = mutableListOf<Int>()
        val failures = mutableListOf<String>()
        var stopCount = 0

        override fun postTransition(event: Map<String, Any>) {
            transitions += event
        }

        override fun postPromoted(generation: Int) {
            promoted += generation
        }

        override fun postStartFailure(reason: String) {
            failures += reason
        }

        override fun stopSelf() {
            stopCount++
        }
    }

    private class Rig(
        persisted: DesiredArmState? = null,
        var outcome: PromotionOutcome = PromotionOutcome.Promoted,
    ) {
        val armer = FakeArmer()
        val store = FakeStore(persisted)
        val host = FakeHost()
        var promoteCount = 0

        val arming = AutoRecordArming(
            promoter = { promoteCount++; outcome },
            armer = armer,
            store = store,
            host = host,
        )

        /** Fires the platform callback registered for [generation]. */
        fun fireTransition(generation: Int, type: String, atMillis: Long = 1_700_000_000_000L) {
            val cb = armer.callbacks[generation]
                ?: throw AssertionError("no callback registered for generation $generation")
            cb(type, atMillis)
        }
    }

    // --------------------------------------------- checkbox 1 + the mutation

    @Test
    fun promotionRefused_takesZeroGattAttempts_andOneExplicitFailure() {
        // THE mutation-check target (#4355 last checkbox): deleting the
        // post-promotion abort in AutoRecordArming.onStartCommand makes this
        // test fail on `attempts` — the service would open a GATT connection
        // from a service Android refused to promote.
        val rig = Rig(
            outcome = PromotionOutcome.Refused(
                PromotionFailureReason.NOT_ALLOWED_IN_BACKGROUND,
            ),
        )

        val disposition = rig.arming.onStartCommand(MAC_A)

        // Asserted FIRST so the mutation's failure message names the actual
        // defect (a GATT opened from an unpromoted service), not a knock-on
        // disposition mismatch.
        assertEquals(
            "a refused promotion must take ZERO GATT connection attempts",
            emptyList<Pair<String, Int>>(),
            rig.armer.attempts,
        )
        assertEquals(StartDisposition.NOT_STICKY, disposition)
        assertFalse("no owner may be retained", rig.arming.isArmed)
        assertNull(rig.arming.currentMac)
        assertEquals(
            "exactly one explicit failure outcome, carrying the accurate reason",
            listOf("notAllowedInBackground"),
            rig.host.failures,
        )
        assertEquals(
            "a refused promotion is never acknowledged",
            emptyList<Int>(),
            rig.host.promoted,
        )
        assertEquals(1, rig.host.stopCount)
        assertEquals(
            "nothing may be persisted as armed on a refusal",
            emptyList<DesiredArmState>(),
            rig.store.writes,
        )
    }

    @Test
    fun promotionRefusal_reasonsAreDistinct_notOneGenericLabel() {
        val reasons = listOf(
            PromotionFailureReason.NOT_ALLOWED_IN_BACKGROUND to "notAllowedInBackground",
            PromotionFailureReason.PERMISSION_DENIED to "permissionDenied",
            PromotionFailureReason.ILLEGAL_STATE to "illegalState",
        )
        for ((reason, wire) in reasons) {
            val rig = Rig(outcome = PromotionOutcome.Refused(reason))
            rig.arming.onStartCommand(MAC_A)
            assertEquals(listOf(wire), rig.host.failures)
        }
    }

    @Test
    fun gattRefusedAfterPromotion_stopsWithoutAcknowledging() {
        // Promotion held, but the platform refused the connection (BT off,
        // BLUETOOTH_CONNECT revoked). The caller must NOT be told it has a
        // watcher: one failure, no ack, nothing retained.
        val rig = Rig()
        rig.armer.refuse = true

        val disposition = rig.arming.onStartCommand(MAC_A)

        assertEquals(StartDisposition.NOT_STICKY, disposition)
        assertEquals(listOf("gattUnavailable"), rig.host.failures)
        assertEquals(emptyList<Int>(), rig.host.promoted)
        assertFalse(rig.arming.isArmed)
        assertEquals(1, rig.host.stopCount)
    }

    // ------------------------------------------------------------ checkbox 2

    @Test
    fun stickyNullIntentRestart_reconstructsAtMostOneWatcher() {
        // The OS never redelivers extras on a sticky restart. The desire is
        // read back from persisted state instead.
        val rig = Rig(
            persisted = DesiredArmState(mac = MAC_A, generation = 7, armed = true),
        )

        val disposition = rig.arming.onStartCommand(null)

        assertEquals(StartDisposition.STICKY, disposition)
        assertEquals(1, rig.armer.attempts.size)
        assertEquals(MAC_A, rig.armer.attempts.single().first)
        assertEquals(1, rig.armer.opened.size)
        assertTrue(rig.arming.isArmed)
        assertEquals(1, rig.host.promoted.size)
        assertEquals(emptyList<String>(), rig.host.failures)
        assertEquals(0, rig.host.stopCount)
    }

    @Test
    fun reconstructedGeneration_staysMonotonicAcrossProcessDeath() {
        val rig = Rig(
            persisted = DesiredArmState(mac = MAC_A, generation = 7, armed = true),
        )
        rig.arming.onStartCommand(null)
        assertEquals(
            "a fresh process must not restart the counter at 1",
            8,
            rig.arming.currentGeneration,
        )
    }

    // ------------------------------------------------------------ checkbox 3

    @Test
    fun nullIntent_afterDisarm_stopsWithoutReconnecting() {
        val rig = Rig(
            persisted = DesiredArmState(mac = MAC_A, generation = 4, armed = false),
        )

        val disposition = rig.arming.onStartCommand(null)

        assertEquals(StartDisposition.NOT_STICKY, disposition)
        assertEquals(emptyList<Pair<String, Int>>(), rig.armer.attempts)
        assertEquals(
            "a disarmed restart must not even attempt a promotion",
            0,
            rig.promoteCount,
        )
        assertEquals(1, rig.host.stopCount)
        assertFalse(rig.arming.isArmed)
    }

    @Test
    fun nullIntent_withNoPersistedState_stopsWithoutReconnecting() {
        val rig = Rig(persisted = null)

        assertEquals(StartDisposition.NOT_STICKY, rig.arming.onStartCommand(null))
        assertEquals(emptyList<Pair<String, Int>>(), rig.armer.attempts)
        assertEquals(0, rig.promoteCount)
        assertEquals(1, rig.host.stopCount)
    }

    @Test
    fun nullIntent_withInvalidPersistedAdapter_stopsWithoutReconnecting() {
        val rig = Rig(
            persisted = DesiredArmState(mac = "not-a-mac", generation = 2, armed = true),
        )

        assertEquals(StartDisposition.NOT_STICKY, rig.arming.onStartCommand(null))
        assertEquals(emptyList<Pair<String, Int>>(), rig.armer.attempts)
        assertEquals(0, rig.promoteCount)
        assertEquals(1, rig.host.stopCount)
    }

    @Test
    fun explicitStart_withAnInvalidAdapter_stopsWithoutPromotingOrPersisting() {
        val rig = Rig()

        assertEquals(StartDisposition.NOT_STICKY, rig.arming.onStartCommand("zz"))
        assertEquals(0, rig.promoteCount)
        assertEquals(emptyList<DesiredArmState>(), rig.store.writes)
        assertEquals(1, rig.host.stopCount)
    }

    @Test
    fun macValidity_matchesWhatTheAdapterAccepts() {
        assertTrue(AutoRecordArming.isValidMac("AA:BB:CC:DD:EE:01"))
        assertTrue(AutoRecordArming.isValidMac("aa:bb:cc:dd:ee:01"))
        assertFalse(AutoRecordArming.isValidMac(null))
        assertFalse(AutoRecordArming.isValidMac(""))
        assertFalse(AutoRecordArming.isValidMac("AA:BB:CC:DD:EE"))
        assertFalse(AutoRecordArming.isValidMac("AA-BB-CC-DD-EE-01"))
        assertFalse(AutoRecordArming.isValidMac("GG:BB:CC:DD:EE:01"))
    }

    // ------------------------------------------------------------ checkbox 4

    @Test
    fun disarmDuringPendingConnect_thenLateCallback_doesNotRearmOrReport() {
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)
        val armedGeneration = rig.arming.currentGeneration
        assertTrue(rig.arming.isArmed)

        rig.arming.disarm()

        // The platform callback for the retired GATT fires afterwards — this
        // is the real race: `disconnect`/`connect` can be in flight when the
        // user disarms.
        rig.fireTransition(armedGeneration, "connect")

        assertEquals(
            "a late callback from a retired generation must not reach Dart",
            emptyList<Map<String, Any>>(),
            rig.host.transitions,
        )
        assertFalse(rig.arming.isArmed)
        assertEquals(1, rig.store.disarmCount)
        assertEquals(
            "nothing may be re-armed by a late callback",
            1,
            rig.armer.attempts.size,
        )
    }

    @Test
    fun liveGenerationCallbacks_stillReachDart() {
        // The fence must not be a mute button: the CURRENT generation's
        // transitions are exactly what auto-record runs on.
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)

        rig.fireTransition(rig.arming.currentGeneration, "connect", atMillis = 42L)

        assertEquals(1, rig.host.transitions.size)
        assertEquals("connect", rig.host.transitions.single()["type"])
        assertEquals(MAC_A, rig.host.transitions.single()["mac"])
        assertEquals(42L, rig.host.transitions.single()["atMillis"])
    }

    @Test
    fun rearmToANewMac_fencesTheOldGenerationsCallback() {
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)
        val oldGeneration = rig.arming.currentGeneration

        rig.arming.onStartCommand(MAC_B)
        val newGeneration = rig.arming.currentGeneration
        assertNotEquals(oldGeneration, newGeneration)

        rig.fireTransition(oldGeneration, "disconnect")
        assertEquals(emptyList<Map<String, Any>>(), rig.host.transitions)

        rig.fireTransition(newGeneration, "connect")
        assertEquals(1, rig.host.transitions.size)
        assertEquals(MAC_B, rig.host.transitions.single()["mac"])
    }

    // ------------------------------------------------------------ checkbox 5

    @Test
    fun duplicateStartsForTheSameMac_leaveExactlyOneOwner() {
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)
        rig.arming.onStartCommand(MAC_A)
        rig.arming.onStartCommand(MAC_A)

        assertEquals(
            "an idempotent re-arm must not open a second GATT",
            1,
            rig.armer.attempts.size,
        )
        assertEquals(
            "nor take a second promotion",
            1,
            rig.promoteCount,
        )
        assertEquals(
            "but each duplicate start is still acknowledged, or its parked " +
                "Dart reply would time out",
            3,
            rig.host.promoted.size,
        )
        assertEquals(0, rig.host.stopCount)
        assertTrue(rig.arming.isArmed)
    }

    @Test
    fun rearmToADifferentMac_closesThePriorOwnerExactlyOnce() {
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)
        val first = rig.armer.opened.single()

        rig.arming.onStartCommand(MAC_B)

        assertEquals(1, first.closeCount)
        assertEquals(2, rig.armer.opened.size)
        assertEquals(MAC_B, rig.arming.currentMac)
        assertEquals(0, rig.armer.opened[1].closeCount)
    }

    @Test
    fun repeatedCleanupIsSafeAndClosesEachOwnerOnce() {
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)
        val handle = rig.armer.opened.single()

        rig.arming.disarm()
        rig.arming.disarm()
        rig.arming.onDestroy()

        assertEquals("each owned GATT is closed exactly once", 1, handle.closeCount)
        assertFalse(rig.arming.isArmed)
    }

    // ------------------------------------------------------------ checkbox 6

    @Test
    fun aNewValidArmingWorksAfterAnEarlierPromotionFailure() {
        val rig = Rig(
            outcome = PromotionOutcome.Refused(PromotionFailureReason.PERMISSION_DENIED),
        )
        val refused = rig.arming.onStartCommand(MAC_A)
        assertEquals(emptyList<Pair<String, Int>>(), rig.armer.attempts)
        assertEquals(StartDisposition.NOT_STICKY, refused)

        rig.outcome = PromotionOutcome.Promoted
        assertEquals(StartDisposition.STICKY, rig.arming.onStartCommand(MAC_A))

        assertTrue(rig.arming.isArmed)
        assertEquals(1, rig.armer.opened.size)
        assertEquals(listOf(rig.arming.currentGeneration), rig.host.promoted)
    }

    @Test
    fun aStaleStopCannotTearDownANewerValidOwner() {
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)
        val staleGeneration = rig.arming.currentGeneration

        rig.arming.onStartCommand(MAC_B)
        val liveHandle = rig.armer.opened.last()

        assertFalse(
            "a teardown from a retired generation must be refused",
            rig.arming.stopGeneration(staleGeneration),
        )
        assertTrue(rig.arming.isArmed)
        assertEquals(MAC_B, rig.arming.currentMac)
        assertEquals(0, liveHandle.closeCount)
        assertEquals(0, rig.host.stopCount)

        assertTrue(rig.arming.stopGeneration(rig.arming.currentGeneration))
        assertEquals(1, liveHandle.closeCount)
        assertFalse(rig.arming.isArmed)
    }

    @Test
    fun generationIsStrictlyMonotonicAcrossArmsAndTeardowns() {
        val rig = Rig()
        val seen = mutableListOf<Int>()
        rig.arming.onStartCommand(MAC_A); seen += rig.arming.currentGeneration
        rig.arming.disarm(); seen += rig.arming.currentGeneration
        rig.arming.onStartCommand(MAC_A); seen += rig.arming.currentGeneration
        rig.arming.onDestroy(); seen += rig.arming.currentGeneration
        rig.arming.onStartCommand(MAC_B); seen += rig.arming.currentGeneration

        assertEquals(seen.sorted(), seen)
        assertEquals(seen.distinct().size, seen.size)
    }

    // -------------------------------------------- persisted-desire behaviour

    @Test
    fun anAcceptedArmPersistsTheDesire_andAnExplicitDisarmClearsIt() {
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)

        assertEquals(1, rig.store.writes.size)
        assertEquals(MAC_A, rig.store.writes.single().mac)
        assertTrue(rig.store.writes.single().armed)

        rig.arming.disarm()
        assertEquals(1, rig.store.disarmCount)
        assertEquals(false, rig.store.read()?.armed)

        // And the cleared desire is what a subsequent sticky restart reads.
        assertEquals(StartDisposition.NOT_STICKY, rig.arming.onStartCommand(null))
    }

    @Test
    fun onDestroyKeepsTheDesire_soAnOsKillCanStillReconstruct() {
        // A process kill is not a user disarm: `onDestroy` must not clear the
        // desire, or the OS restart would have nothing to rebuild from.
        val rig = Rig()
        rig.arming.onStartCommand(MAC_A)
        rig.arming.onDestroy()

        assertEquals(0, rig.store.disarmCount)
        assertEquals(true, rig.store.read()?.armed)
    }
}
