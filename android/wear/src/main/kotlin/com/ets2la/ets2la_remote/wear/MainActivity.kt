package com.ets2la.ets2la_remote.wear

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext

/**
 * Two-button Wear OS remote. Tapping either button sends a [MessageClient]
 * message to every connected phone node; the paired Android phone's
 * [com.ets2la.ets2la_remote.WearMessageListenerService] picks it up and
 * forwards it into the Flutter isolate, where it runs the same Pages WS
 * toggle as the in-app / home-screen-widget buttons.
 */
class MainActivity : ComponentActivity() {

    companion object {
        const val PATH_TOGGLE_STEERING = "/ets2la/toggle_steering"
        const val PATH_TOGGLE_ACC = "/ets2la/toggle_acc"
    }

    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildLayout())
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    private fun buildLayout(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.BLACK)
            setPadding(dp(16), dp(16), dp(16), dp(16))
        }

        root.addView(TextView(this).apply {
            text = getString(R.string.title)
            setTextColor(Color.WHITE)
            textSize = 14f
            gravity = Gravity.CENTER
        })

        root.addView(spacer(dp(10)))

        root.addView(button(
            label = getString(R.string.toggle_autopilot),
            bgColor = 0xFFFF9500.toInt(),
            textColor = Color.BLACK,
        ) { send(PATH_TOGGLE_STEERING) })

        root.addView(spacer(dp(8)))

        root.addView(button(
            label = getString(R.string.toggle_acc),
            bgColor = 0xFF3A86FF.toInt(),
            textColor = Color.WHITE,
        ) { send(PATH_TOGGLE_ACC) })

        return root
    }

    private fun button(
        label: String,
        bgColor: Int,
        textColor: Int,
        onClick: () -> Unit,
    ): Button = Button(this).apply {
        text = label
        setTextColor(textColor)
        setBackgroundColor(bgColor)
        textSize = 16f
        setOnClickListener { onClick() }
    }

    private fun spacer(height: Int) = android.view.View(this).apply {
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, height
        )
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    private fun send(path: String) {
        scope.launch {
            val delivered = withContext(Dispatchers.IO) { broadcast(path) }
            val msg = if (delivered > 0) {
                getString(R.string.sent)
            } else {
                getString(R.string.no_phone)
            }
            Toast.makeText(this@MainActivity, msg, Toast.LENGTH_SHORT).show()
        }
    }

    /** Returns the number of connected phone nodes that accepted the message. */
    private suspend fun broadcast(path: String): Int {
        return try {
            val nodes: List<Node> =
                Wearable.getNodeClient(applicationContext).connectedNodes.await()
            if (nodes.isEmpty()) return 0
            val client = Wearable.getMessageClient(applicationContext)
            var ok = 0
            for (node in nodes) {
                try {
                    client.sendMessage(node.id, path, ByteArray(0)).await()
                    ok++
                } catch (_: Exception) {
                    // Individual node failure — keep trying the rest.
                }
            }
            ok
        } catch (_: Exception) {
            0
        }
    }
}
