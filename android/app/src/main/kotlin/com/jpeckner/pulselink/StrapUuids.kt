package com.jpeckner.pulselink

import java.util.UUID

/** The Bluetooth SIG's UUIDs for what PulseLink uses on a strap. */
object StrapUuids {
    /** The Heart Rate Service, 0x180D: what scans filter on. */
    val HEART_RATE_SERVICE: UUID = UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")

    /** The Heart Rate Measurement characteristic, 0x2A37. */
    val HEART_RATE_MEASUREMENT: UUID = UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb")

    /**
     * The Client Characteristic Configuration descriptor, 0x2902. Writing
     * to it tells the strap to send a characteristic's notifications.
     */
    val CLIENT_CHARACTERISTIC_CONFIG: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
}
