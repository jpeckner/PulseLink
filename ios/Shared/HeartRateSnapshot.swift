import Foundation

/// What the iPhone app tells the watch about the heart rate it's showing.
///
/// The phone sends the same snapshot two ways: as a live WatchConnectivity
/// message while the watch is reachable, and as the application context,
/// which the watch reads on launch. The watch ignores a snapshot sent
/// earlier than the one it's already showing, so the two can arrive in any
/// order.
///
/// Compiled into both the iOS app and the watch app. The phone encodes it
/// with `dictionary`, and the watch decodes it with `init?(dictionary:)`.
struct HeartRateSnapshot: Equatable, Sendable {
  /// When the phone sent this snapshot, by the phone's clock.
  let sentAt: Date

  /// Whether the heart rate comes from demo data or a strap.
  let source: HeartRateSource

  /// How getting heart-rate data is going.
  let status: HeartRateStatus

  /// The latest reading, or nil before the first one. It's kept after the
  /// strap fails, so the watch can still show the last bpm and when it was
  /// measured. It never says whether it's stale: the watch works that out
  /// from its timestamp.
  let latestReading: HeartRateReading?
}

/// Where the phone's heart rate comes from.
enum HeartRateSource: String, Sendable {
  /// The app's demo mode: simulated data, no strap.
  case demo

  /// A Bluetooth heart-rate strap.
  case strap
}

/// How getting heart-rate data is going on the phone. Mirrors the Dart
/// `LiveHeartRateState` cases.
enum HeartRateStatus: Equatable, Sendable {
  /// No strap has been picked on the phone.
  case noStrap

  /// Starting up or connecting; no reading since then.
  case waiting

  /// Readings are arriving.
  case receiving

  /// The phone can't get heart-rate data, for this reason.
  case failed(StrapConnectionFailure)
}

/// Why the phone can't get heart-rate data. Mirrors the Dart
/// `StrapConnectionFailure` in lib/domain/strap_connection_failure.dart.
enum StrapConnectionFailure: Equatable, Sendable {
  /// The phone can't use Bluetooth, for this reason.
  case bluetooth(BluetoothProblem)

  /// The strap is off, out of range, or connected to another app.
  case strapUnreachable

  /// The device doesn't offer the standard Heart Rate Service.
  case notAHeartRateStrap

  /// The strap was connected, then dropped.
  case connectionLost
}

/// Why the phone can't use Bluetooth. Mirrors the Dart `BluetoothProblem`.
enum BluetoothProblem: Sendable {
  /// Bluetooth is turned off.
  case off

  /// The phone can't use Bluetooth LE.
  case unavailable

  /// The user hasn't allowed the app to use Bluetooth.
  case permissionDenied
}

/// One heart-rate sample, stamped with when it was measured. Mirrors the
/// Dart `HeartRateSample`, without the parts the watch doesn't show.
enum HeartRateReading: Equatable, Sendable {
  /// A usable reading.
  case measured(BeatsPerMinute, measuredAt: Date)

  /// The strap is sending, but has no trustworthy heart rate.
  case unavailable(HeartRateUnavailableReason, measuredAt: Date)

  /// When the sample was measured, by the phone's clock.
  var measuredAt: Date {
    switch self {
    case .measured(_, let measuredAt), .unavailable(_, let measuredAt):
      return measuredAt
    }
  }
}

/// Why a sample has no trustworthy heart rate. Mirrors the Dart
/// `HeartRateUnavailableReason`.
enum HeartRateUnavailableReason: String, Sendable {
  /// The strap reports no skin contact.
  case noSkinContact

  /// The strap sent a bpm of 0, meaning it has no reading.
  case zeroBeatsPerMinute

  /// The strap sent a bpm too high to be a heartbeat.
  case implausibleBeatsPerMinute
}

// MARK: - Dictionary encoding

/// A snapshot as a WatchConnectivity dictionary, which holds only property
/// list types. For example:
///
///     [
///       "version": 1,
///       "kind": "heartRateSnapshot",
///       "sentAt": 1_794_000_000.0,            // seconds since 1970
///       "source": "strap",                     // or "demo"
///       "status": "failed",                    // or "waiting", "receiving"
///       "failure": "connectionLost",           // only when "failed"
///       "latestReading": [                     // absent before the first
///         "kind": "measured",                  // or "unavailable"
///         "bpm": 72,                           // only when "measured"
///         "reason": "noSkinContact",           // only when "unavailable"
///         "measuredAt": 1_794_000_000.0,
///       ],
///     ]
///
/// Decoding returns nil for anything malformed: a missing key, a value of
/// the wrong type, an unknown version, kind or code, a bpm out of range, or
/// a time that isn't a finite number. Keys it doesn't know are ignored.
extension HeartRateSnapshot {
  /// The message format's version. Decoding rejects any other, since the
  /// phone and watch apps ship together.
  static let version = 1

  /// Tells a snapshot apart from other kinds of message, such as the watch
  /// commands planned for later.
  static let kind = "heartRateSnapshot"

  /// This snapshot as a WatchConnectivity dictionary.
  var dictionary: [String: Any] {
    var dictionary: [String: Any] = [
      Field.version: Self.version,
      Field.kind: Self.kind,
      Field.sentAt: sentAt.timeIntervalSince1970,
      Field.source: source.rawValue,
    ]
    switch status {
    case .noStrap:
      dictionary[Field.status] = StatusCode.noStrap.rawValue
    case .waiting:
      dictionary[Field.status] = StatusCode.waiting.rawValue
    case .receiving:
      dictionary[Field.status] = StatusCode.receiving.rawValue
    case .failed(let failure):
      dictionary[Field.status] = StatusCode.failed.rawValue
      dictionary[Field.failure] = FailureCode(failure).rawValue
    }
    if let latestReading {
      dictionary[Field.latestReading] = latestReading.dictionary
    }
    return dictionary
  }

