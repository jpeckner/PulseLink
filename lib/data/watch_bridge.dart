// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

/// What became of a snapshot handed to the watch bridge. Each is an expected
/// outcome, not an error; none needs handling beyond carrying on, since a
/// newer snapshot follows.
enum WatchDeliveryResult {
  /// Handed to WatchConnectivity. For a live snapshot, that doesn't promise
  /// the watch got it.
  sent,

  /// An application context the phone's WatchConnectivity session can't take
  /// yet, because it's still activating. It's kept, and sent when activation
  /// finishes, unless a newer one replaces it first.
  pending,

  /// A live snapshot the watch app can't receive right now, because it isn't
  /// open or the watch is out of range. Dropped.
  watchUnreachable,

  /// There's no paired Apple Watch with the app installed. Dropped.
  noWatchApp,

  /// This device can't talk to an Apple Watch, such as an iPad, or an
  /// Android phone. Dropped.
  unsupported,

  /// WatchConnectivity refused it, or the native side failed. Dropped, and
  /// logged.
  failed,
}

/// Sends heart-rate snapshots to the Apple Watch app. Everything above the
/// data layer depends only on this, so tests can fake it.
///
/// Neither call throws for an expected failure: each returns a
/// [WatchDeliveryResult].
abstract interface class WatchBridge {
  /// Sends [snapshot] as a live message if the watch app is reachable.
  /// Never queued: one that can't be sent now is dropped.
  Future<WatchDeliveryResult> sendLiveSnapshot(WatchHeartRateSnapshot snapshot);

  /// Makes [snapshot] the application context, which the watch app reads
  /// when it launches. Replaces any earlier one.
  Future<WatchDeliveryResult> updateApplicationContext(
    WatchHeartRateSnapshot snapshot,
  );
}
