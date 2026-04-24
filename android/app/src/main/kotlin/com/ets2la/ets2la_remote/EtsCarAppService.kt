package com.ets2la.ets2la_remote

import android.content.Intent
import androidx.car.app.CarAppService
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.GridItem
import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ItemList
import androidx.car.app.model.Template
import androidx.car.app.validation.HostValidator

/**
 * Minimal Android Auto surface for ETS2LA Remote. Displays a 2-cell
 * grid ("Autopilot", "ACC") on the head unit; each cell forwards a
 * toggle to the phone via the same [AutopilotWidgetProvider] intent
 * channel used by the home-screen widget and the Wear companion.
 *
 * Intentionally minimal — Android Auto apps are heavily constrained
 * to a small set of templates for driver safety. Live speed display
 * would require a templated ScrollingContentTemplate subscribed to a
 * phone-side data stream; out of scope for this PR.
 */
class EtsCarAppService : CarAppService() {

    override fun createHostValidator(): HostValidator {
        return HostValidator.Builder(applicationContext)
            .addAllowedHosts(
                androidx.car.app.R.array.hosts_allowlist_sample,
            )
            .build()
    }

    override fun onCreateSession(): Session = EtsSession()
}

private class EtsSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen = EtsMainScreen(carContext)
}

private class EtsMainScreen(ctx: CarContext) : Screen(ctx) {
    override fun onGetTemplate(): Template {
        val list = ItemList.Builder()
            .addItem(
                GridItem.Builder()
                    .setTitle(carContext.getString(R.string.notification_action_autopilot))
                    .setImage(CarIcon.APP_ICON)
                    .setOnClickListener {
                        WidgetActionBridge.forward(
                            carContext,
                            AutopilotWidgetProvider.ACTION_TOGGLE_STEERING,
                        )
                    }
                    .build(),
            )
            .addItem(
                GridItem.Builder()
                    .setTitle(carContext.getString(R.string.notification_action_acc))
                    .setImage(CarIcon.APP_ICON)
                    .setOnClickListener {
                        WidgetActionBridge.forward(
                            carContext,
                            AutopilotWidgetProvider.ACTION_TOGGLE_ACC,
                        )
                    }
                    .build(),
            )
            .build()
        return GridTemplate.Builder()
            .setTitle("ETS2LA")
            .setSingleList(list)
            .setHeaderAction(Action.APP_ICON)
            .build()
    }
}

/**
 * Small helper that forwards a widget-action extra to [MainActivity]
 * so the existing widget-intent drain logic handles it — we don't
 * have to introduce a car-specific code path on the Flutter side.
 */
internal object WidgetActionBridge {
    fun forward(context: android.content.Context, action: String) {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            putExtra(AutopilotWidgetProvider.EXTRA_WIDGET_ACTION, action)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        context.startActivity(intent)
    }
}
