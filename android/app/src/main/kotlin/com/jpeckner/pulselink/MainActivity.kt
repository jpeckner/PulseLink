package com.jpeckner.pulselink

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    /** Created with the engine; null before that and after it goes. */
    private var strapScanner: BleStrapScanner? = null
    private var strapLink: BleStrapLink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // The channels keep these for as long as the engine runs.
        val scanner = BleStrapScanner(this)
        strapScanner = scanner
        ScanForHeartRateStrapsStreamHandler.register(messenger, scanner)
        // The application context, since the connection may outlive this
        // activity once streaming continues in the background.
        val link = BleStrapLink(applicationContext)
        strapLink = link
        StrapEventsStreamHandler.register(messenger, link)
        BleConnectionApi.setUp(messenger, link)
        AppSettingsApi.setUp(messenger, AppSettingsOpener(this))
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Dart is going, so nothing will stop the scan or disconnect the
        // strap; both are let go of here.
        strapScanner?.close()
        strapScanner = null
        strapLink?.close()
        strapLink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        strapScanner?.onRequestPermissionsResult(requestCode, grantResults)
    }

    override fun onResume() {
        super.onResume()
        strapScanner?.onResume()
    }
}
