// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.bluetooth.BluetoothAdapter

/** Where the app stands on the Bluetooth permissions a scan needs. */
enum class PermissionState {
    /** Both BLUETOOTH_SCAN and BLUETOOTH_CONNECT are granted. */
    GRANTED,

    /** Not granted, and not yet asked for during this scan. */
    NOT_ASKED,

    /** The permission dialog is showing. */
    ASKING,

    /** Asked for during this scan, and refused. */
    REFUSED,
}

/** The Bluetooth adapter's state, as far as scanning cares. */
enum class AdapterState {
    ON,
    OFF,

    /** Turning on or off; the next state follows shortly. */
    CHANGING,
    ;

    companion object {
        /** Maps `BluetoothAdapter.getState()`'s value. */
        fun of(state: Int): AdapterState =
            when (state) {
                BluetoothAdapter.STATE_ON -> ON
                BluetoothAdapter.STATE_OFF -> OFF
                // STATE_TURNING_ON and STATE_TURNING_OFF, or a value a later
                // Android adds: wait for the next state change.
                else -> CHANGING
            }
    }
}

/**
 * What a scan should do, given whether the phone has Bluetooth LE, the
 * permission state and the adapter state. Android's counterpart of iOS's
 * ScanAction, with one more case: Android asks for permission explicitly,
 * where iOS asks by itself when the central manager is created.
 *
 * Pure, so it's unit-tested without a phone.
 */
sealed interface ScanAction {
    /** Start scanning, or keep scanning. */
    data object Scan : ScanAction

    /** Show the system permission dialog. */
    data object RequestPermission : ScanAction

    /** Do nothing until something changes. */
    data object Wait : ScanAction

    /** Tell Dart why the phone can't scan. */
    data class Fail(val reason: BleScanFailureReason) : ScanAction

    companion object {
        fun of(
            isSupported: Boolean,
            permission: PermissionState,
            adapter: AdapterState,
        ): ScanAction {
            if (!isSupported) {
                return Fail(BleScanFailureReason.UNSUPPORTED)
            }
            return when (permission) {
                PermissionState.NOT_ASKED -> RequestPermission
                PermissionState.ASKING -> Wait
                PermissionState.REFUSED -> Fail(BleScanFailureReason.UNAUTHORIZED)
                PermissionState.GRANTED ->
                    when (adapter) {
                        AdapterState.ON -> Scan
                        AdapterState.OFF -> Fail(BleScanFailureReason.POWERED_OFF)
                        AdapterState.CHANGING -> Wait
                    }
            }
        }

        /**
         * The name to show for a strap: the one in its advertisement, which
         * is current, or else the one Android cached from an earlier
         * connection.
         */
        fun strapName(
            advertised: String?,
            cached: String?,
        ): String? = advertised ?: cached
    }
}
