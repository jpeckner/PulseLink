// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.bluetooth.BluetoothGattCharacteristic

/**
 * What a connection attempt should do, given whether the phone has
 * Bluetooth LE, whether the app may connect, and the adapter state.
 * Android's counterpart of iOS's ConnectAction.
 *
 * Pure, so it's unit-tested without a phone.
 */
sealed interface ConnectAction {
    /** Bluetooth is ready: connect. */
    data object Connect : ConnectAction

    /** Bluetooth is about to change state; the change will say what to do. */
    data object Wait : ConnectAction

    /** Bluetooth can't be used, for [reason]. */
    data class Fail(val reason: BleConnectFailureReason) : ConnectAction

    companion object {
        /**
         * [hasPermission] is whether BLUETOOTH_CONNECT is granted. A
         * connection doesn't ask for it: the scan that found the strap
         * already did, so it's missing only if the user has since revoked
         * it, and the app then offers Open Settings.
         */
        fun of(
            isSupported: Boolean,
            hasPermission: Boolean,
            adapter: AdapterState,
        ): ConnectAction {
            if (!isSupported) {
                return Fail(BleConnectFailureReason.UNSUPPORTED)
            }
            if (!hasPermission) {
                return Fail(BleConnectFailureReason.UNAUTHORIZED)
            }
            return when (adapter) {
                AdapterState.ON -> Connect
                AdapterState.OFF -> Fail(BleConnectFailureReason.POWERED_OFF)
                AdapterState.CHANGING -> Wait
            }
        }

        /**
         * Why finding the strap's heart rate failed. A GATT error means the
         * strap couldn't be asked (it dropped out mid-way, or didn't
         * answer), so it counts as unreachable, and trying again may work.
         * Only a strap that answered without one has no heart rate to offer.
         * The same rule as iOS's StrapConnection.discoveryFailure.
         */
        fun discoveryFailure(hadError: Boolean): BleConnectFailureReason =
            if (hadError) {
                BleConnectFailureReason.UNREACHABLE
            } else {
                BleConnectFailureReason.NOT_AHEART_RATE_STRAP
            }

        /** Whether a characteristic with [properties] sends notifications. */
        fun canNotify(properties: Int): Boolean = (properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0
    }
}
