package com.jpeckner.pulselink

/**
 * Reads a Battery Level characteristic's value (0x2A19).
 *
 * Pure, so it's unit-tested without a phone.
 */
object BatteryValue {
    /**
     * The battery level the value holds: its first byte, unsigned, which
     * Dart checks is a percentage. Null for an empty value. The same rule
     * as iOS's StrapConnection.batteryPercent.
     */
    fun percent(value: ByteArray): Int? = value.firstOrNull()?.toInt()?.and(BYTE_MASK)

    /** Kotlin's Byte is signed; this reads it as 0 to 255. */
    private const val BYTE_MASK = 0xFF
}
