// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

/// Opens this app's page in the phone's Settings app, where the user can
/// allow Bluetooth. Everything above the data layer depends only on this, so
/// tests can fake it.
abstract interface class AppSettings {
  /// Opens it, and completes with whether it opened. Never fails: a
  /// platform that can't open it completes with false.
  Future<bool> open();
}
