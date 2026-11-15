package com.jpeckner.pulselink

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    /** Created with the engine; null before that. */
    private var strapScanner: BleStrapScanner? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // The channels keep these for as long as the engine runs.
        val scanner = BleStrapScanner(this)
        strapScanner = scanner
        ScanForHeartRateStrapsStreamHandler.register(messenger, scanner)
        val strapLink = BleStrapLink()
        StrapEventsStreamHandler.register(messenger, strapLink)
        BleConnectionApi.setUp(messenger, strapLink)
        AppSettingsApi.setUp(messenger, AppSettingsOpener(this))
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
