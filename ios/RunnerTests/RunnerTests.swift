// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import CoreBluetooth
import Foundation
import Testing

@testable import Runner

struct ScanActionTests {
  @Test(arguments: [
    (CBManagerState.poweredOn, ScanAction.scan),
    (.poweredOff, .fail(.poweredOff)),
    (.unauthorized, .fail(.unauthorized)),
    (.unsupported, .fail(.unsupported)),
    (.unknown, .wait),
    (.resetting, .wait),
  ])
  func eachBluetoothStateHasAnAction(state: CBManagerState, action: ScanAction) {
    #expect(ScanAction(state) == action)
  }
}

struct ConnectActionTests {
  @Test(arguments: [
    (CBManagerState.poweredOn, ConnectAction.connect),
    (.poweredOff, .fail(.poweredOff)),
    (.unauthorized, .fail(.unauthorized)),
    (.unsupported, .fail(.unsupported)),
    (.unknown, .wait),
    (.resetting, .reset),
  ])
  func eachBluetoothStateHasAnAction(state: CBManagerState, action: ConnectAction) {
    #expect(ConnectAction(state) == action)
  }

  // iOS calls no disconnect callback when Bluetooth goes off or restarts,
  // so StrapConnection reports the drop itself in these states.
  @Test(arguments: [
    (ConnectAction.connect, false),
    (.wait, false),
    (.fail(.poweredOff), true),
    (.fail(.unauthorized), true),
    (.fail(.unsupported), true),
    (.reset, true),
  ])
  func dropsAConnectedStrapWhenBluetoothGoesOffOrRestarts(
    action: ConnectAction,
    drops: Bool
  ) {
    #expect(action.dropsConnection == drops)
  }
}

struct BatteryPercentTests {
  @Test func readsTheFirstByte() {
    #expect(StrapConnection.batteryPercent(from: Data([0x55])) == 85)
  }

  @Test func passesOnAnyByteForDartToCheck() {
    #expect(StrapConnection.batteryPercent(from: Data([0xFF])) == 255)
  }

  @Test func hasNoLevelForAnEmptyValue() {
    #expect(StrapConnection.batteryPercent(from: Data()) == nil)
  }
}

struct DiscoveryFailureTests {
  @Test func anErrorMeansTheStrapCouldNotBeReached() {
    #expect(StrapConnection.discoveryFailure(hadError: true) == .unreachable)
  }

  @Test func noErrorMeansTheStrapHasNoHeartRate() {
    #expect(StrapConnection.discoveryFailure(hadError: false) == .notAHeartRateStrap)
  }
}

struct StrapNameTests {
  @Test func prefersTheAdvertisedName() {
    #expect(CentralScan.strapName(advertised: "TICKR", cached: "Old name") == "TICKR")
  }

  @Test func fallsBackToTheCachedName() {
    #expect(CentralScan.strapName(advertised: nil, cached: "Polar H10") == "Polar H10")
  }

  @Test func hasNoNameWhenThereIsNone() {
    #expect(CentralScan.strapName(advertised: nil, cached: nil) == nil)
  }
}
