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
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // #1801 — the refresh icon is now an Activity PendingIntent
        // (see StationWidgetRenderer), not a broadcast: a
        // BroadcastReceiver cannot reliably `startActivity` on
        // Android 10+, so the old ACTION_REFRESH broadcast silently
        // no-op'd. Only the mode toggle stays a broadcast — it merely
        // re-renders, which is allowed from onReceive.
        if (intent.action == StationWidgetRenderer.ACTION_TOGGLE_MODE) {
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
}
