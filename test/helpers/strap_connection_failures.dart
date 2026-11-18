// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';

/// Every [StrapConnectionFailure], with each [BluetoothProblem]. Add a new
/// case here when one is added to [StrapConnectionFailure].
const List<StrapConnectionFailure> allStrapConnectionFailures = [
  StrapConnectionFailure.bluetooth(BluetoothProblem.off),
  StrapConnectionFailure.bluetooth(BluetoothProblem.unavailable),
  StrapConnectionFailure.bluetooth(BluetoothProblem.permissionDenied),
  StrapConnectionFailure.strapUnreachable(),
  StrapConnectionFailure.notAHeartRateStrap(),
  StrapConnectionFailure.connectionLost(),
];
