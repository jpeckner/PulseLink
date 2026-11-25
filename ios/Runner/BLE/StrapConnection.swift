// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import CoreBluetooth

/// How a connection attempt ended. `Sendable`, so it can leave the main
/// actor; `BleStrapLink` turns it into Pigeon's `BleConnectResult`.
enum StrapConnectOutcome: Equatable, Sendable {
  /// Connected, and subscribed to Heart Rate Measurement notifications.
  case connected
  /// `disconnect()`, or a newer `connect`, ended the attempt first.
  case cancelled
  /// Couldn't connect, for this reason.
  case failed(BleConnectFailureReason)
}

/// Connects to one strap at a time, subscribes to its Heart Rate
/// Measurement characteristic (0x2A37), and sends each notification to Dart.
///
/// `@MainActor` for the same reasons as `CentralScan`: Flutter only accepts
/// messages on the main thread, and Flutter's calls and CoreBluetooth's
/// callbacks share this state. CoreBluetooth calls the delegate methods
/// below on the main queue because the manager is created with
/// `queue: nil`; each checks that, as `CentralScan` explains.
///
/// It has its own `CBCentralManager`, separate from `CentralScan`'s, which
/// Apple allows. Milestone 7's reliability work (reconnecting, staying
/// connected in the background) is the time to share one.
@MainActor
final class StrapConnection: NSObject {
  /// How long to wait for a strap before calling it unreachable.
  /// CoreBluetooth never gives up on a connection attempt by itself.
  private static let connectTimeoutNanoseconds: UInt64 = 10_000_000_000

  private let heartRateService = CBUUID(string: "180D")
  private let heartRateMeasurement = CBUUID(string: "2A37")
  // Optional: a strap without it connects the same, with no battery level.
  private let batteryService = CBUUID(string: "180F")
  private let batteryLevel = CBUUID(string: "2A19")

  /// Created on the first connection rather than at launch, like
  /// `CentralScan`'s.
  private var central: CBCentralManager?

  /// The strap being connected to, or connected; nil otherwise.
  private var strap: CBPeripheral?

  /// The attempt in progress, and how to finish it; nil otherwise.
  private var pending: PendingConnect?

  /// Ends the attempt in progress as unreachable once it's taken too long.
  private var timeout: Task<Void, Never>?

  /// Where strap events go while Dart is listening; nil otherwise.
  private var sink: PigeonEventSink<BleStrapEvent>?

  private struct PendingConnect {
    let strapId: UUID
    let continuation: CheckedContinuation<StrapConnectOutcome, Never>
  }

  /// Where a call that arrives off the main thread is reported.
  private let tracker: any ErrorTracker

  /// `nonisolated` so `BleStrapLink`, which has no actor isolation, can
  /// create one. It only sets up the properties above, which needs no
  /// particular thread.
  nonisolated init(tracker: any ErrorTracker) {
    self.tracker = tracker
    super.init()
  }

  /// Connects to the strap with `strapId` (from `BleStrapFound`) and
  /// subscribes to its heart rate. Ends any earlier connection or attempt
  /// first, which then finishes as `.cancelled`.
  func connect(strapId: String) async -> StrapConnectOutcome {
    disconnect()
    guard let id = UUID(uuidString: strapId) else {
      // Not an id iOS gave us, so there's no strap to reach.
      return .failed(.unreachable)
    }
    return await withCheckedContinuation { continuation in
      // `finish` is the only place that resumes this, and it takes
      // `pending` out first, so it's resumed exactly once.
      pending = PendingConnect(strapId: id, continuation: continuation)
      timeout = Task { [weak self] in
        do {
          try await Task.sleep(nanoseconds: Self.connectTimeoutNanoseconds)
        } catch {
          // Cancelled because the attempt already finished.
          return
        }
        self?.finish(.failed(.unreachable))
      }
      if central != nil {
        bluetoothStateChanged()
      } else {
        // Its first state arrives in centralManagerDidUpdateState.
        central = CBCentralManager(delegate: self, queue: nil)
      }
    }
  }

  /// Disconnects, ending an attempt in progress as `.cancelled`. Does
  /// nothing when not connected.
  func disconnect() {
    finish(.cancelled)
    dropStrap()
  }

  /// The battery level a Battery Level value holds: its first byte, which
  /// Dart checks is a percentage. Nil for an empty value.
  nonisolated static func batteryPercent(from value: Data) -> Int? {
    value.first.map { Int($0) }
  }

