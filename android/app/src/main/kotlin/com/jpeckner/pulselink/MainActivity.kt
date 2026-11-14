package com.jpeckner.pulselink

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The channel keeps the scanner for as long as the engine runs.
        ScanForHeartRateStrapsStreamHandler.register(
            flutterEngine.dartExecutor.binaryMessenger,
            BleStrapScanner(),
        )
    }
}
