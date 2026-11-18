// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothProfile
import org.junit.Assert.assertEquals
import org.junit.Test

class ConnectionChangeTest {
    private val success = BluetoothGatt.GATT_SUCCESS
    private val gattError = ConnectionChange.GATT_ERROR
    private val connected = BluetoothProfile.STATE_CONNECTED
    private val disconnected = BluetoothProfile.STATE_DISCONNECTED

    /** Android's "connection timed out" status, as an example of another error. */
    private val timedOut = 8

    private fun connecting(
        status: Int,
        newState: Int,
        canRetry: Boolean = true,
    ) = ConnectionChange.of(status, newState, isConnecting = true, canRetry = canRetry)

    @Test
    fun connectingSuccessfullyDiscoversServices() {
        assertEquals(ConnectionChange.DISCOVER, connecting(success, connected))
    }

    @Test
    fun gattError133RetriesOnce() {
        assertEquals(ConnectionChange.RETRY, connecting(gattError, disconnected))
        assertEquals(ConnectionChange.FAIL, connecting(gattError, disconnected, canRetry = false))
    }

    @Test
    fun otherErrorsWhileConnectingFailWithoutRetrying() {
        assertEquals(ConnectionChange.FAIL, connecting(timedOut, disconnected))
        // A clean disconnect before connecting finished.
        assertEquals(ConnectionChange.FAIL, connecting(success, disconnected))
        // "Connected" with an error status isn't a connection.
        assertEquals(ConnectionChange.FAIL, connecting(timedOut, connected))
    }

    @Test
    fun statesOnTheWayAreIgnored() {
        assertEquals(ConnectionChange.IGNORE, connecting(success, BluetoothProfile.STATE_CONNECTING))
        assertEquals(ConnectionChange.IGNORE, connecting(success, BluetoothProfile.STATE_DISCONNECTING))
    }

    @Test
    fun onceConnectedAnyDisconnectIsADrop() {
        for (status in listOf(success, gattError, timedOut)) {
            assertEquals(
                ConnectionChange.DROPPED,
                ConnectionChange.of(status, disconnected, isConnecting = false, canRetry = true),
            )
        }
        assertEquals(
            ConnectionChange.IGNORE,
            ConnectionChange.of(success, connected, isConnecting = false, canRetry = false),
        )
    }
}
