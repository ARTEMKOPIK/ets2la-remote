package com.ets2la.ets2la_remote.wear

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Intent
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.MonochromaticImageComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.data.ComplicationText
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import android.graphics.drawable.Icon

/**
 * Watchface complication that renders the ETS2LA remote as a single
 * "AP" button on the watchface. Tapping the complication launches
 * [MainActivity] with `path=/ets2la/toggle_steering` so the user gets
 * one-tap Autopilot control from their watchface without opening the
 * watch app.
 */
class AutopilotComplicationService : SuspendingComplicationDataSourceService() {

    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        return when (type) {
            ComplicationType.SHORT_TEXT -> shortTextData(preview = true)
            ComplicationType.MONOCHROMATIC_IMAGE -> iconData(preview = true)
            else -> null
        }
    }

    override suspend fun onComplicationRequest(
        request: ComplicationRequest,
    ): ComplicationData? {
        return when (request.complicationType) {
            ComplicationType.SHORT_TEXT -> shortTextData(preview = false)
            ComplicationType.MONOCHROMATIC_IMAGE -> iconData(preview = false)
            else -> null
        }
    }

    private fun shortTextData(preview: Boolean): ShortTextComplicationData {
        val tap = PlainComplicationText.Builder(
            getString(R.string.toggle_autopilot),
        ).build()
        val label = PlainComplicationText.Builder("AP").build()
        val builder = ShortTextComplicationData.Builder(
            text = label,
            contentDescription = tap,
        )
        if (!preview) builder.setTapAction(toggleSteeringIntent())
        return builder.build()
    }

    private fun iconData(preview: Boolean): MonochromaticImageComplicationData {
        val icon = MonochromaticImage.Builder(
            Icon.createWithResource(this, android.R.drawable.ic_media_play),
        ).build()
        val cd: ComplicationText =
            PlainComplicationText.Builder(
                getString(R.string.toggle_autopilot),
            ).build()
        val builder = MonochromaticImageComplicationData.Builder(
            monochromaticImage = icon,
            contentDescription = cd,
        )
        if (!preview) builder.setTapAction(toggleSteeringIntent())
        return builder.build()
    }

    private fun toggleSteeringIntent(): PendingIntent {
        val intent = Intent().apply {
            component = ComponentName(
                packageName,
                "com.ets2la.ets2la_remote.wear.MainActivity",
            )
            putExtra("path", MainActivity.PATH_TOGGLE_STEERING)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
