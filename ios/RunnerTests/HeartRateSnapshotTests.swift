import Foundation
import Testing

@testable import Runner

// Times are whole or half seconds, which survive the trip through seconds
// since 1970 exactly, so decoded snapshots compare equal.
private let sentAt = Date(timeIntervalSince1970: 1_794_000_010)
private let measuredAt = Date(timeIntervalSince1970: 1_794_000_009.5)

private func bpm(_ value: Int) throws -> BeatsPerMinute {
  try #require(BeatsPerMinute(value))
}

/// A well-formed snapshot dictionary, for tests to break one key at a time.
private func validDictionary() -> [String: Any] {
  [
    "version": 1,
    "kind": "heartRateSnapshot",
    "sentAt": 1_794_000_010.0,
    "source": "strap",
    "status": "receiving",
    "latestReading": [
      "kind": "measured",
      "bpm": 72,
      "measuredAt": 1_794_000_009.5,
    ] as [String: Any],
  ]
}

struct BeatsPerMinuteTests {
  @Test(arguments: [1, 72, 250])
  func acceptsPlausibleValues(value: Int) {
    #expect(BeatsPerMinute(value)?.value == value)
  }

  @Test(arguments: [Int.min, -1, 0, 251, 65_535, Int.max])
  func rejectsImplausibleValues(value: Int) {
    #expect(BeatsPerMinute(value) == nil)
  }
}

struct HeartRateSnapshotEncodingTests {
  @Test
  func decodesTheDocumentedFormat() throws {
    let snapshot = HeartRateSnapshot(dictionary: validDictionary())

    #expect(
      snapshot
        == HeartRateSnapshot(
          sentAt: sentAt,
          source: .strap,
          status: .receiving,
          latestReading: .measured(try bpm(72), measuredAt: measuredAt)
        )
    )
  }

  @Test
  func encodesTheDocumentedFormat() throws {
    let snapshot = HeartRateSnapshot(
      sentAt: sentAt,
      source: .strap,
      status: .failed(.connectionLost),
      latestReading: .unavailable(.noSkinContact, measuredAt: measuredAt)
    )

    let dictionary = snapshot.dictionary

    #expect(dictionary["version"] as? Int == 1)
    #expect(dictionary["kind"] as? String == "heartRateSnapshot")
    #expect(dictionary["sentAt"] as? Double == 1_794_000_010)
    #expect(dictionary["source"] as? String == "strap")
    #expect(dictionary["status"] as? String == "failed")
    #expect(dictionary["failure"] as? String == "connectionLost")
    let reading = try #require(dictionary["latestReading"] as? [String: Any])
    #expect(reading["kind"] as? String == "unavailable")
    #expect(reading["reason"] as? String == "noSkinContact")
    #expect(reading["measuredAt"] as? Double == 1_794_000_009.5)
    #expect(reading["bpm"] == nil)
  }

  @Test
  func leavesOutAMissingReadingAndFailure() {
    let snapshot = HeartRateSnapshot(
      sentAt: sentAt,
      source: .demo,
      status: .waiting,
      latestReading: nil
    )

    let dictionary = snapshot.dictionary

    #expect(dictionary["latestReading"] == nil)
    #expect(dictionary["failure"] == nil)
    #expect(HeartRateSnapshot(dictionary: dictionary) == snapshot)
  }

  @Test(arguments: [
    HeartRateStatus.noStrap,
    .waiting,
    .receiving,
    .failed(.bluetooth(.off)),
    .failed(.bluetooth(.unavailable)),
    .failed(.bluetooth(.permissionDenied)),
    .failed(.strapUnreachable),
    .failed(.notAHeartRateStrap),
    .failed(.connectionLost),
  ])
  func roundTripsEachStatus(status: HeartRateStatus) {
    let snapshot = HeartRateSnapshot(
      sentAt: sentAt,
      source: .strap,
      status: status,
      latestReading: nil
    )

    #expect(HeartRateSnapshot(dictionary: snapshot.dictionary) == snapshot)
  }

  @Test(arguments: [HeartRateSource.demo, .strap])
  func roundTripsEachSource(source: HeartRateSource) {
    let snapshot = HeartRateSnapshot(
      sentAt: sentAt,
      source: source,
      status: .receiving,
      latestReading: nil
    )

    #expect(HeartRateSnapshot(dictionary: snapshot.dictionary) == snapshot)
  }

  @Test(arguments: [
    HeartRateUnavailableReason.noSkinContact,
    .zeroBeatsPerMinute,
    .implausibleBeatsPerMinute,
  ])
  func roundTripsEachUnavailableReason(reason: HeartRateUnavailableReason) {
    let snapshot = HeartRateSnapshot(
      sentAt: sentAt,
      source: .strap,
      status: .receiving,
      latestReading: .unavailable(reason, measuredAt: measuredAt)
    )

    #expect(HeartRateSnapshot(dictionary: snapshot.dictionary) == snapshot)
  }

  @Test(arguments: [1, 72, 250])
  func roundTripsMeasuredReadings(value: Int) throws {
    let snapshot = HeartRateSnapshot(
      sentAt: sentAt,
      source: .strap,
      status: .failed(.strapUnreachable),
      latestReading: .measured(try bpm(value), measuredAt: measuredAt)
    )

    #expect(HeartRateSnapshot(dictionary: snapshot.dictionary) == snapshot)
  }

  @Test
  func ignoresKeysItDoesNotKnow() {
    var dictionary = validDictionary()
    dictionary["addedLater"] = "anything"

    #expect(HeartRateSnapshot(dictionary: dictionary) != nil)
  }

  @Test
  func ignoresAFailureWhenTheStatusIsNotFailed() {
    var dictionary = validDictionary()
    dictionary["failure"] = "connectionLost"

    #expect(HeartRateSnapshot(dictionary: dictionary)?.status == .receiving)
  }

  @Test
  func readingReportsWhenItWasMeasured() throws {
    #expect(
      HeartRateReading.measured(try bpm(72), measuredAt: measuredAt).measuredAt
        == measuredAt
    )
    #expect(
      HeartRateReading.unavailable(.zeroBeatsPerMinute, measuredAt: measuredAt)
        .measuredAt == measuredAt
    )
  }
}

