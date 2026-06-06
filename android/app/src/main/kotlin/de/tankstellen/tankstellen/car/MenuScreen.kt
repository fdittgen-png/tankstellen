// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import de.tankstellen.tankstellen.R

/**
 * Android Auto v1 (#2948 / epic #2946) — the root car menu. A simple
 * [ListTemplate] with two rows that push the [SearchScreen] and [RadarScreen].
 */
class MenuScreen(carContext: CarContext) : Screen(carContext) {

    override fun onGetTemplate(): Template {
        val list = ItemList.Builder()
            .addItem(
                Row.Builder()
                    .setTitle(carContext.getString(R.string.car_menu_search))
                    .addText(carContext.getString(R.string.car_menu_search_subtitle))
                    .setBrowsable(true)
                    .setOnClickListener { screenManager.push(SearchScreen(carContext)) }
                    .build()
            )
            .addItem(
                Row.Builder()
                    .setTitle(carContext.getString(R.string.car_menu_radar))
                    .addText(carContext.getString(R.string.car_menu_radar_subtitle))
                    .setBrowsable(true)
                    .setOnClickListener { screenManager.push(RadarScreen(carContext)) }
                    .build()
            )
            .build()

        return ListTemplate.Builder()
            .setTitle(carContext.getString(R.string.car_app_title))
            .setHeaderAction(Action.APP_ICON)
            .setSingleList(list)
            .build()
    }
}
