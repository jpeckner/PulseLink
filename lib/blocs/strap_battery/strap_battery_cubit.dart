// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/domain/battery_level.dart';

/// The strap's battery level for the live screen, or null when it isn't
/// known: before one is read, for a strap that doesn't report one, or after
/// a drop or a switch to another strap.
///
/// Separate from `LiveHeartRateCubit`, so a battery update (rare) doesn't
/// rebuild the heart-rate readout, and each can be tested on its own.
class StrapBatteryCubit extends Cubit<BatteryLevel?> {
  new({required StrapDataSource source}) : super(null) {
    // No onError: StrapDataSource.batteryLevel never carries errors.
    _subscription = source.batteryLevel.listen(emit);
  }

  StreamSubscription<BatteryLevel?>? _subscription;

  @override
  Future<void> close() async {
    try {
      // Stops delivery first, so nothing is emitted into the closed cubit.
      await _subscription?.cancel();
    } finally {
      // Close even if unsubscribing failed; the error still reaches the
      // caller.
      await super.close();
    }
  }
}
