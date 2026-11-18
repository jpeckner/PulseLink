// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/discovered_strap.dart';

part 'strap_picker_state.freezed.dart';

/// What the strap picker shows.
@freezed
sealed class StrapPickerState with _$StrapPickerState {
  /// Looking for straps. [straps] holds each one found so far, once, in the
  /// order they were found.
  const factory scanning({required List<DiscoveredStrap> straps}) =
      StrapPickerScanning;

  /// The phone can't scan, for the reason in [problem]. Scanning resumes on
  /// its own if the problem goes away (such as Bluetooth being turned on).
  const factory failed(BluetoothProblem problem) = StrapPickerFailed;
}
