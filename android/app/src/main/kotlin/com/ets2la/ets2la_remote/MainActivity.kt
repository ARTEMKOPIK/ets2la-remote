package com.ets2la.ets2la_remote

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ets2la_remote/multicast_lock"
    private var lock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
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
