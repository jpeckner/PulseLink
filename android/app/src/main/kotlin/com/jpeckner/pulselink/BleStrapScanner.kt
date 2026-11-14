package com.jpeckner.pulselink

/**
 * Answers `scanForHeartRateStraps` (see pigeons/ble_api.dart) until Android
 * scanning arrives: every scan reports that it's unsupported, so the app
 * explains that Bluetooth isn't available rather than looking forever.
 */
class BleStrapScanner : ScanForHeartRateStrapsStreamHandler() {
    override fun onListen(p0: Any?, sink: PigeonEventSink<BleScanEvent>) {
        sink.success(BleScanFailed(BleScanFailureReason.UNSUPPORTED))
    }
}
