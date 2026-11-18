// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import org.junit.Assert.assertEquals
import org.junit.Test

class BatteryValueTest {
    @Test
    fun theFirstByteIsThePercentage() {
        assertEquals(80, BatteryValue.percent(byteArrayOf(80)))
        assertEquals(0, BatteryValue.percent(byteArrayOf(0)))
        assertEquals(100, BatteryValue.percent(byteArrayOf(100, 7)))
    }

    @Test
    fun bytesAbove127AreReadUnsignedForDartToReject() {
        assertEquals(200, BatteryValue.percent(byteArrayOf(200.toByte())))
        assertEquals(255, BatteryValue.percent(byteArrayOf(0xFF.toByte())))
    }

    @Test
    fun anEmptyValueHasNoLevel() {
        assertEquals(null, BatteryValue.percent(byteArrayOf()))
    }
}
