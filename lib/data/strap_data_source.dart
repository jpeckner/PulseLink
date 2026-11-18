// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/battery_level.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

part 'strap_data_source.freezed.dart';

/// How a call to [StrapDataSource.start] ended.
@freezed
sealed class StrapDataSourceStartResult with _$StrapDataSourceStartResult {
  /// The source is producing samples.
  const factory started() = StrapDataSourceStarted;

  /// [StrapDataSource.stop] or [StrapDataSource.dispose] was called before
  /// starting finished, so the source isn't producing samples. Nothing went
  /// wrong, so there's nothing to show.
  const factory cancelled() = StrapDataSourceStartCancelled;

  /// The source couldn't start, for an expected reason such as Bluetooth
  /// being off.
  const factory failed(StrapConnectionFailure failure) =
      StrapDataSourceStartFailed;

  /// There's nothing to start: no strap has been picked yet. Nothing went
  /// wrong; the screen asks for a strap.
  const factory noStrap() = StrapDataSourceNoStrap;
}

/// Where heart-rate samples come from: a BLE strap, or a simulator for demo
/// mode (debug and profile builds only) and tests. Everything above the data
/// layer depends only on this.
abstract interface class StrapDataSource {
  /// True when samples are simulated, so the UI can label them as such.
  bool get isSimulated;

  /// Samples as they arrive. A broadcast stream; it stays open across
  /// [start]/[stop] cycles and closes on [dispose].
  ///
  /// Never carries errors. A missing heart rate arrives as an unavailable
  /// sample; any other failure is reported as a typed result, never as a
  /// stream error, so listeners need no error handler.
  Stream<HeartRateSample> get samples;

  /// Failures that stop a started source producing samples, such as a strap
  /// going out of range. A broadcast stream; it stays open across
  /// [start]/[stop] cycles and closes on [dispose]. Never carries errors.
  ///
  /// After one, the source counts as stopped, so [start] starts it again:
  /// for a strap, that means reconnecting. A source that can't lose a
  /// connection, such as demo data, never emits one.
  Stream<StrapConnectionFailure> get connectionLost;

  /// The strap's battery level, when it's read and whenever it changes, or
  /// null once it's no longer known, such as after stopping, losing the
  /// connection or switching straps. A broadcast stream; it stays open
  /// across [start]/[stop] cycles and closes on [dispose]. Never carries
  /// errors. A strap without a battery level never emits one.
  Stream<BatteryLevel?> get batteryLevel;

  /// Starts producing samples, and completes once the source is producing
  /// them or has failed to. Calling it while already started completes with
  /// [StrapDataSourceStarted] at once. Calling it while a start is still in
  /// progress joins that start: both calls complete with the same result,
  /// and the source makes only one attempt.
  ///
  /// Expected failures, such as Bluetooth being off, complete with
  /// [StrapDataSourceStartFailed]; they never throw.
  ///
  /// Calling [stop] or [dispose] before this completes cancels it: it then
  /// completes with [StrapDataSourceStartCancelled], and the source produces
  /// no samples. A real strap can take seconds to connect, so a caller that
  /// gives up (such as a screen being closed) must be able to stop it
  /// without leaving a connection running that nothing owns. After [dispose],
  /// it completes with [StrapDataSourceStartCancelled] at once.
  Future<StrapDataSourceStartResult> start();

  /// Stops producing samples, cancelling a [start] still in progress.
  /// Calling it while stopped does nothing.
  Future<void> stop();

  /// Releases resources, cancelling a [start] still in progress. The source
  /// can't be used afterwards.
  Future<void> dispose();
}
