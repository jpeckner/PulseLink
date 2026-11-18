// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.bluetooth.BluetoothGattCharacteristic
import org.junit.Assert.assertEquals
import org.junit.Test

class ConnectActionTest {
    @Test
    fun withoutBluetoothLeItFailsAsUnsupportedWhateverElseHolds() {
        for (hasPermission in listOf(true, false)) {
            for (adapter in AdapterState.entries) {
                assertEquals(
                    ConnectAction.Fail(BleConnectFailureReason.UNSUPPORTED),
                    ConnectAction.of(isSupported = false, hasPermission = hasPermission, adapter = adapter),
                )
            }
        }
    }

    @Test
    fun withoutPermissionItFailsAsUnauthorizedWhateverTheAdapter() {
        for (adapter in AdapterState.entries) {
            assertEquals(
                ConnectAction.Fail(BleConnectFailureReason.UNAUTHORIZED),
                ConnectAction.of(isSupported = true, hasPermission = false, adapter = adapter),
            )
        }
    }

    @Test
    fun withPermissionTheAdapterDecides() {
        val expected =
            mapOf(
                AdapterState.ON to ConnectAction.Connect,
                AdapterState.OFF to ConnectAction.Fail(BleConnectFailureReason.POWERED_OFF),
                AdapterState.CHANGING to ConnectAction.Wait,
            )
        for ((adapter, action) in expected) {
            assertEquals(
                "$adapter",
                action,
                ConnectAction.of(isSupported = true, hasPermission = true, adapter = adapter),
            )
        }
    }

    @Test
    fun aGattErrorDuringDiscoveryMeansUnreachable() {
        assertEquals(BleConnectFailureReason.UNREACHABLE, ConnectAction.discoveryFailure(hadError = true))
        assertEquals(
            BleConnectFailureReason.NOT_AHEART_RATE_STRAP,
            ConnectAction.discoveryFailure(hadError = false),
        )
    }

    @Test
    fun onlyTheNotifyPropertyCounts() {
        val notify = BluetoothGattCharacteristic.PROPERTY_NOTIFY
        val read = BluetoothGattCharacteristic.PROPERTY_READ
        val indicate = BluetoothGattCharacteristic.PROPERTY_INDICATE
        assertEquals(true, ConnectAction.canNotify(notify))
        assertEquals(true, ConnectAction.canNotify(notify or read))
        assertEquals(false, ConnectAction.canNotify(read or indicate))
        assertEquals(false, ConnectAction.canNotify(0))
    }
}