  /// Decodes a WatchConnectivity dictionary, or returns nil if it isn't a
  /// well-formed snapshot.
  init?(dictionary: [String: Any]) {
    guard
      dictionary[Field.version] as? Int == Self.version,
      dictionary[Field.kind] as? String == Self.kind,
      let sentAt = date(dictionary[Field.sentAt]),
      let sourceCode = dictionary[Field.source] as? String,
      let source = HeartRateSource(rawValue: sourceCode),
      let statusCode = dictionary[Field.status] as? String,
      let statusValue = StatusCode(rawValue: statusCode)
    else {
      return nil
    }

    let status: HeartRateStatus
    switch statusValue {
    case .noStrap:
      status = .noStrap
    case .waiting:
      status = .waiting
    case .receiving:
      status = .receiving
    case .failed:
      guard
        let failureCode = dictionary[Field.failure] as? String,
        let failure = FailureCode(rawValue: failureCode)
      else {
        return nil
      }
      status = .failed(failure.failure)
    }

    let latestReading: HeartRateReading?
    if let readingValue = dictionary[Field.latestReading] {
      // Present but malformed fails the whole snapshot, rather than
      // dropping the reading and showing a snapshot without one.
      guard
        let readingDictionary = readingValue as? [String: Any],
        let reading = HeartRateReading(dictionary: readingDictionary)
      else {
        return nil
      }
      latestReading = reading
    } else {
      latestReading = nil
    }

    self.init(
      sentAt: sentAt,
      source: source,
      status: status,
      latestReading: latestReading
    )
  }
}

extension HeartRateReading {
  /// This reading as a WatchConnectivity dictionary, as described on
  /// `HeartRateSnapshot`.
  var dictionary: [String: Any] {
    switch self {
    case .measured(let beatsPerMinute, let measuredAt):
      return [
        Field.kind: ReadingCode.measured.rawValue,
        Field.bpm: beatsPerMinute.value,
        Field.measuredAt: measuredAt.timeIntervalSince1970,
      ]
    case .unavailable(let reason, let measuredAt):
      return [
        Field.kind: ReadingCode.unavailable.rawValue,
        Field.reason: reason.rawValue,
        Field.measuredAt: measuredAt.timeIntervalSince1970,
      ]
    }
  }

  /// Decodes a reading's dictionary, or returns nil if it's malformed.
  init?(dictionary: [String: Any]) {
    guard
      let kindCode = dictionary[Field.kind] as? String,
      let kind = ReadingCode(rawValue: kindCode),
      let measuredAt = date(dictionary[Field.measuredAt])
    else {
      return nil
    }
    switch kind {
    case .measured:
      guard
        let value = dictionary[Field.bpm] as? Int,
        let beatsPerMinute = BeatsPerMinute(value)
      else {
        return nil
      }
      self = .measured(beatsPerMinute, measuredAt: measuredAt)
    case .unavailable:
      guard
        let reasonCode = dictionary[Field.reason] as? String,
        let reason = HeartRateUnavailableReason(rawValue: reasonCode)
      else {
        return nil
      }
      self = .unavailable(reason, measuredAt: measuredAt)
    }
  }
}

/// The dictionary keys.
private enum Field {
  static let version = "version"
  static let kind = "kind"
  static let sentAt = "sentAt"
  static let source = "source"
  static let status = "status"
  static let failure = "failure"
  static let latestReading = "latestReading"
  static let bpm = "bpm"
  static let reason = "reason"
  static let measuredAt = "measuredAt"
}

/// The `status` values.
private enum StatusCode: String {
  case noStrap
  case waiting
  case receiving
  case failed
}

/// The `kind` values of a reading.
private enum ReadingCode: String {
  case measured
  case unavailable
}

/// The `failure` values: one flat code per `StrapConnectionFailure`, so a
/// string can be turned back into a failure without a catch-all case.
private enum FailureCode: String {
  case bluetoothOff
  case bluetoothUnavailable
  case bluetoothPermissionDenied
  case strapUnreachable
  case notAHeartRateStrap
  case connectionLost

  init(_ failure: StrapConnectionFailure) {
    switch failure {
    case .bluetooth(.off):
      self = .bluetoothOff
    case .bluetooth(.unavailable):
      self = .bluetoothUnavailable
    case .bluetooth(.permissionDenied):
      self = .bluetoothPermissionDenied
    case .strapUnreachable:
      self = .strapUnreachable
    case .notAHeartRateStrap:
      self = .notAHeartRateStrap
    case .connectionLost:
      self = .connectionLost
    }
  }

  var failure: StrapConnectionFailure {
    switch self {
    case .bluetoothOff:
      return .bluetooth(.off)
    case .bluetoothUnavailable:
      return .bluetooth(.unavailable)
    case .bluetoothPermissionDenied:
      return .bluetooth(.permissionDenied)
    case .strapUnreachable:
      return .strapUnreachable
    case .notAHeartRateStrap:
      return .notAHeartRateStrap
    case .connectionLost:
      return .connectionLost
    }
  }
}

/// A time sent as seconds since 1970, or nil if `value` isn't a finite
/// number.
private func date(_ value: Any?) -> Date? {
  guard let seconds = value as? Double, seconds.isFinite else {
    return nil
  }
  return Date(timeIntervalSince1970: seconds)
}
