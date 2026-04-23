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
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "ETS2LA Remote"
                val body = intent.getStringExtra(EXTRA_BODY) ?: ""
                postOrUpdateNotification(title, body)
                return START_STICKY
            }
            else -> {
                // ACTION_START (or initial start) — show notification and go foreground
                val host = intent?.getStringExtra(EXTRA_HOST) ?: ""
                val title = "ETS2LA Remote"
                val body = if (host.isEmpty()) "Connected" else "Connected to $host"
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
            "Connection",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps the connection to ETS2LA alive while the screen is off."
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
            .build()
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
