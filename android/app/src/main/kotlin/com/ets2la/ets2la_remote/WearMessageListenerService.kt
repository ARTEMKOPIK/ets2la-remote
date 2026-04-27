package com.ets2la.ets2la_remote

import android.content.Intent
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

/**
 * Receives Wearable Data Layer messages from the Wear OS companion and
 * routes them into the Flutter isolate by starting [MainActivity] with
 * the same intent extras the home-screen widget uses.
 *
 * This keeps the Wear → phone path and the widget → phone path identical
 * on the Flutter side: both end up in `ConnectionProvider._handleWidgetAction`.
 */
class WearMessageListenerService : WearableListenerService() {

    companion object {
        private const val PATH_TOGGLE_STEERING = "/ets2la/toggle_steering"
        private const val PATH_TOGGLE_ACC = "/ets2la/toggle_acc"
    }

    override fun onMessageReceived(event: MessageEvent) {
        val action = when (event.path) {
            PATH_TOGGLE_STEERING -> AutopilotWidgetProvider.ACTION_TOGGLE_STEERING
            PATH_TOGGLE_ACC -> AutopilotWidgetProvider.ACTION_TOGGLE_ACC
            else -> return
        }
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            this.action = action
            putExtra(AutopilotWidgetProvider.EXTRA_WIDGET_ACTION, action)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        WidgetActionSecurity.attachToken(applicationContext, intent)
        startActivity(intent)
    }
}
