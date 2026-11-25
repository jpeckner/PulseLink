// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.os.SystemClock

/**
 * Scans for heart-rate straps and turns what happens into scan events for
 * Dart: Android's counterpart of iOS's CentralScan.
 *
 * Everything here runs on the main thread, the only thread Flutter accepts
 * messages to Dart from. Flutter calls [start] and [stop] there, and Android
 * delivers permission results and the Bluetooth state broadcast there. Scan
 * results are posted to it, since Android doesn't promise which thread a
 * ScanCallback runs on.
 *
 * Permissions: a scan needs BLUETOOTH_SCAN, and naming and listing straps
 * needs BLUETOOTH_CONNECT. [ScanAction] decides when to ask for them, and
 * every call that needs them also catches SecurityException, in case they're
 * revoked in between.
 */
// The Bluetooth calls below need the permissions above, which Android lint
// can't see are checked through ScanAction; each also catches
// SecurityException.
@SuppressLint("MissingPermission")
class LeScan(
    private val activity: Activity,
    private val tracker: ErrorTracker,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val throttle = ScanThrottle()
    private val adapter: BluetoothAdapter? =
        activity.getSystemService(BluetoothManager::class.java)?.adapter

    /** Where events go while Dart is listening; null otherwise. */
    private var sink: PigeonEventSink<BleScanEvent>? = null

    /** The running scan's callback; null when not scanning. */
    private var scanCallback: ScanCallback? = null

    /** A start delayed by [throttle]; null when none is waiting. */
    private var pendingStart: Runnable? = null

    private var isAskingPermission = false
    private var wasPermissionRefused = false
    private var isReceiverRegistered = false

    /** Turning Bluetooth off stops a scan; turning it on resumes it here. */
    private val stateReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                context: Context,
                intent: Intent,
            ) {
                applyCurrentState()
            }
        }

    fun start(sink: PigeonEventSink<BleScanEvent>) {
        this.sink = sink
        // Each scan may ask again. If the user chose "Don't allow" twice
        // before, Android refuses straight away without showing the dialog.
        wasPermissionRefused = false
        if (!isReceiverRegistered) {
            activity.registerReceiver(
                stateReceiver,
                IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED),
            )
            isReceiverRegistered = true
        }
        applyCurrentState()
    }

    fun stop() {
        sink = null
        if (isReceiverRegistered) {
            activity.unregisterReceiver(stateReceiver)
            isReceiverRegistered = false
        }
        stopScanning()
    }

    /** Forwarded from `Activity.onRequestPermissionsResult`. */
    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray,
    ) {
        if (requestCode != PERMISSION_REQUEST_CODE) {
            return
        }
        isAskingPermission = false
        // Empty results mean the request was interrupted; treat it as a
        // refusal, so the picker explains rather than looking forever.
        val isGranted =
            grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        if (!isGranted) {
            wasPermissionRefused = true
        }
        applyCurrentState()
    }

    /**
     * Forwarded from `Activity.onResume`: the user may be back from Settings
     * having allowed Bluetooth, which Android doesn't announce otherwise.
     */
    fun onResume() {
        applyCurrentState()
    }

    private fun applyCurrentState() {
        val sink = sink ?: return
        when (val action = currentAction()) {
            ScanAction.Scan -> scanWhenAllowed()
            ScanAction.RequestPermission -> requestPermissions()
            ScanAction.Wait -> stopScanning()
            is ScanAction.Fail -> {
                stopScanning()
                sink.success(BleScanFailed(action.reason))
            }
        }
    }

    private fun currentAction(): ScanAction =
        ScanAction.of(
            isSupported =
                adapter != null &&
                    activity.packageManager.hasSystemFeature(
                        PackageManager.FEATURE_BLUETOOTH_LE,
                    ),
            permission = permissionState(),
            adapter = AdapterState.of(adapter?.state ?: BluetoothAdapter.STATE_OFF),
        )

    private fun permissionState(): PermissionState =
        when {
            hasPermissions() -> PermissionState.GRANTED
            isAskingPermission -> PermissionState.ASKING
            wasPermissionRefused -> PermissionState.REFUSED
            else -> PermissionState.NOT_ASKED
        }

    private fun hasPermissions(): Boolean =
        PERMISSIONS.all {
            activity.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
        }

    private fun requestPermissions() {
        if (isAskingPermission) {
            return
        }
        isAskingPermission = true
        activity.requestPermissions(PERMISSIONS, PERMISSION_REQUEST_CODE)
    }

    /** Starts scanning now, or as soon as [throttle] allows. */
    private fun scanWhenAllowed() {
        if (scanCallback != null || pendingStart != null) {
            return
        }
        val wait = throttle.millisUntilNextStart(SystemClock.elapsedRealtime())
        if (wait <= 0) {
            startScanning()
            return
        }
        tracker.logInfo(TAG, "Delaying the scan ${wait}ms to stay under Android's limit")
        val start =
            Runnable {
                pendingStart = null
                // Things may have changed while waiting.
                when (currentAction()) {
                    ScanAction.Scan -> startScanning()
                    ScanAction.RequestPermission,
                    ScanAction.Wait,
                    is ScanAction.Fail,
                    -> applyCurrentState()
                }
            }
        pendingStart = start
        mainHandler.postDelayed(start, wait)
    }

    private fun startScanning() {
        val sink = sink ?: return
        // Null for a moment while Bluetooth turns off or on; the state
        // broadcast that follows calls this again.
        val scanner = adapter?.bluetoothLeScanner ?: return
        val callback = StrapScanCallback()
        try {
            scanner.startScan(listOf(heartRateFilter), scanSettings, callback)
        } catch (error: SecurityException) {
            // The permission was revoked after it was checked.
            tracker.logError(TAG, "Starting the scan wasn't permitted", error)
            sink.success(BleScanFailed(BleScanFailureReason.UNAUTHORIZED))
            return
        } catch (error: IllegalStateException) {
            // Bluetooth turned off after it was checked; the state broadcast
            // that follows reports it.
            tracker.logWarning(TAG, "Bluetooth turned off before the scan started", error)
            return
        }
        throttle.recordStart(SystemClock.elapsedRealtime())
        scanCallback = callback
        sink.success(BleScanStarted())
        sendConnectedStraps(sink)
    }

    private fun stopScanning() {
        pendingStart?.let { mainHandler.removeCallbacks(it) }
        pendingStart = null
        val callback = scanCallback ?: return
        scanCallback = null
        try {
            adapter?.bluetoothLeScanner?.stopScan(callback)
        } catch (error: IllegalStateException) {
            // Bluetooth is already off, which stopped the scan.
            tracker.logInfo(TAG, "Bluetooth was off when stopping the scan", error)
        } catch (error: SecurityException) {
            // The permission was revoked, which stops scans too.
            tracker.logError(TAG, "Stopping the scan wasn't permitted", error)
        }
    }

    /**
     * Straps already connected to the phone, by this app or another, may
     * stop advertising, so the scan wouldn't find them. Android lists
     * connected devices, but only knows a device's services if it has cached
     * them, so this finds a connected strap only when it has. iOS's
     * retrieveConnectedPeripherals is more reliable here.
     */
    private fun sendConnectedStraps(sink: PigeonEventSink<BleScanEvent>) {
        val manager = activity.getSystemService(BluetoothManager::class.java) ?: return
        val devices =
            try {
                manager.getConnectedDevices(BluetoothProfile.GATT)
            } catch (error: SecurityException) {
                tracker.logError(TAG, "Listing connected straps wasn't permitted", error)
                return
            }
        for (device in devices) {
            val offersHeartRate =
                try {
                    device.uuids?.any { it.uuid == StrapUuids.HEART_RATE_SERVICE } == true
                } catch (error: SecurityException) {
                    tracker.logError(TAG, "Reading a device's services wasn't permitted", error)
                    false
                }
            if (offersHeartRate) {
                sink.success(
                    BleStrapFound(
                        id = device.address,
                        name = ScanAction.strapName(advertised = null, cached = cachedName(device)),
                        isConnected = true,
                    ),
                )
            }
        }
    }

    private fun cachedName(device: BluetoothDevice): String? =
        try {
            device.name
        } catch (error: SecurityException) {
            tracker.logError(TAG, "Reading a strap's name wasn't permitted", error)
            null
        }

    private fun onScanResult(
        callback: ScanCallback,
        result: ScanResult,
    ) {
        // A result from a scan that has since stopped.
        if (callback !== scanCallback) {
            return
        }
        val sink = sink ?: return
        sink.success(
            BleStrapFound(
                id = result.device.address,
                name =
                    ScanAction.strapName(
                        advertised = result.scanRecord?.deviceName,
                        cached = cachedName(result.device),
                    ),
                isConnected = false,
            ),
        )
    }

    private fun onScanFailed(
        callback: ScanCallback,
        errorCode: Int,
    ) {
        if (callback !== scanCallback) {
            return
        }
        scanCallback = null
        tracker.logError(TAG, "The scan failed with error $errorCode")
        if (errorCode == ScanCallback.SCAN_FAILED_FEATURE_UNSUPPORTED) {
            sink?.success(BleScanFailed(BleScanFailureReason.UNSUPPORTED))
        }
        // Other errors (out of resources, an internal error, scanning too
        // often) are transient and have no matching reason in the contract,
        // and "Bluetooth isn't available" would be wrong. The picker keeps
        // looking and shows its tips; reopening it scans again.
    }

    /** Passes each result to the main thread, tagged with this scan. */
    private inner class StrapScanCallback : ScanCallback() {
        override fun onScanResult(
            callbackType: Int,
            result: ScanResult,
        ) {
            mainHandler.post { onScanResult(this, result) }
        }

        override fun onBatchScanResults(results: List<ScanResult>) {
            mainHandler.post { results.forEach { onScanResult(this, it) } }
        }

        override fun onScanFailed(errorCode: Int) {
            mainHandler.post { onScanFailed(this, errorCode) }
        }
    }

    private companion object {
        const val TAG = "LeScan"
        const val PERMISSION_REQUEST_CODE = 0x180D

        val PERMISSIONS =
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
            )

        val heartRateFilter: ScanFilter =
            ScanFilter.Builder().setServiceUuid(ParcelUuid(StrapUuids.HEART_RATE_SERVICE)).build()

        /** Low latency: the picker is on screen, waiting for straps. */
        val scanSettings: ScanSettings =
            ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
    }
}
