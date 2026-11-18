// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/discovered_strap.dart';

part 'strap_scanner.freezed.dart';

/// Something that happened during a scan for straps.
@freezed
sealed class StrapScanEvent with _$StrapScanEvent {
  /// The phone is scanning. Comes first, and again whenever scanning resumes
  /// after [StrapScanFailed] (such as when Bluetooth is turned back on).
  const factory scanning() = StrapScanScanning;

  /// A nearby heart-rate strap. The same strap can be reported more than
  /// once.
  const factory found(DiscoveredStrap strap) = StrapFound;

  /// The phone can't scan, for the reason in [problem]. Straps found before
  /// this may no longer be nearby or reachable.
  const factory failed(BluetoothProblem problem) = StrapScanFailed;
}

/// Finds nearby heart-rate straps. Everything above the data layer depends
/// only on this, so tests can fake it.
abstract interface class StrapScanner {
  /// Scans while the returned stream is listened to, and stops when the
  /// subscription is cancelled. Listening again starts a new scan.
  ///
  /// Expected failures never arrive as stream errors: a scan that can't run
  /// reports [StrapScanFailed]. So listeners need no error handler; an error
  /// would mean a bug, and goes to the zone's error handler.
  ///
  /// Only one scan runs at a time, so listen from one place at a time.
  Stream<StrapScanEvent> scan();
}
