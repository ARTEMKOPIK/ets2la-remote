package com.ets2la.ets2la_remote

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service that keeps the app process alive while connected to
 * ETS2LA so the WebSocket isn't torn down when the screen turns off.
 *
 * The service does no networking itself: the Dart isolate owns the socket.
 * We just need a foreground-promoted process so Android doesn't kill us.
 */
class KeepAliveService : Service() {

    companion object {
        const val CHANNEL_ID = "ets2la_keepalive"
        const val NOTIFICATION_ID = 17221

        const val ACTION_START = "ets2la.START"
        const val ACTION_UPDATE = "ets2la.UPDATE"
        const val ACTION_STOP = "ets2la.STOP"

        /** Forwarded to Dart via EXTRA_WIDGET_ACTION; consumed by ConnectionProvider. */
        const val ACTION_DISCONNECT = "com.ets2la.ets2la_remote.DISCONNECT"

        const val EXTRA_HOST = "host"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForegroundCompat()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE -> {
                val title = intent.getStringExtra(EXTRA_TITLE)
                    ?: getString(R.string.notification_title)
                val body = intent.getStringExtra(EXTRA_BODY) ?: ""
                postOrUpdateNotification(title, body)
                return START_STICKY
            }
            else -> {
                // ACTION_START (or initial start) — show notification and go foreground
                val host = intent?.getStringExtra(EXTRA_HOST) ?: ""
                val title = getString(R.string.notification_title)
                val body = if (host.isEmpty()) {
                    getString(R.string.notification_body_connected)
                } else {
                    getString(R.string.notification_body_connected_to, host)
                }
                startAsForeground(title, body)
                return START_STICKY
            }
        }
    }

    private fun startAsForeground(title: String, body: String) {
        ensureChannel()
        val notification = buildNotification(title, body)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun postOrUpdateNotification(title: String, body: String) {
        ensureChannel()
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(title, body))
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.notification_channel_description)
            setShowBadge(false)
        }
        nm.createNotificationChannel(channel)
    }

    private fun buildNotification(title: String, body: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pending = launchIntent?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pending)
            .addAction(
                0,
                getString(R.string.notification_action_autopilot),
                widgetActionPendingIntent(
                    AutopilotWidgetProvider.ACTION_TOGGLE_STEERING,
                ),
            )
            .addAction(
                0,
                getString(R.string.notification_action_acc),
                widgetActionPendingIntent(
                    AutopilotWidgetProvider.ACTION_TOGGLE_ACC,
                ),
            )
            .addAction(
                0,
                getString(R.string.notification_action_disconnect),
                widgetActionPendingIntent(ACTION_DISCONNECT),
            )
            .build()
    }

    /**
     * Build a PendingIntent that launches MainActivity carrying the given
     * widget-action extra. We piggyback on AutopilotWidgetProvider's
     * EXTRA_WIDGET_ACTION channel — MainActivity already knows how to drain
     * that extra and forward it to Dart via the widget MethodChannel.
     */
    private fun widgetActionPendingIntent(action: String): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            this.action = action
            putExtra(AutopilotWidgetProvider.EXTRA_WIDGET_ACTION, action)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        WidgetActionSecurity.attachToken(this, intent)
        return PendingIntent.getActivity(
            this,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    @Suppress("DEPRECATION")
    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
    }
}

/** Helper used from Flutter via MethodChannel. */
object KeepAlive {
    fun start(context: Context, host: String) {
        val intent = Intent(context, KeepAliveService::class.java)
            .setAction(KeepAliveService.ACTION_START)
            .putExtra(KeepAliveService.EXTRA_HOST, host)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    fun update(context: Context, title: String, body: String) {
        val intent = Intent(context, KeepAliveService::class.java)
            .setAction(KeepAliveService.ACTION_UPDATE)
            .putExtra(KeepAliveService.EXTRA_TITLE, title)
            .putExtra(KeepAliveService.EXTRA_BODY, body)
        context.startService(intent)
    }

    fun stop(context: Context) {
        val intent = Intent(context, KeepAliveService::class.java)
            .setAction(KeepAliveService.ACTION_STOP)
        context.startService(intent)
    }
}
