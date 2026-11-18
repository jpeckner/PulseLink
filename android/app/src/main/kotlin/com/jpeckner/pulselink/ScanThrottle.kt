// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

/**
 * Keeps scan starts under Android's limit. An app that starts more than 5
 * scans in 30 seconds has its next scans silently return nothing, with only
 * a log line ("App is scanning too frequently") to say why. Opening and
 * closing the picker, or toggling Bluetooth, can get there quickly.
 *
 * Pure, with the time passed in, so it's unit-tested without a phone.
 */
class ScanThrottle {
    private val starts = ArrayDeque<Long>()

    /** How long to wait before the next start, in milliseconds; 0 if none. */
    fun millisUntilNextStart(nowMillis: Long): Long {
        // Forget starts that have left the window.
        while (starts.firstOrNull()?.let { it <= nowMillis - WINDOW_MILLIS } == true) {
            starts.removeFirstOrNull()
        }
        if (starts.size < MAX_STARTS) {
            return 0
        }
        val oldest = starts.firstOrNull() ?: return 0
        return oldest + WINDOW_MILLIS - nowMillis
    }

    /** Records a scan started at [nowMillis]. */
    fun recordStart(nowMillis: Long) {
        starts.addLast(nowMillis)
    }

    private companion object {
        const val MAX_STARTS = 5

        /** Android's 30 seconds, plus a little margin for clock differences. */
        const val WINDOW_MILLIS = 30_500L
    }
}
