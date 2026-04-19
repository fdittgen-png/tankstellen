package de.tankstellen.tankstellen

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
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
        when (intent.action) {
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
            StationWidgetRenderer.ACTION_REFRESH -> {
                val mgr = AppWidgetManager.getInstance(context)
                val ids = mgr.getAppWidgetIds(
                    ComponentName(context, FuelPriceWidgetProvider::class.java),
                )
                for (id in ids) renderAndCommit(context, mgr, id)
                // Open the app so its Riverpod stack can pull fresh prices.
                val launchIntent =
                    context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(launchIntent)
                }
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
