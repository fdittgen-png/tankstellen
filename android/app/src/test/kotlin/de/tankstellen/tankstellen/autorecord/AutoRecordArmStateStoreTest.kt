// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

package de.tankstellen.tankstellen.autorecord

import android.app.ForegroundServiceStartNotAllowedException
import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * #4355 — the two *platform-backed* halves of the presence-watcher fix that
 * [AutoRecordArmingTest] deliberately fakes away:
 *
 *  - the `autorecord_arm` SharedPreferences round-trip a sticky restart
 *    reconstructs from (defect 2), and
 *  - the by-name classification of the Android 12+ background-start refusal
 *    (defect 1's accurate reason).
 */
@RunWith(RobolectricTestRunner::class)
class AutoRecordArmStateStoreTest {

    private val context: Context get() = ApplicationProvider.getApplicationContext()

    private fun freshStore(): SharedPrefsDesiredArmStateStore {
        context.getSharedPreferences(
            AutoRecordForegroundService.ARM_PREFS,
            Context.MODE_PRIVATE,
        ).edit().clear().commit()
        return SharedPrefsDesiredArmStateStore(context)
    }

    @Test
    fun aNeverArmedInstallReadsNull_soAStickyRestartStops() {
        assertNull(freshStore().read())
    }

    @Test
    fun theDesireSurvivesANewStoreInstance_whichIsWhatAProcessRestartSees() {
        freshStore().arm("AA:BB:CC:DD:EE:01", 9)

        // A restarted process builds a brand-new store over the same file.
        val afterRestart = SharedPrefsDesiredArmStateStore(context).read()

        assertEquals("AA:BB:CC:DD:EE:01", afterRestart?.mac)
        assertEquals(9, afterRestart?.generation)
        assertEquals(true, afterRestart?.armed)
    }

    @Test
    fun disarmClearsTheDesireButKeepsTheGenerationMonotonic() {
        val store = freshStore()
        store.arm("AA:BB:CC:DD:EE:01", 9)
        store.disarm()

        val afterRestart = SharedPrefsDesiredArmStateStore(context).read()
        assertEquals(false, afterRestart?.armed)
        assertEquals(9, afterRestart?.generation)
    }

    @Test
    fun theArmFileIsASiblingOfTheNotificationFile_notTheSameOne() {
        // #3505's localized notification copy and #4355's desired arming must
        // not share a file — a language change must not touch the arm state.
        assertEquals("autorecord_notification", AutoRecordForegroundService.NOTIF_PREFS)
        assertEquals("autorecord_arm", AutoRecordForegroundService.ARM_PREFS)

        freshStore().arm("AA:BB:CC:DD:EE:01", 3)
        val notifPrefs = context.getSharedPreferences(
            AutoRecordForegroundService.NOTIF_PREFS,
            Context.MODE_PRIVATE,
        )
        assertFalse(notifPrefs.contains(AutoRecordForegroundService.ARM_KEY_MAC))
    }

    @Test
    fun theStoreRoundTripsThroughTheArmingSeam() {
        // The seam + the real store together: an arm persists, and a
        // null-intent restart over that same file reconstructs it.
        val store = freshStore()
        val armer = RecordingArmer()
        val host = CountingHost()
        AutoRecordArming(
            promoter = { PromotionOutcome.Promoted },
            armer = armer,
            store = store,
            host = host,
        ).onStartCommand("AA:BB:CC:DD:EE:01")

        val restarted = AutoRecordArming(
            promoter = { PromotionOutcome.Promoted },
            armer = armer,
            store = SharedPrefsDesiredArmStateStore(context),
            host = host,
        )
        assertEquals(StartDisposition.STICKY, restarted.onStartCommand(null))
        assertEquals("AA:BB:CC:DD:EE:01", restarted.currentMac)
        assertTrue(
            "the reconstructed arm must outrank the persisted one",
            restarted.currentGeneration > 1,
        )
        assertEquals(0, host.stopCount)
    }

    @Test
    fun android12BackgroundStartRefusalIsNamedAccurately() {
        // The real exception the OS throws — an IllegalStateException subclass
        // the old code caught only incidentally and labelled generically.
        assertEquals(
            PromotionFailureReason.NOT_ALLOWED_IN_BACKGROUND,
            classifyPromotionFailure(
                Build.VERSION_CODES.S,
                ForegroundServiceStartNotAllowedException("mFgsStartForegroundTimeout"),
            ),
        )
    }

    @Test
    fun anOrdinaryIllegalStateStaysGeneric_onEveryApiLevel() {
        val plain = IllegalStateException("not the background-start refusal")
        assertEquals(
            PromotionFailureReason.ILLEGAL_STATE,
            classifyPromotionFailure(Build.VERSION_CODES.S, plain),
        )
        assertEquals(
            PromotionFailureReason.ILLEGAL_STATE,
            classifyPromotionFailure(Build.VERSION_CODES.R, plain),
        )
    }

    private class RecordingArmer : GattArmer {
        override fun arm(
            mac: String,
            generation: Int,
            onTransition: (type: String, atMillis: Long) -> Unit,
        ): GattHandle = GattHandle { }
    }

    private class CountingHost : ArmingHost {
        var stopCount = 0
        override fun postTransition(event: Map<String, Any>) = Unit
        override fun postPromoted(generation: Int) = Unit
        override fun postStartFailure(reason: String) = Unit
        override fun stopSelf() {
            stopCount++
        }
    }
}
