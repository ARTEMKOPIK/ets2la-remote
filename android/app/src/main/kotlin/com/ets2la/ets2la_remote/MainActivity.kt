package com.ets2la.ets2la_remote

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val multicastChannel = "ets2la_remote/multicast_lock"
    private val keepAliveChannel = "ets2la_remote/keepalive"
    private val widgetChannel = "ets2la_remote/widget"
    private val installPermissionChannel = "ets2la_remote/install_permission"
    private var lock: WifiManager.MulticastLock? = null

    /** Last widget action received before Dart had a chance to consume it. */
    private var pendingWidgetAction: String? = null
    private var widgetChannelRef: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, multicastChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquire" -> {
                        acquireLock()
                        result.success(null)
                    }
                    "release" -> {
                        releaseLock()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, keepAliveChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val host = call.argument<String>("host") ?: ""
                        KeepAlive.start(applicationContext, host)
                        result.success(null)
                    }
                    "update" -> {
                        val title = call.argument<String>("title") ?: "ETS2LA Remote"
                        val body = call.argument<String>("body") ?: ""
                        KeepAlive.update(applicationContext, title, body)
                        result.success(null)
                    }
                    "stop" -> {
                        KeepAlive.stop(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        widgetChannelRef = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            widgetChannel,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialAction" -> {
                        val action = pendingWidgetAction
                        pendingWidgetAction = null
                        result.success(action)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installPermissionChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Android 8+ gates APK installs behind a per-app "Install
                    // unknown apps" toggle that is NOT granted by declaring
                    // REQUEST_INSTALL_PACKAGES in the manifest — the user has
                    // to flip it themselves in Settings. Dart asks us for the
                    // current state (or to launch the settings screen).
                    "canInstall" -> {
                        val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            packageManager.canRequestPackageInstalls()
                        } else {
                            true
                        }
                        result.success(ok)
                    }
                    "openSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName"),
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Consume the intent that started the activity (cold start from widget).
        consumeWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        consumeWidgetIntent(intent)
    }

    private fun consumeWidgetIntent(intent: Intent?) {
        val action = intent?.getStringExtra(AutopilotWidgetProvider.EXTRA_WIDGET_ACTION)
            ?: return
        val channel = widgetChannelRef
        if (channel != null) {
            channel.invokeMethod("widgetAction", action)
        } else {
            pendingWidgetAction = action
        }
    }

    private fun acquireLock() {
        if (lock?.isHeld == true) return
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        lock = wifi.createMulticastLock("ets2la-mdns").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseLock() {
        lock?.let { if (it.isHeld) it.release() }
        lock = null
    }

    override fun onDestroy() {
        releaseLock()
        super.onDestroy()
    }
}
