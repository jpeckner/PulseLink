// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothStatusCodes
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.UUID
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/** A GATT operation [LeConnection] runs through its [GattQueue]. */
sealed interface GattOperation {
    /** Finds the strap's services and characteristics. */
    data object DiscoverServices : GattOperation

    /** Turns on notifications for [characteristic] in [service]. */
    data class EnableNotifications(
        val service: UUID,
        val characteristic: UUID,
    ) : GattOperation

    /** Reads [characteristic] in [service] once. */
    data class ReadCharacteristic(
        val service: UUID,
        val characteristic: UUID,
    ) : GattOperation
}

/**
 * Connects to one strap at a time, subscribes to its Heart Rate Measurement
 * characteristic (0x2A37), and sends each notification to Dart, along with
 * the strap's battery level if it has one: Android's counterpart of iOS's
 * StrapConnection, and laid out the same way.
 *
 * Everything here runs on the main thread, the only thread Flutter accepts
 * messages to Dart from. Pigeon runs [connect] in a coroutine on the main
 * dispatcher, Flutter calls the rest there, and Android delivers the
 * Bluetooth state broadcast there. BluetoothGattCallback runs on a binder
 * thread, so each callback is posted to the main thread first, tagged with
 * its connection so a late one from a closed connection is ignored.
 *
 * GATT operations go through a [GattQueue], since Android runs only one at
 * a time.
 *
 * Permissions: connecting needs BLUETOOTH_CONNECT, which the scan that
 * found the strap asked for. [ConnectAction] checks it, and every call that
 * needs it also catches SecurityException, in case it's revoked in between.
 */
