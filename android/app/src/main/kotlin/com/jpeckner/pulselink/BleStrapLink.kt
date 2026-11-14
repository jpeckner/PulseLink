package com.jpeckner.pulselink

/**
 * Answers Dart's strap connection calls (`BleConnectionApi` and
 * `strapEvents`, see pigeons/ble_api.dart) until Android BLE arrives: every
 * connection fails as unsupported, so the app explains that Bluetooth isn't
 * available, and the event stream sends nothing.
 */
class BleStrapLink :
    StrapEventsStreamHandler(),
    BleConnectionApi {
    override suspend fun connect(strapId: String): BleConnectResult =
        BleConnectFailed(BleConnectFailureReason.UNSUPPORTED)

    override fun disconnect() = Unit
}
