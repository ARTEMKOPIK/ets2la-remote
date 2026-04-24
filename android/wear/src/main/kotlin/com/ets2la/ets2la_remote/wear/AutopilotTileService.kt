package com.ets2la.ets2la_remote.wear

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders
import androidx.wear.protolayout.DimensionBuilders
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.TypeBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * Wear OS Tile that exposes "Toggle Autopilot" / "Toggle ACC" as a
 * two-button tile on the user's tile carousel. Tapping either button
 * launches the companion Wear activity with a `path=…` extra so the
 * same Message-API round-trip as the main activity buttons is reused.
 *
 * Intentionally minimal: no live state (that would require streaming
 * from the phone via the Wear data layer). See the phone-side
 * `WearMessageListenerService` for the receiving half.
 */
class AutopilotTileService : TileService() {

    companion object {
        private const val RESOURCES_VERSION = "1"
    }

    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        val root = LayoutElementBuilders.Column.Builder()
            .setWidth(DimensionBuilders.expand())
            .setHeight(DimensionBuilders.expand())
            .setHorizontalAlignment(
                LayoutElementBuilders.HorizontalAlignmentProp.Builder()
                    .setValue(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
                    .build(),
            )
            .addContent(label(getString(R.string.title), 12))
            .addContent(spacer(12))
            .addContent(
                bigButton(
                    text = getString(R.string.toggle_autopilot),
                    backgroundArgb = 0xFFFF9500.toInt(),
                    textArgb = 0xFF000000.toInt(),
                    clickId = "toggle_steering",
                    path = MainActivity.PATH_TOGGLE_STEERING,
                ),
            )
            .addContent(spacer(8))
            .addContent(
                bigButton(
                    text = getString(R.string.toggle_acc),
                    backgroundArgb = 0xFF3A86FF.toInt(),
                    textArgb = 0xFFFFFFFF.toInt(),
                    clickId = "toggle_acc",
                    path = MainActivity.PATH_TOGGLE_ACC,
                ),
            )
            .build()

        val layout = LayoutElementBuilders.Layout.Builder()
            .setRoot(root)
            .build()

        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setTileTimeline(
                TimelineBuilders.Timeline.Builder()
                    .addTimelineEntry(
                        TimelineBuilders.TimelineEntry.Builder()
                            .setLayout(layout)
                            .build(),
                    )
                    .build(),
            )
            .build()
        return Futures.immediateFuture(tile)
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> {
        return Futures.immediateFuture(
            ResourceBuilders.Resources.Builder()
                .setVersion(RESOURCES_VERSION)
                .build(),
        )
    }

    private fun label(text: String, sizeSp: Int): LayoutElementBuilders.LayoutElement =
        LayoutElementBuilders.Text.Builder()
            .setText(text)
            .setFontStyle(
                LayoutElementBuilders.FontStyle.Builder()
                    .setSize(DimensionBuilders.sp(sizeSp.toFloat()))
                    .setColor(ColorBuilders.argb(0xFFFFFFFF.toInt()))
                    .build(),
            )
            .build()

    private fun spacer(dp: Int): LayoutElementBuilders.LayoutElement =
        LayoutElementBuilders.Spacer.Builder()
            .setHeight(DimensionBuilders.dp(dp.toFloat()))
            .build()

    private fun bigButton(
        text: String,
        backgroundArgb: Int,
        textArgb: Int,
        clickId: String,
        path: String,
    ): LayoutElementBuilders.LayoutElement {
        val label = LayoutElementBuilders.Text.Builder()
            .setText(text)
            .setFontStyle(
                LayoutElementBuilders.FontStyle.Builder()
                    .setSize(DimensionBuilders.sp(14f))
                    .setColor(ColorBuilders.argb(textArgb))
                    .setWeight(
                        LayoutElementBuilders.FontWeightProp.Builder()
                            .setValue(LayoutElementBuilders.FONT_WEIGHT_BOLD)
                            .build(),
                    )
                    .build(),
            )
            .build()
        val clickable = ModifiersBuilders.Clickable.Builder()
            .setId(clickId)
            .setOnClick(
                ActionBuilders.LaunchAction.Builder()
                    .setAndroidActivity(
                        ActionBuilders.AndroidActivity.Builder()
                            .setPackageName(packageName)
                            .setClassName(
                                "com.ets2la.ets2la_remote.wear.MainActivity",
                            )
                            .addKeyToExtraMapping(
                                "path",
                                ActionBuilders.AndroidStringExtra.Builder()
                                    .setValue(path)
                                    .build(),
                            )
                            .build(),
                    )
                    .build(),
            )
            .build()
        return LayoutElementBuilders.Box.Builder()
            .setWidth(DimensionBuilders.expand())
            .setHeight(DimensionBuilders.dp(52f))
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .setVerticalAlignment(LayoutElementBuilders.VERTICAL_ALIGN_CENTER)
            .setModifiers(
                ModifiersBuilders.Modifiers.Builder()
                    .setBackground(
                        ModifiersBuilders.Background.Builder()
                            .setColor(ColorBuilders.argb(backgroundArgb))
                            .setCorner(
                                ModifiersBuilders.Corner.Builder()
                                    .setRadius(DimensionBuilders.dp(26f))
                                    .build(),
                            )
                            .build(),
                    )
                    .setClickable(clickable)
                    .build(),
            )
            .addContent(label)
            .build()
    }

    @Suppress("unused")
    private fun kept(): TypeBuilders.StringProp? = null
}
