package com.jpeckner.pulselink

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothProfile

/**
 * What to do when `BluetoothGattCallback.onConnectionStateChange` reports a
 * change to the strap's connection.
 *
 * Pure, so it's unit-tested without a phone.
 */
enum class ConnectionChange {
    /** Connected while connecting: find the strap's services next. */
    DISCOVER,

    /** Failed with GATT error 133 while connecting: close, wait and try again. */
    RETRY,

    /** Failed while connecting: the strap is unreachable. */
    FAIL,

    /** Disconnected after connecting: the strap dropped. */
    DROPPED,

    /** Nothing to act on, such as a state on the way to another one. */
    IGNORE,
    ;

    companion object {
        /**
         * Android's GATT_ERROR. Android doesn't name it publicly, but it's
         * the most common way a connection attempt fails, often for reasons
         * that go away on a second try: the Bluetooth stack was busy, or the
         * strap's advertisement was missed.
         */
        const val GATT_ERROR = 133

        /**
         * [status] and [newState] are as Android passes them.
         * [isConnecting] is whether a connection attempt is in progress, and
         * [canRetry] whether it may still be retried.
         */
        fun of(
            status: Int,
            newState: Int,
            isConnecting: Boolean,
            canRetry: Boolean,
        ): ConnectionChange {
            val isConnected = newState == BluetoothProfile.STATE_CONNECTED
            val isDisconnected = newState == BluetoothProfile.STATE_DISCONNECTED
            if (!isConnecting) {
                // Once connected, any status on a disconnect means the same:
                // the strap is gone.
                return if (isDisconnected) DROPPED else IGNORE
            }
            return when {
                isConnected && status == BluetoothGatt.GATT_SUCCESS -> DISCOVER
                !isConnected && !isDisconnected -> IGNORE
                status == GATT_ERROR && canRetry -> RETRY
                else -> FAIL
            }
        }
    }
}
