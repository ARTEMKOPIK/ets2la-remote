package com.ets2la.ets2la_remote

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home-screen widget with "Autopilot" and "ACC" toggle buttons.
 *
 * Tapping a button launches the app via [MainActivity] with an intent extra.
 * The Flutter side picks it up and invokes [PagesWsService.toggleSteering]
 * / `toggleAcc` on the already-connected session (the foreground service
 * keeps it alive).
 */
class AutopilotWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_STEERING = "com.ets2la.ets2la_remote.TOGGLE_STEERING"
        const val ACTION_TOGGLE_ACC = "com.ets2la.ets2la_remote.TOGGLE_ACC"
        const val EXTRA_WIDGET_ACTION = "widget_action"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, AutopilotWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                val provider = AutopilotWidgetProvider()
                for (id in ids) provider.render(context, manager, id)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) render(context, appWidgetManager, id)
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_autopilot)
        views.setOnClickPendingIntent(
            R.id.widget_btn_autopilot,
            launchPendingIntent(context, ACTION_TOGGLE_STEERING, appWidgetId),
        )
        views.setOnClickPendingIntent(
            R.id.widget_btn_acc,
            launchPendingIntent(context, ACTION_TOGGLE_ACC, appWidgetId),
        )
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun launchPendingIntent(
        context: Context,
        action: String,
        appWidgetId: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            putExtra(EXTRA_WIDGET_ACTION, action)
            // FLAG_ACTIVITY_SINGLE_TOP so an already-running MainActivity
            // receives onNewIntent instead of being recreated.
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        // Use a request code derived from action so each button has its own
        // PendingIntent — otherwise both buttons would share the same one.
        val requestCode = action.hashCode() xor appWidgetId
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
