// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

part 'live_heart_rate_state.freezed.dart';

/// What the live heart-rate screen shows.
@freezed
sealed class LiveHeartRateState with _$LiveHeartRateState {
  /// No strap has been picked, so there's no heart rate to show. Every build
  /// starts here; the screen asks for a strap.
  const factory noStrap() = LiveHeartRateNoStrap;

  /// No sample has arrived yet.
  const factory waiting({required bool isSimulated}) = LiveHeartRateWaiting;

  /// The latest sample. [isStale] is true once it's older than the stale
  /// threshold, and the UI must then not present it as current.
  const factory reading({
    required HeartRateSample sample,
    required bool isStale,
    required bool isSimulated,
  }) = LiveHeartRateReading;

  /// The source couldn't start, for the reason in [failure]. No samples will
  /// arrive until it's started again.
  const factory connectionFailed({
    required StrapConnectionFailure failure,
    required bool isSimulated,
  }) = LiveHeartRateConnectionFailed;

  const new _();

  /// Whether the heart rate comes from demo data rather than a strap. Never
  /// with no strap picked.
  bool get isSimulated => switch (this) {
    LiveHeartRateNoStrap() => false,
    LiveHeartRateWaiting(:final isSimulated) ||
    LiveHeartRateReading(:final isSimulated) ||
    LiveHeartRateConnectionFailed(:final isSimulated) => isSimulated,
  };
}
