// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

part 'watch_heart_rate_snapshot.freezed.dart';

/// How getting heart-rate data is going on the phone, as the watch shows it.
@freezed
sealed class WatchHeartRateStatus with _$WatchHeartRateStatus {
  /// No strap has been picked on the phone.
  const factory noStrap() = WatchHeartRateNoStrap;

  /// Starting up or connecting; no reading since then.
  const factory waiting() = WatchHeartRateWaiting;

  /// Readings are arriving.
  const factory receiving() = WatchHeartRateReceiving;

  /// The phone can't get heart-rate data, for the reason in [failure].
  const factory failed(StrapConnectionFailure failure) = WatchHeartRateFailed;
}

/// What the phone tells the Apple Watch app about the heart rate it's
/// showing. The phone sends the same snapshot as a live message and as the
/// application context; the watch shows the newest one by [sentAt].
///
/// The Dart side of the HeartRateSnapshot the iPhone and watch apps share
/// (ios/Shared/HeartRateSnapshot.swift).
@freezed
abstract class WatchHeartRateSnapshot with _$WatchHeartRateSnapshot {
  const factory({
    /// When the phone sent it, by the phone's clock.
    required DateTime sentAt,

    /// True in demo mode, when the heart rate is simulated.
    required bool isSimulated,

    required WatchHeartRateStatus status,

    /// The latest sample, or null before the first one. It's kept after the
    /// strap fails, so the watch can still show the last bpm and when it was
    /// measured. Whether it's stale is for the watch to work out from its
    /// timestamp.
    required HeartRateSample? latestReading,
  }) = _WatchHeartRateSnapshot;
}
