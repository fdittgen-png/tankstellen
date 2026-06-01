// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

/**
 * Home-screen widget that starts in "favorites" mode. The user can flip
 * the widget to "nearest" mode via the toggle icon in the header; the
 * choice is persisted per appWidgetId. Rendering and intent wiring is
 * delegated to [StationWidgetRenderer] which both providers share.
 */
class FuelPriceWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            renderAndCommit(context, appWidgetManager, appWidgetId)
        }
        // #2412 — the OS refreshes the widget periodically (updatePeriodMillis)
        // while it is on the home screen. Treat each refresh as an extra,
        // opportunistic wake for the on-device price scan — complementary to
        // the WorkManager periodic tasks, NOT a reliability guarantee. The
        // coordinator's cross-trigger cooldown (#2415) dedups this against a
        // concurrent periodic scan, so it is a cheap no-op when one just ran.
        BackgroundScanEnqueuer.enqueue(
            context,
            dartTask = WIDGET_SCAN_TASK,
            uniqueName = WIDGET_SCAN_UNIQUE_NAME,
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            // The mode toggle is a broadcast — it merely re-renders, which
            // is allowed from onReceive.
            StationWidgetRenderer.ACTION_TOGGLE_MODE -> {
                val id = intent.getIntExtra(
                    StationWidgetRenderer.EXTRA_APP_WIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                if (id != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    StationWidgetRenderer.toggleMode(
                        context,
                        id,
                        StationWidgetRenderer.MODE_FAVORITES,
                    )
                    renderAndCommit(
                        context,
                        AppWidgetManager.getInstance(context),
                        id,
                    )
                }
            }
            // #2600 — refresh-in-place. The refresh icon is now a broadcast
            // (not an Activity PendingIntent), so a tap NEVER launches the
            // app. We dim the glyph for immediate feedback, then enqueue the
            // SAME on-device `widgetRefreshScan` WorkManager task that the
            // periodic onUpdate wake uses (#2412): the Dart
            // `BackgroundService.widgetRefreshScanTask` re-fetches prices and
            // calls back into HomeWidget to re-render every placed widget.
            // The coordinator's cross-trigger cooldown (#2415) dedups this
            // against a concurrent periodic scan, so a rapid tap is cheap.
            StationWidgetRenderer.ACTION_REFRESH -> {
                val id = intent.getIntExtra(
                    StationWidgetRenderer.EXTRA_APP_WIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID,
                )
                if (id != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    StationWidgetRenderer.setRefreshing(context, id)
                }
                BackgroundScanEnqueuer.enqueue(
                    context,
                    dartTask = WIDGET_SCAN_TASK,
                    uniqueName = WIDGET_SCAN_UNIQUE_NAME,
                )
            }
        }
    }

    private fun renderAndCommit(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views = StationWidgetRenderer.render(
            context = context,
            appWidgetId = appWidgetId,
            defaultMode = StationWidgetRenderer.MODE_FAVORITES,
            providerClass = FuelPriceWidgetProvider::class.java,
        )
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    companion object {
        /**
         * Dart task name enqueued on every widget refresh (#2412). Must match
         * `BackgroundService.widgetRefreshScanTask`.
         */
        const val WIDGET_SCAN_TASK = "widgetRefreshScan"

        private const val WIDGET_SCAN_UNIQUE_NAME = "widgetRefreshScan"
    }
}