/// One way to break a well-formed snapshot dictionary.
struct Malformation: CustomTestStringConvertible, Sendable {
  let testDescription: String
  let apply: @Sendable (inout [String: Any]) -> Void

  init(
    _ testDescription: String,
    _ apply: @escaping @Sendable (inout [String: Any]) -> Void
  ) {
    self.testDescription = testDescription
    self.apply = apply
  }

  /// Sets `key` in the snapshot's `latestReading` dictionary.
  static func reading(_ testDescription: String, _ key: String, _ value: Any?) -> Malformation
  {
    let value = UncheckedSendable(value)
    return Malformation(testDescription) { dictionary in
      guard var reading = dictionary["latestReading"] as? [String: Any] else {
        return
      }
      reading[key] = value.value
      dictionary["latestReading"] = reading
    }
  }

  /// Sets `key` in the snapshot dictionary.
  static func snapshot(_ testDescription: String, _ key: String, _ value: Any?) -> Malformation
  {
    let value = UncheckedSendable(value)
    return Malformation(testDescription) { dictionary in
      dictionary[key] = value.value
    }
  }
}

/// Carries a test's fixed property-list value into a `@Sendable` closure.
/// The values are literals that nothing mutates.
struct UncheckedSendable: @unchecked Sendable {
  let value: Any?

  init(_ value: Any?) {
    self.value = value
  }
}

struct HeartRateSnapshotDecodingTests {
  @Test
  func theUnbrokenDictionaryDecodes() {
    #expect(HeartRateSnapshot(dictionary: validDictionary()) != nil)
  }

  @Test(arguments: [
    // Missing keys.
    Malformation.snapshot("no version", "version", nil),
    .snapshot("no kind", "kind", nil),
    .snapshot("no sentAt", "sentAt", nil),
    .snapshot("no source", "source", nil),
    .snapshot("no status", "status", nil),
    .reading("no reading kind", "kind", nil),
    .reading("no measuredAt", "measuredAt", nil),
    .reading("no bpm", "bpm", nil),

    // Wrong types.
    .snapshot("version as a string", "version", "1"),
    .snapshot("kind as a number", "kind", 1),
    .snapshot("sentAt as a string", "sentAt", "1794000010"),
    .snapshot("sentAt as a date", "sentAt", Date(timeIntervalSince1970: 0)),
    .snapshot("source as a number", "source", 1),
    .snapshot("status as a number", "status", 1),
    .snapshot("latestReading as a string", "latestReading", "72"),
    .snapshot("latestReading as an array", "latestReading", [72]),
    .reading("bpm as a string", "bpm", "72"),
    .reading("bpm as a fraction", "bpm", 72.5),
    .reading("measuredAt as a string", "measuredAt", "1794000009.5"),

    // Unknown values.
    .snapshot("an older version", "version", 0),
    .snapshot("a newer version", "version", 2),
    .snapshot("another kind of message", "kind", "startSession"),
    .snapshot("an unknown source", "source", "simulator"),
    .snapshot("an unknown status", "status", "connecting"),
    .reading("an unknown reading kind", "kind", "estimated"),

    // Values out of range.
    .reading("bpm of 0", "bpm", 0),
    .reading("bpm of 251", "bpm", 251),
    .reading("negative bpm", "bpm", -72),
    .snapshot("sentAt not a number", "sentAt", Double.nan),
    .snapshot("sentAt infinite", "sentAt", Double.infinity),
    .reading("measuredAt infinite", "measuredAt", -Double.infinity),
  ])
  func rejects(_ malformation: Malformation) {
    var dictionary = validDictionary()
    malformation.apply(&dictionary)

    #expect(HeartRateSnapshot(dictionary: dictionary) == nil)
  }

  @Test
  func rejectsAFailedStatusWithoutAFailure() {
    var dictionary = validDictionary()
    dictionary["status"] = "failed"

    #expect(HeartRateSnapshot(dictionary: dictionary) == nil)
  }

  @Test
  func rejectsAnUnknownFailure() {
    var dictionary = validDictionary()
    dictionary["status"] = "failed"
    dictionary["failure"] = "strapOnFire"

    #expect(HeartRateSnapshot(dictionary: dictionary) == nil)
  }

  @Test
  func rejectsAnUnavailableReadingWithoutAKnownReason() {
    var dictionary = validDictionary()
    dictionary["latestReading"] = [
      "kind": "unavailable",
      "reason": "sensorAsleep",
      "measuredAt": 1_794_000_009.5,
    ] as [String: Any]

    #expect(HeartRateSnapshot(dictionary: dictionary) == nil)

    dictionary["latestReading"] = [
      "kind": "unavailable",
      "measuredAt": 1_794_000_009.5,
    ] as [String: Any]

    #expect(HeartRateSnapshot(dictionary: dictionary) == nil)
  }

  @Test
  func rejectsAnEmptyDictionary() {
    #expect(HeartRateSnapshot(dictionary: [:]) == nil)
  }
}
