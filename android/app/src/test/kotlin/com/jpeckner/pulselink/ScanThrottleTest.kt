package com.jpeckner.pulselink

import org.junit.Assert.assertEquals
import org.junit.Test

class ScanThrottleTest {
    @Test
    fun allowsFiveStartsWithoutWaiting() {
        val throttle = ScanThrottle()
        for (second in 0L until 5L) {
            assertEquals(0L, throttle.millisUntilNextStart(second * 1_000))
            throttle.recordStart(second * 1_000)
        }
    }

    @Test
    fun theSixthStartWaitsUntilTheFirstLeavesTheWindow() {
        val throttle = ScanThrottle()
        for (second in 0L until 5L) {
            throttle.recordStart(second * 1_000)
        }
        // The first start was at 0, so the window frees up at 30.5 s.
        assertEquals(25_500L, throttle.millisUntilNextStart(5_000))
        assertEquals(1L, throttle.millisUntilNextStart(30_499))
        assertEquals(0L, throttle.millisUntilNextStart(30_500))
    }

    @Test
    fun startsSpreadOutNeverWait() {
        val throttle = ScanThrottle()
        for (start in 0L until 20L) {
            val now = start * 10_000
            assertEquals(0L, throttle.millisUntilNextStart(now))
            throttle.recordStart(now)
        }
    }
}
