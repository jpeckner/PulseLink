package com.jpeckner.pulselink

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // The channels keep these for as long as the engine runs.
        ScanForHeartRateStrapsStreamHandler.register(messenger, BleStrapScanner())
        val strapLink = BleStrapLink()
        StrapEventsStreamHandler.register(messenger, strapLink)
        BleConnectionApi.setUp(messenger, strapLink)
    }
}
