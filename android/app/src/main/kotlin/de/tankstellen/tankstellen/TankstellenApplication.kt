// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.app.Application

/**
 * #3580 — custom Application solely so the crash-forensics last-resort
 * uncaught-exception handler is installed for EVERY process entry point
 * (activity, foreground service, WorkManager worker, widget provider) —
 * a background recording crash must journal even when no activity ever
 * existed in the process.
 */
class TankstellenApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CrashForensics.installUncaughtHandler(this)
    }
}
