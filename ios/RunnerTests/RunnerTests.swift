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
    (.resetting, .wait),
  ])
  func eachBluetoothStateHasAnAction(state: CBManagerState, action: ConnectAction) {
    #expect(ConnectAction(state) == action)
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
