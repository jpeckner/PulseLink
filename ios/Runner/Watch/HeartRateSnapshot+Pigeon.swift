// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import Foundation

/// Turns the Pigeon snapshot Dart sends (pigeons/watch_api.dart) into the
/// shared `HeartRateSnapshot` the watch app decodes.
extension HeartRateSnapshot {
  /// Returns nil if `pigeon` is malformed: a bpm out of range, or a status or
  /// reading of a type this code doesn't know. Dart's own types rule out the
  /// first, and generating both sides together rules out the second, so nil
  /// means a bug.
  init?(_ pigeon: WatchHeartRateSnapshot) {
    let status: HeartRateStatus
    // Pigeon's sealed classes become plain protocols in Swift, which any
    // type could conform to, so this switch can't list every case.
    switch pigeon.status {
    case is WatchNoStrap:
      status = .noStrap
    case is WatchWaiting:
      status = .waiting
    case is WatchReceiving:
      status = .receiving
    case let failed as WatchFailed:
      status = .failed(StrapConnectionFailure(failed.failure))
    default:  // swiftlint:disable:this no_catch_all_cases
      return nil
    }

    let latestReading: HeartRateReading?
    if let pigeonReading = pigeon.latestReading {
      guard let reading = HeartRateReading(pigeonReading) else {
        return nil
      }
      latestReading = reading
    } else {
      latestReading = nil
    }

    self.init(
      sentAt: Date(millisecondsSince1970: pigeon.sentAtMillis),
      source: HeartRateSource(pigeon.source),
      status: status,
      latestReading: latestReading
    )
  }
}

extension HeartRateReading {
  /// Returns nil for a bpm out of range, or a reading type this code doesn't
  /// know.
  init?(_ pigeon: WatchHeartRateReading) {
    // See HeartRateSnapshot.init?(_:) for why this has a catch-all.
    switch pigeon {
    case let measured as WatchMeasuredReading:
      guard
        let value = Int(exactly: measured.beatsPerMinute),
        let beatsPerMinute = BeatsPerMinute(value)
      else {
        return nil
      }
      self = .measured(
        beatsPerMinute,
        measuredAt: Date(millisecondsSince1970: measured.measuredAtMillis)
      )
    case let unavailable as WatchUnavailableReading:
      self = .unavailable(
        HeartRateUnavailableReason(unavailable.reason),
        measuredAt: Date(millisecondsSince1970: unavailable.measuredAtMillis)
      )
    default:  // swiftlint:disable:this no_catch_all_cases
      return nil
    }
  }
}

extension HeartRateSource {
  init(_ pigeon: WatchHeartRateSource) {
    switch pigeon {
    case .demo:
      self = .demo
    case .strap:
      self = .strap
    }
  }
}

extension StrapConnectionFailure {
  init(_ pigeon: WatchStrapFailure) {
    switch pigeon {
    case .bluetoothOff:
      self = .bluetooth(.off)
    case .bluetoothUnavailable:
      self = .bluetooth(.unavailable)
    case .bluetoothPermissionDenied:
      self = .bluetooth(.permissionDenied)
    case .strapUnreachable:
      self = .strapUnreachable
    case .notAHeartRateStrap:
      self = .notAHeartRateStrap
    case .connectionLost:
      self = .connectionLost
    }
  }
}

extension HeartRateUnavailableReason {
  init(_ pigeon: WatchUnavailableReason) {
    switch pigeon {
    case .noSkinContact:
      self = .noSkinContact
    case .zeroBeatsPerMinute:
      self = .zeroBeatsPerMinute
    case .implausibleBeatsPerMinute:
      self = .implausibleBeatsPerMinute
    }
  }
}

extension Date {
  /// The time `milliseconds` after the start of 1970 (UTC), as Dart's
  /// `DateTime.millisecondsSinceEpoch` counts it.
  init(millisecondsSince1970 milliseconds: Int64) {
    self.init(timeIntervalSince1970: Double(milliseconds) / 1000)
  }
}
