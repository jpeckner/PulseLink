// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.content.Context

/**
 * Connects to a strap for Dart (`BleConnectionApi`) and streams its events
 * (`strapEvents`), both declared in pigeons/ble_api.dart. Hands each call to
 * [LeConnection]. Flutter calls stream handlers and host APIs on the main
 * thread, and Pigeon runs [connect] on the main dispatcher, which is where
 * LeConnection expects to be called.
 */
class BleStrapLink(
    context: Context,
    tracker: ErrorTracker,
) :
    StrapEventsStreamHandler(),
    BleConnectionApi {
    private val connection = LeConnection(context, tracker)

    override fun onListen(
        p0: Any?,
        sink: PigeonEventSink<BleStrapEvent>,
    ) {
        connection.startSending(sink)
    }

    override fun onCancel(p0: Any?) {
        connection.stopSending()
    }

    override suspend fun connect(strapId: String): BleConnectResult = connection.connect(strapId)

    override fun disconnect() {
        connection.disconnect()
    }

    /**
     * Lets go of the strap when the Flutter engine goes, since Dart can't
     * any more. MainActivity calls it.
     */
    fun close() {
        connection.stopSending()
        connection.disconnect()
    }
}
