package com.jpeckner.pulselink

import android.bluetooth.BluetoothAdapter
import org.junit.Assert.assertEquals
import org.junit.Test

class ScanActionTest {
    @Test
    fun withoutBluetoothLeTheScanIsUnsupportedWhateverElseHolds() {
        for (permission in PermissionState.entries) {
            for (adapter in AdapterState.entries) {
                assertEquals(
                    ScanAction.Fail(BleScanFailureReason.UNSUPPORTED),
                    ScanAction.of(isSupported = false, permission = permission, adapter = adapter),
                )
            }
        }
    }

    @Test
    fun withoutPermissionItAsksWaitsOrFailsWhateverTheAdapter() {
        val expected =
            mapOf(
                PermissionState.NOT_ASKED to ScanAction.RequestPermission,
                PermissionState.ASKING to ScanAction.Wait,
                PermissionState.REFUSED to ScanAction.Fail(BleScanFailureReason.UNAUTHORIZED),
            )
        for ((permission, action) in expected) {
            for (adapter in AdapterState.entries) {
                assertEquals(
                    "$permission, $adapter",
                    action,
                    ScanAction.of(isSupported = true, permission = permission, adapter = adapter),
                )
            }
        }
    }

    @Test
    fun withPermissionTheAdapterDecides() {
        val expected =
            mapOf(
                AdapterState.ON to ScanAction.Scan,
                AdapterState.OFF to ScanAction.Fail(BleScanFailureReason.POWERED_OFF),
                AdapterState.CHANGING to ScanAction.Wait,
            )
        for ((adapter, action) in expected) {
            assertEquals(
                "$adapter",
                action,
                ScanAction.of(isSupported = true, permission = PermissionState.GRANTED, adapter = adapter),
            )
        }
    }

    @Test
    fun adapterStatesMapFromAndroidsValues() {
        assertEquals(AdapterState.ON, AdapterState.of(BluetoothAdapter.STATE_ON))
        assertEquals(AdapterState.OFF, AdapterState.of(BluetoothAdapter.STATE_OFF))
        assertEquals(AdapterState.CHANGING, AdapterState.of(BluetoothAdapter.STATE_TURNING_ON))
        assertEquals(AdapterState.CHANGING, AdapterState.of(BluetoothAdapter.STATE_TURNING_OFF))
        assertEquals(AdapterState.CHANGING, AdapterState.of(-1))
    }

    @Test
    fun theAdvertisedNameWinsOverTheCachedOne() {
        assertEquals("TICKR", ScanAction.strapName(advertised = "TICKR", cached = "Old name"))
        assertEquals("Old name", ScanAction.strapName(advertised = null, cached = "Old name"))
        assertEquals(null, ScanAction.strapName(advertised = null, cached = null))
    }
}
