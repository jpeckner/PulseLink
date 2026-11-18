// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import Flutter

/// Connects to a strap for Dart (`BleConnectionApi`) and streams its events
/// (`strapEvents`), both declared in pigeons/ble_api.dart. Hands each call to
/// `StrapConnection`.
///
/// Not itself `@MainActor`: it subclasses Pigeon's generated stream handler,
/// which has no actor isolation, and a subclass can't change that.
final class BleStrapLink: StrapEventsStreamHandler {
  private let connection = StrapConnection()

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<BleStrapEvent>) {
    // See BleStrapScanner.onListen: Flutter calls this on the main thread,
    // and the sink is only used there.
    guard isOnMainThread() else {
      return
    }
    nonisolated(unsafe) let mainThreadSink = sink
    let connection = connection
    MainActor.assumeIsolated {
      connection.startSending(to: mainThreadSink)
    }
  }

  override func onCancel(withArguments arguments: Any?) {
    guard isOnMainThread() else {
      return
    }
    let connection = connection
    MainActor.assumeIsolated {
      connection.stopSending()
    }
  }
}

/// Dart's connect and disconnect calls.
extension BleStrapLink: BleConnectionApi {
  func connect(strapId: String) async throws -> BleConnectResult {
    // No thread check needed: awaiting a main-actor method runs it on the
    // main actor, whichever thread this started on.
    switch await connection.connect(strapId: strapId) {
    case .connected:
      return BleConnected()
    case .cancelled:
      return BleConnectCancelled()
    case .failed(let reason):
      return BleConnectFailed(reason: reason)
    }
  }

  func disconnect() throws {
    // Flutter calls this on the main thread. If it ever didn't, the
    // connection would stay up until the next connect or disconnect.
    guard isOnMainThread() else {
      return
    }
    let connection = connection
    MainActor.assumeIsolated {
      connection.disconnect()
    }
  }
}