// The Bluetooth calls below need BLUETOOTH_CONNECT, which Android lint can't
// see is checked through ConnectAction; each also catches SecurityException.
@SuppressLint("MissingPermission")
class LeConnection(
    private val context: Context,
    private val tracker: ErrorTracker,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val adapter: BluetoothAdapter? =
        context.getSystemService(BluetoothManager::class.java)?.adapter

    private val queue =
        GattQueue<GattOperation>(
            scheduler =
                Scheduler { delayMillis, action ->
                    val runnable = Runnable(action)
                    mainHandler.postDelayed(runnable, delayMillis)
                    return@Scheduler { mainHandler.removeCallbacks(runnable) }
                },
            timeoutMillis = OPERATION_TIMEOUT_MILLIS,
            start = ::startOperation,
            fail = ::operationFailed,
        )

    /** Where strap events go while Dart is listening; null otherwise. */
    private var sink: PigeonEventSink<BleStrapEvent>? = null

    /** The attempt in progress, and how to finish it; null otherwise. */
    private var pending: PendingConnect? = null

    /** The connection being made, or made; null otherwise. */
    private var gatt: BluetoothGatt? = null

    /** [gatt]'s callback; callbacks from any other are late, and ignored. */
    private var gattCallback: StrapGattCallback? = null

    /** Ends the attempt in progress as unreachable once it's taken too long. */
    private var timeout: Runnable? = null

    /** Connects again after GATT error 133; null when no retry is waiting. */
    private var retry: Runnable? = null

    private var isReceiverRegistered = false

    /**
     * Bluetooth turning off drops the connection, and turning on lets an
     * attempt that was waiting go ahead.
     */
    private val stateReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                context: Context,
                intent: Intent,
            ) {
                applyCurrentState()
            }
        }

    private class PendingConnect(
        val strapId: String,
        val continuation: Continuation<BleConnectResult>,
    ) {
        /** Whether a GATT error 133 may still be retried. */
        var canRetry = true
    }

    /**
     * Connects to the strap with [strapId] (a MAC address from
     * `BleStrapFound`) and subscribes to its heart rate. Ends any earlier
     * connection or attempt first, which then finishes as cancelled.
     */
    suspend fun connect(strapId: String): BleConnectResult {
        disconnect()
        return suspendCoroutine { continuation ->
            // finish is the only place that resumes this, and it takes
            // `pending` out first, so it's resumed exactly once.
            pending = PendingConnect(strapId, continuation)
            val timeout =
                Runnable {
                    this.timeout = null
                    Log.w(TAG, "The strap didn't connect within ${CONNECT_TIMEOUT_MILLIS}ms")
                    finish(BleConnectFailed(BleConnectFailureReason.UNREACHABLE))
                }
            this.timeout = timeout
            mainHandler.postDelayed(timeout, CONNECT_TIMEOUT_MILLIS)
            registerReceiver()
            applyCurrentState()
        }
    }

    /**
     * Disconnects, ending an attempt in progress as cancelled. Does nothing
     * when not connected.
     */
    fun disconnect() {
        finish(BleConnectCancelled())
        release()
    }

    fun startSending(sink: PigeonEventSink<BleStrapEvent>) {
        this.sink = sink
    }

    fun stopSending() {
        sink = null
    }

    /**
     * Starts, fails or holds the attempt in progress, depending on the
     * Bluetooth state, and notices Bluetooth going away mid-connection.
     */
    private fun applyCurrentState() {
        val action =
            ConnectAction.of(
                isSupported =
                    adapter != null &&
                        context.packageManager.hasSystemFeature(
                            PackageManager.FEATURE_BLUETOOTH_LE,
                        ),
                hasPermission =
                    context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
                        PackageManager.PERMISSION_GRANTED,
                adapter = AdapterState.of(adapter?.state ?: BluetoothAdapter.STATE_OFF),
            )
        val pending = pending
        if (pending != null) {
            when (action) {
                ConnectAction.Connect ->
                    if (gatt == null && retry == null) {
                        startConnecting(pending.strapId)
                    }
                ConnectAction.Wait -> Unit
                is ConnectAction.Fail -> finish(BleConnectFailed(action.reason))
            }
            return
        }
        when (action) {
            ConnectAction.Connect, ConnectAction.Wait -> Unit
            // Android usually reports the disconnect too, but not always
            // when Bluetooth turns off.
            is ConnectAction.Fail -> strapDropped()
        }
    }

    private fun startConnecting(strapId: String) {
        // getRemoteDevice throws on a malformed address, so it's checked
        // first. Dart only passes ids from BleStrapFound, which are valid.
        val device =
            adapter
                ?.takeIf { BluetoothAdapter.checkBluetoothAddress(strapId) }
                ?.getRemoteDevice(strapId)
        if (device == null) {
            tracker.logError(TAG, "No strap with the id $strapId")
            finish(BleConnectFailed(BleConnectFailureReason.UNREACHABLE))
            return
        }
        val callback = StrapGattCallback()
        val gatt =
            try {
                // autoConnect false: connect now, directly, rather than
                // waiting in the background for the strap to appear. LE
                // transport, since some straps also offer classic Bluetooth.
                device.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
            } catch (error: SecurityException) {
                tracker.logError(TAG, "Connecting wasn't permitted", error)
                finish(BleConnectFailed(BleConnectFailureReason.UNAUTHORIZED))
                return
            }
        if (gatt == null) {
            Log.w(TAG, "Android couldn't start connecting")
            finish(BleConnectFailed(BleConnectFailureReason.UNREACHABLE))
            return
        }
        this.gatt = gatt
        gattCallback = callback
    }

    private fun connectionStateChanged(
        callback: StrapGattCallback,
        status: Int,
        newState: Int,
    ) {
        if (callback !== gattCallback) {
            return
        }
        val pending = pending
        val change =
            ConnectionChange.of(
                status = status,
                newState = newState,
                isConnecting = pending != null,
                canRetry = pending?.canRetry == true,
            )
        when (change) {
            ConnectionChange.DISCOVER -> queue.enqueue(GattOperation.DiscoverServices)
            ConnectionChange.RETRY -> retryConnecting()
            ConnectionChange.FAIL -> {
                Log.w(TAG, "Connecting failed with status $status")
                finish(BleConnectFailed(BleConnectFailureReason.UNREACHABLE))
            }
            ConnectionChange.DROPPED -> {
                Log.i(TAG, "The strap disconnected with status $status")
                strapDropped()
            }
            ConnectionChange.IGNORE -> Unit
        }
    }

    /** Closes the failed connection, and connects again after a pause. */
    private fun retryConnecting() {
        val pending = pending ?: return
        pending.canRetry = false
        Log.i(TAG, "GATT error 133; trying again in ${RETRY_DELAY_MILLIS}ms")
        closeGatt()
        val retry =
            Runnable {
                this.retry = null
                applyCurrentState()
            }
        this.retry = retry
        mainHandler.postDelayed(retry, RETRY_DELAY_MILLIS)
    }

    private fun servicesDiscovered(
        callback: StrapGattCallback,
        status: Int,
    ) {
        if (callback !== gattCallback) {
            return
        }
        when (queue.current) {
            GattOperation.DiscoverServices -> Unit
            // Not waiting for discovery: a late callback.
            is GattOperation.EnableNotifications, is GattOperation.ReadCharacteristic, null -> return
        }
        queue.finishCurrent()
        val gatt = gatt ?: return
        if (pending == null) {
            return
        }
        val hadError = status != BluetoothGatt.GATT_SUCCESS
        val measurement =
            gatt
                .getService(StrapUuids.HEART_RATE_SERVICE)
                ?.getCharacteristic(StrapUuids.HEART_RATE_MEASUREMENT)
        if (hadError || measurement == null || !ConnectAction.canNotify(measurement.properties)) {
            Log.w(TAG, "No heart rate notifications found (status $status)")
            finish(BleConnectFailed(ConnectAction.discoveryFailure(hadError)))
            return
        }
        // Finishes in notificationsEnabled.
        queue.enqueue(
            GattOperation.EnableNotifications(
                service = StrapUuids.HEART_RATE_SERVICE,
                characteristic = StrapUuids.HEART_RATE_MEASUREMENT,
            ),
        )
    }

    private fun descriptorWritten(
        callback: StrapGattCallback,
        characteristic: UUID,
        descriptor: UUID,
        status: Int,
    ) {
        if (callback !== gattCallback) {
            return
        }
        when (val op = queue.current) {
            is GattOperation.EnableNotifications -> {
                if (op.characteristic != characteristic ||
                    descriptor != StrapUuids.CLIENT_CHARACTERISTIC_CONFIG
                ) {
                    return
                }
                queue.finishCurrent()
                notificationsEnabled(op, status)
            }
            // Not waiting for a descriptor write: a late callback.
            GattOperation.DiscoverServices, is GattOperation.ReadCharacteristic, null -> Unit
        }
    }

    /**
     * Finishes connecting once heart-rate notifications are on, then reads
     * the battery level. The battery's own notifications don't affect
     * connecting.
     */
    private fun notificationsEnabled(
        op: GattOperation.EnableNotifications,
        status: Int,
    ) {
        val isSuccess = status == BluetoothGatt.GATT_SUCCESS
        if (op.characteristic != StrapUuids.HEART_RATE_MEASUREMENT) {
            if (!isSuccess) {
                // The level read after connecting still shows; it just
                // won't update.
                Log.i(TAG, "Turning on battery notifications failed with status $status")
            }
            return
        }
        if (pending == null) {
            return
        }
        if (!isSuccess) {
            Log.w(TAG, "Turning on heart rate notifications failed with status $status")
            finish(BleConnectFailed(ConnectAction.discoveryFailure(hadError = true)))
            return
        }
        finish(BleConnected())
        readBatteryLevel()
    }

    /**
     * Queues reading the battery level, and notifications of changes to
     * it, if the strap has the Battery Service. Only once connected, so the
     * battery never delays connecting.
     */
    private fun readBatteryLevel() {
        val gatt = gatt ?: return
        if (pending != null) {
            return
        }
        val level =
            gatt
                .getService(StrapUuids.BATTERY_SERVICE)
                ?.getCharacteristic(StrapUuids.BATTERY_LEVEL)
                ?: return
        // The value arrives in characteristicRead now and, if the strap
        // supports it, in characteristicChanged whenever it changes.
        queue.enqueue(
            GattOperation.ReadCharacteristic(
                service = StrapUuids.BATTERY_SERVICE,
                characteristic = StrapUuids.BATTERY_LEVEL,
            ),
        )
        if (ConnectAction.canNotify(level.properties)) {
            queue.enqueue(
                GattOperation.EnableNotifications(
                    service = StrapUuids.BATTERY_SERVICE,
                    characteristic = StrapUuids.BATTERY_LEVEL,
                ),
            )
        }
    }

    private fun characteristicRead(
        callback: StrapGattCallback,
        characteristic: UUID,
        value: ByteArray,
        status: Int,
    ) {
        if (callback !== gattCallback) {
            return
        }
        when (val op = queue.current) {
            is GattOperation.ReadCharacteristic -> {
                if (op.characteristic != characteristic) {
                    return
                }
                queue.finishCurrent()
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    // Optional, so the strap stays connected without it.
                    Log.i(TAG, "Reading $characteristic failed with status $status")
                    return
                }
                valueReceived(characteristic, value)
            }
            // Not waiting for a read: a late callback.
            GattOperation.DiscoverServices, is GattOperation.EnableNotifications, null -> Unit
        }
    }

    private fun characteristicChanged(
        callback: StrapGattCallback,
        characteristic: UUID,
        value: ByteArray,
    ) {
        if (callback !== gattCallback) {
            return
        }
        valueReceived(characteristic, value)
    }

    /** Sends a heart rate measurement or battery level on to Dart. */
    private fun valueReceived(
        characteristic: UUID,
        value: ByteArray,
    ) {
        // Values before connecting finished don't count, as on iOS.
        if (pending != null) {
            return
        }
        if (characteristic == StrapUuids.HEART_RATE_MEASUREMENT) {
            sink?.success(BleHeartRateMeasurement(value))
            return
        }
        if (characteristic == StrapUuids.BATTERY_LEVEL) {
            BatteryValue.percent(value)?.let { sink?.success(BleBatteryLevel(it.toLong())) }
        }
    }

    /** Starts [op] on the strap; false if Android refused. */
    private fun startOperation(op: GattOperation): Boolean {
        val gatt = gatt ?: return false
        return try {
            when (op) {
                GattOperation.DiscoverServices -> gatt.discoverServices()
                is GattOperation.EnableNotifications -> enableNotifications(gatt, op)
                is GattOperation.ReadCharacteristic -> {
                    val characteristic =
                        gatt.getService(op.service)?.getCharacteristic(op.characteristic)
                    characteristic != null && gatt.readCharacteristic(characteristic)
                }
            }
        } catch (error: SecurityException) {
            tracker.logError(TAG, "Starting $op wasn't permitted", error)
            false
        }
    }

    private fun enableNotifications(
        gatt: BluetoothGatt,
        op: GattOperation.EnableNotifications,
    ): Boolean {
        val characteristic =
            gatt.getService(op.service)?.getCharacteristic(op.characteristic) ?: return false
        val descriptor =
            characteristic.getDescriptor(StrapUuids.CLIENT_CHARACTERISTIC_CONFIG) ?: return false
        // Tells Android to pass the notifications on to the callback; the
        // descriptor write tells the strap to send them.
        if (!gatt.setCharacteristicNotification(characteristic, true)) {
            return false
        }
        val value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gatt.writeDescriptor(descriptor, value) == BluetoothStatusCodes.SUCCESS
        } else {
            writeDescriptorOnAndroid12(gatt, descriptor, value)
        }
    }

    /**
     * Android 13 deprecated this way of writing, which stores the value on
     * the descriptor object Android shares, but it's the only way on
     * Android 12.
     */
    @Suppress("DEPRECATION")
    private fun writeDescriptorOnAndroid12(
        gatt: BluetoothGatt,
        descriptor: BluetoothGattDescriptor,
        value: ByteArray,
    ): Boolean {
        descriptor.value = value
        return gatt.writeDescriptor(descriptor)
    }

    /**
     * An operation Android refused to start, or whose callback never came.
     * One that's part of connecting fails the attempt; a battery one is
     * optional, so the strap stays connected without it.
     */
    private fun operationFailed(op: GattOperation) {
        Log.w(TAG, "$op was refused or timed out")
        val isForConnecting =
            when (op) {
                GattOperation.DiscoverServices -> true
                is GattOperation.EnableNotifications -> op.characteristic == StrapUuids.HEART_RATE_MEASUREMENT
                is GattOperation.ReadCharacteristic -> false
            }
        if (isForConnecting) {
            finish(BleConnectFailed(BleConnectFailureReason.UNREACHABLE))
        }
    }

    /** Reports a connected strap that's gone, and lets go of it. */
    private fun strapDropped() {
        if (gatt == null) {
            return
        }
        release()
        sink?.success(BleStrapDisconnected())
    }

    /**
     * Ends the attempt in progress, if any, with [outcome]. Lets go of the
     * strap unless it connected.
     */
    private fun finish(outcome: BleConnectResult) {
        val pending = pending ?: return
        this.pending = null
        timeout?.let { mainHandler.removeCallbacks(it) }
        timeout = null
        retry?.let { mainHandler.removeCallbacks(it) }
        retry = null
        when (outcome) {
            is BleConnected -> Unit
            is BleConnectCancelled, is BleConnectFailed -> release()
        }
        pending.continuation.resume(outcome)
    }

    /** Closes the connection, and stops listening for Bluetooth changes. */
    private fun release() {
        closeGatt()
        if (isReceiverRegistered) {
            context.unregisterReceiver(stateReceiver)
            isReceiverRegistered = false
        }
    }

    private fun registerReceiver() {
        if (isReceiverRegistered) {
            return
        }
        context.registerReceiver(stateReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
        isReceiverRegistered = true
    }

    private fun closeGatt() {
        queue.clear()
        val gatt = gatt ?: return
        this.gatt = null
        gattCallback = null
        try {
            gatt.disconnect()
        } catch (error: SecurityException) {
            tracker.logError(TAG, "Disconnecting wasn't permitted", error)
        } finally {
            // Frees Android's connection slot, of which there are only a
            // few; without it, they stay taken until the app is killed.
            try {
                gatt.close()
            } catch (error: SecurityException) {
                tracker.logError(TAG, "Closing the connection wasn't permitted", error)
            }
        }
    }

    /** Passes each callback to the main thread, tagged with this connection. */
    private inner class StrapGattCallback : BluetoothGattCallback() {
        override fun onConnectionStateChange(
            gatt: BluetoothGatt,
            status: Int,
            newState: Int,
        ) {
            mainHandler.post { connectionStateChanged(this, status, newState) }
        }

        override fun onServicesDiscovered(
            gatt: BluetoothGatt,
            status: Int,
        ) {
            mainHandler.post { servicesDiscovered(this, status) }
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            val characteristic = descriptor.characteristic?.uuid ?: return
            val uuid = descriptor.uuid
            mainHandler.post { descriptorWritten(this, characteristic, uuid, status) }
        }

        /** Android 13 and later. */
        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
            status: Int,
        ) {
            val uuid = characteristic.uuid
            mainHandler.post { characteristicRead(this, uuid, value, status) }
        }

        /**
         * Android 12; Android 13 calls the one above instead. The value is
         * copied here, on the binder thread, as in onCharacteristicChanged.
         */
        @Deprecated("Replaced in Android 13 by the overload with a value parameter")
        @Suppress("DEPRECATION")
        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            val value = characteristic.value?.copyOf() ?: byteArrayOf()
            val uuid = characteristic.uuid
            mainHandler.post { characteristicRead(this, uuid, value, status) }
        }

        /** Android 13 and later. */
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            val uuid = characteristic.uuid
            mainHandler.post { characteristicChanged(this, uuid, value) }
        }

        /**
         * Android 12; Android 13 calls the one above instead. The value is
         * copied here, on the binder thread, because the next notification
         * overwrites the characteristic object's.
         */
        @Deprecated("Replaced in Android 13 by the overload with a value parameter")
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            val value = characteristic.value?.copyOf() ?: return
            val uuid = characteristic.uuid
            mainHandler.post { characteristicChanged(this, uuid, value) }
        }
    }

    private companion object {
        const val TAG = "LeConnection"

        /**
         * How long to wait for a strap before calling it unreachable, as on
         * iOS. Android gives up by itself only after about 30 seconds.
         */
        const val CONNECT_TIMEOUT_MILLIS = 10_000L

        /** How long to wait after GATT error 133 before trying again. */
        const val RETRY_DELAY_MILLIS = 600L

        /** How long a GATT operation may take before the queue moves on. */
        const val OPERATION_TIMEOUT_MILLIS = 5_000L
    }
}
