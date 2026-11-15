package com.jpeckner.pulselink

import android.app.Activity

/**
 * Scans for heart-rate straps while Dart listens to `scanForHeartRateStraps`
 * (see pigeons/ble_api.dart), and stops when Dart cancels. Hands each call to
 * [LeScan]. Flutter calls stream handlers on the main thread, which is where
 * LeScan expects to be called.
 *
 * [activity] shows the permission dialog; MainActivity forwards its result,
 * and its resumes, here.
 */
class BleStrapScanner(activity: Activity) : ScanForHeartRateStrapsStreamHandler() {
    private val scan = LeScan(activity)

    override fun onListen(
        p0: Any?,
        sink: PigeonEventSink<BleScanEvent>,
    ) {
        scan.start(sink)
    }

    override fun onCancel(p0: Any?) {
        scan.stop()
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray,
    ) {
        scan.onRequestPermissionsResult(requestCode, grantResults)
    }

    fun onResume() {
        scan.onResume()
    }
}