  /// Why finding the strap's heart rate failed. An error from CoreBluetooth
  /// means the strap couldn't be asked (it dropped out mid-way, or didn't
  /// answer), so it counts as unreachable, and trying again may work. Only
  /// a strap that answered without one has no heart rate to offer.
  nonisolated static func discoveryFailure(hadError: Bool) -> BleConnectFailureReason {
    hadError ? .unreachable : .notAHeartRateStrap
  }

  func startSending(to sink: PigeonEventSink<BleStrapEvent>) {
    self.sink = sink
  }

  func stopSending() {
    sink = nil
  }
}

/// CoreBluetooth reports Bluetooth state, and connections to the strap,
/// here. See `StrapConnection` for why each method checks the thread first.
extension StrapConnection: CBCentralManagerDelegate {
  nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
    guard isOnMainThread(reportingTo: tracker) else {
      return
    }
    MainActor.assumeIsolated {
      bluetoothStateChanged()
    }
  }

  nonisolated func centralManager(
    _ central: CBCentralManager,
    didConnect peripheral: CBPeripheral
  ) {
    guard isOnMainThread(reportingTo: tracker) else {
      return
    }
    let id = peripheral.identifier
    MainActor.assumeIsolated {
      strapConnected(id)
    }
  }

  nonisolated func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: (any Error)?
  ) {
    guard isOnMainThread(reportingTo: tracker) else {
      return
    }
    let id = peripheral.identifier
    MainActor.assumeIsolated {
      if isCurrentStrap(id) {
        finish(.failed(.unreachable))
      }
    }
  }

  nonisolated func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: (any Error)?
  ) {
    guard isOnMainThread(reportingTo: tracker) else {
      return
    }
    let id = peripheral.identifier
    MainActor.assumeIsolated {
      strapDisconnected(id)
    }
  }
}

/// CoreBluetooth reports what it finds on the strap, and its notifications,
/// here. See `StrapConnection` for why each method checks the thread first.
extension StrapConnection: CBPeripheralDelegate {
  nonisolated func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverServices error: (any Error)?
  ) {
    guard isOnMainThread(reportingTo: tracker) else {
      return
    }
    let id = peripheral.identifier
    let hadError = error != nil
    MainActor.assumeIsolated {
      servicesDiscovered(id, hadError: hadError)
    }
  }

  nonisolated func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: (any Error)?
  ) {
    guard isOnMainThread(reportingTo: tracker) else {
      return
    }
    let id = peripheral.identifier
    let serviceId = service.uuid.uuidString
    let hadError = error != nil
    MainActor.assumeIsolated {
      characteristicsDiscovered(id, serviceId: serviceId, hadError: hadError)
    }
  }

  nonisolated func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateNotificationStateFor characteristic: CBCharacteristic,
    error: (any Error)?
  ) {
    guard isOnMainThread(reportingTo: tracker) else {
      return
    }
    let id = peripheral.identifier
    let characteristicId = characteristic.uuid.uuidString
    let hadError = error != nil
    let isNotifying = characteristic.isNotifying
    MainActor.assumeIsolated {
      notificationsChanged(
        id,
        characteristicId: characteristicId,
        hadError: hadError,
        isNotifying: isNotifying
      )
    }
  }

  nonisolated func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: (any Error)?
  ) {
    guard isOnMainThread(reportingTo: tracker) else {
      return
    }
    let id = peripheral.identifier
    let characteristicId = characteristic.uuid.uuidString
    let value = characteristic.value
    MainActor.assumeIsolated {
      valueReceived(id, characteristicId: characteristicId, value: value)
    }
  }
}

private extension StrapConnection {
  func isCurrentStrap(_ id: UUID) -> Bool {
    strap?.identifier == id
  }

  /// Starts, fails or holds the attempt in progress, depending on the
  /// Bluetooth state, and notices Bluetooth going away mid-connection.
  func bluetoothStateChanged() {
    guard let central else {
      return
    }
    let action = ConnectAction(central.state)
    if let pending {
      switch action {
      case .connect:
        if strap == nil {
          startConnecting(to: pending.strapId, with: central)
        }
      case .fail(let reason):
        finish(.failed(reason))
      case .wait:
        break
      case .reset:
        // The strap iOS gave is no longer valid, so let go of it, and the
        // attempt starts over once Bluetooth is back. The timeout still
        // bounds the whole attempt.
        strap = nil
      }
      return
    }
    // Bluetooth going off or restarting drops the connection without a
    // disconnect callback.
    if action.dropsConnection, strap != nil {
      strap = nil
      sink?.success(BleStrapDisconnected())
    }
  }

