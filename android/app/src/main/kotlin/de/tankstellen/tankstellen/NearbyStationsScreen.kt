package de.tankstellen.tankstellen

import android.content.Context
import android.content.SharedPreferences
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.*
import org.json.JSONArray

/**
 * Android Auto screen showing nearby favorite stations with prices.
 *
 * Reads station data from SharedPreferences (written by Flutter via home_widget).
 * Uses PlaceListMapTemplate for a list of POIs with navigation actions.
 */
class NearbyStationsScreen(carContext: CarContext) : Screen(carContext) {

    override fun onGetTemplate(): Template {
        val prefs: SharedPreferences = carContext.getSharedPreferences(
            "HomeWidgetPreferences", Context.MODE_PRIVATE
        )
        val stationsJson = prefs.getString("stations_json", "[]") ?: "[]"

        val stations = try {
            JSONArray(stationsJson)
        } catch (e: Exception) {
            JSONArray()
        }

        val listBuilder = ItemList.Builder()

        if (stations.length() == 0) {
            listBuilder.setNoItemsMessage("Add favorites in the app to see stations here")
        } else {
            val count = minOf(stations.length(), 6) // Android Auto max list items
            for (i in 0 until count) {
                val station = stations.getJSONObject(i)
                val name = station.optString("name", "Station")
                val place = station.optString("place", "")
                val e10 = station.optDouble("e10", Double.NaN)
                val diesel = station.optDouble("diesel", Double.NaN)

                val priceText = buildString {
                    if (!e10.isNaN()) append("E10: ${String.format("%.3f", e10)}")
                    if (!diesel.isNaN()) {
                        if (isNotEmpty()) append(" | ")
                        append("Diesel: ${String.format("%.3f", diesel)}")
                    }
                    if (isEmpty()) append("No prices")
                }

                listBuilder.addItem(
                    Row.Builder()
                        .setTitle(name)
                        .addText("$place — $priceText")
                        .build()
                )
            }
        }

        return ListTemplate.Builder()
            .setTitle("Fuel Prices")
            .setHeaderAction(Action.APP_ICON)
            .setSingleList(listBuilder.build())
            .build()
    }
}
