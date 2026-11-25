// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

// The contract between Dart and the iPhone's WatchConnectivity code, which
// passes the live heart rate on to the Apple Watch app. Pigeon generates the
// Dart and Swift sides from this file. Regenerate with tool/regenerate.sh.
//
// There's no Kotlin side: there's no watch app on Android, so the app doesn't
// use this API there.
//
// Only the data layer (lib/data/watch/) uses the generated Dart; everything
// above it sees domain types. On the iPhone, WatchLink turns each snapshot
// into the HeartRateSnapshot that the watch app shares (ios/Shared/).

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/data/watch/watch_api.pigeon.dart',
    dartPackageName: 'pulselink',
    swiftOut: 'ios/Runner/WatchApi.pigeon.swift',
    swiftOptions: SwiftOptions(
      // Both Pigeon files compile into Runner. These keep this one's
      // generated helpers apart from ble_api.dart's, and leave out the
      // PigeonError class that BleApi.pigeon.swift already declares.
      fileSpecificClassNameComponent: 'Watch',
      includeErrorClass: false,
    ),
  ),
)
/// Where the phone's heart rate comes from.
enum WatchHeartRateSource {
  /// The app's demo mode: simulated data, no strap.
  demo,

  /// A Bluetooth heart-rate strap.
  strap,
}

/// Why the phone can't get heart-rate data: one value per Dart
/// `StrapConnectionFailure`, with the Bluetooth problems spelled out.
enum WatchStrapFailure {
  /// Bluetooth is turned off.
  bluetoothOff,

  /// The phone can't use Bluetooth LE.
  bluetoothUnavailable,

  /// The user hasn't allowed the app to use Bluetooth.
  bluetoothPermissionDenied,

  /// The strap is off, out of range, or connected to another app.
  strapUnreachable,

  /// The device doesn't offer the standard Heart Rate Service.
  notAHeartRateStrap,

  /// The strap was connected, then dropped.
  connectionLost,
}

/// How getting heart-rate data is going on the phone.
sealed class WatchHeartRateStatus;

/// Starting up or connecting; no reading since then.
class WatchWaiting extends WatchHeartRateStatus;

/// Readings are arriving.
class WatchReceiving extends WatchHeartRateStatus;

/// The phone can't get heart-rate data, for [failure].
class WatchFailed extends WatchHeartRateStatus {
  new(this.failure);

  final WatchStrapFailure failure;
}

/// No strap has been picked on the phone.
class WatchNoStrap extends WatchHeartRateStatus;

/// Why a sample has no trustworthy heart rate.
enum WatchUnavailableReason {
  /// The strap reports no skin contact.
  noSkinContact,

  /// The strap sent a bpm of 0, meaning it has no reading.
  zeroBeatsPerMinute,

  /// The strap sent a bpm too high to be a heartbeat.
  implausibleBeatsPerMinute,
}

/// One heart-rate sample, stamped with when it was measured.
sealed class WatchHeartRateReading;

/// A usable reading. [beatsPerMinute] comes from a Dart `BeatsPerMinute`, so
/// it's in range; the native side checks again anyway.
class WatchMeasuredReading extends WatchHeartRateReading {
  new(this.beatsPerMinute, this.measuredAtMillis);

  final int beatsPerMinute;

  /// When it was measured, in milliseconds since 1970 (UTC).
  final int measuredAtMillis;
}

/// The strap is sending, but has no trustworthy heart rate, for [reason].
class WatchUnavailableReading extends WatchHeartRateReading {
  new(this.reason, this.measuredAtMillis);

  final WatchUnavailableReason reason;

  /// When it was measured, in milliseconds since 1970 (UTC).
  final int measuredAtMillis;
}

/// What the phone tells the watch: the Pigeon form of the shared
/// HeartRateSnapshot (ios/Shared/HeartRateSnapshot.swift).
class WatchHeartRateSnapshot {
  new(this.sentAtMillis, this.source, this.status, this.latestReading);

  /// When the phone sent it, in milliseconds since 1970 (UTC).
  final int sentAtMillis;

  final WatchHeartRateSource source;

  final WatchHeartRateStatus status;

  /// The latest reading, or null before the first one.
  final WatchHeartRateReading? latestReading;
}

/// What became of a snapshot handed to WatchConnectivity.
enum WatchDeliveryOutcome {
  /// Handed to WatchConnectivity. For a live snapshot, that doesn't promise
  /// the watch got it.
  sent,

  /// An application context the session can't take yet, because it's still
  /// activating. It's kept, and sent when activation finishes, unless a newer
  /// one replaces it first.
  pending,

  /// A live snapshot the watch app can't receive right now, because it isn't
  /// open or the watch is out of range. Dropped: the next one is newer.
  watchUnreachable,

  /// There's no paired Apple Watch with the app installed. Dropped.
  noWatchApp,

  /// This device can't talk to an Apple Watch, such as an iPad. Dropped.
  unsupported,

  /// WatchConnectivity refused it, or the snapshot was malformed. Dropped,
  /// and logged on the native side.
  failed,
}

@HostApi()
abstract class WatchSessionApi {
  /// Sends [snapshot] to the watch app as a live message, if it's reachable.
  /// Never queued: one that can't be sent now is dropped.
  @async
  WatchDeliveryOutcome sendLiveSnapshot(WatchHeartRateSnapshot snapshot);

  /// Makes [snapshot] the application context, which the watch app reads
  /// when it launches. Replaces any earlier one.
  @async
  WatchDeliveryOutcome updateApplicationContext(
    WatchHeartRateSnapshot snapshot,
  );
}