  func startConnecting(to id: UUID, with central: CBCentralManager) {
    // Finds a strap iOS has seen before, such as in a scan.
    guard let found = central.retrievePeripherals(withIdentifiers: [id]).first else {
      finish(.failed(.unreachable))
      return
    }
    strap = found
    found.delegate = self
    central.connect(found)
  }

  func strapConnected(_ id: UUID) {
    guard pending != nil, let strap, strap.identifier == id else {
      return
    }
    strap.discoverServices([heartRateService, batteryService])
  }

  func servicesDiscovered(_ id: UUID, hadError: Bool) {
    guard pending != nil, let strap, strap.identifier == id else {
      return
    }
    guard
      !hadError,
      let service = strap.services?.first(where: { $0.uuid == heartRateService })
    else {
      finish(.failed(Self.discoveryFailure(hadError: hadError)))
      return
    }
    strap.discoverCharacteristics([heartRateMeasurement], for: service)
  }

  func characteristicsDiscovered(_ id: UUID, serviceId: String, hadError: Bool) {
    if serviceId == batteryService.uuidString {
      // The battery level is optional: after an error there's just no
      // characteristic to read, and the strap stays connected.
      batteryCharacteristicsDiscovered(id)
      return
    }
    guard pending != nil, let strap, strap.identifier == id else {
      return
    }
    let measurement = strap.services?
      .first(where: { $0.uuid == heartRateService })?
      .characteristics?
      .first(where: { $0.uuid == heartRateMeasurement })
    guard !hadError, let measurement, measurement.properties.contains(.notify) else {
      finish(.failed(Self.discoveryFailure(hadError: hadError)))
      return
    }
    // Finishes in peripheral(_:didUpdateNotificationStateFor:error:).
    strap.setNotifyValue(true, for: measurement)
  }

  /// Finishes connecting once heart-rate notifications are on, then reads
  /// the battery level. The battery's own notifications don't affect
  /// connecting.
  func notificationsChanged(
    _ id: UUID,
    characteristicId: String,
    hadError: Bool,
    isNotifying: Bool
  ) {
    guard isCurrentStrap(id), characteristicId == heartRateMeasurement.uuidString else {
      return
    }
    guard !hadError, isNotifying else {
      finish(.failed(Self.discoveryFailure(hadError: hadError)))
      return
    }
    finish(.connected)
    readBatteryLevel()
  }

  /// Starts reading the battery level, if the strap has the Battery
  /// Service. Only once connected, so the battery never delays connecting.
  func readBatteryLevel() {
    guard
      pending == nil,
      let strap,
      let service = strap.services?.first(where: { $0.uuid == batteryService })
    else {
      return
    }
    strap.discoverCharacteristics([batteryLevel], for: service)
  }

  func batteryCharacteristicsDiscovered(_ id: UUID) {
    guard pending == nil, let strap, strap.identifier == id else {
      return
    }
    let level = strap.services?
      .first(where: { $0.uuid == batteryService })?
      .characteristics?
      .first(where: { $0.uuid == batteryLevel })
    guard let level else {
      return
    }
    // The value arrives in peripheral(_:didUpdateValueFor:error:), now and,
    // if the strap supports it, whenever it changes.
    strap.readValue(for: level)
    if level.properties.contains(.notify) {
      strap.setNotifyValue(true, for: level)
    }
  }

  func valueReceived(_ id: UUID, characteristicId: String, value: Data?) {
    guard pending == nil, isCurrentStrap(id), let value else {
      return
    }
    if characteristicId == heartRateMeasurement.uuidString {
      sink?.success(BleHeartRateMeasurement(value: FlutterStandardTypedData(bytes: value)))
    } else if characteristicId == batteryLevel.uuidString,
      let percent = Self.batteryPercent(from: value)
    {
      sink?.success(BleBatteryLevel(percent: Int64(percent)))
    }
  }

  func strapDisconnected(_ id: UUID) {
    guard isCurrentStrap(id) else {
      // A strap this already let go of; nothing to report.
      return
    }
    if pending != nil {
      finish(.failed(.unreachable))
      return
    }
    strap = nil
    sink?.success(BleStrapDisconnected())
  }

  /// Ends the attempt in progress, if any, with `outcome`. Lets go of the
  /// strap unless it connected.
  func finish(_ outcome: StrapConnectOutcome) {
    guard let pending else {
      return
    }
    self.pending = nil
    timeout?.cancel()
    timeout = nil
    switch outcome {
    case .connected:
      break
    case .cancelled, .failed:
      dropStrap()
    }
    pending.continuation.resume(returning: outcome)
  }

  func dropStrap() {
    guard let strap else {
      return
    }
    self.strap = nil
    central?.cancelPeripheralConnection(strap)
  }
}
