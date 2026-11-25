// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:pulselink/data/watch_bridge.dart';
import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

/// How a [FakeWatchBridge] with an [FakeWatchBridge.error] fails. Each
/// [description] reads as a test name.
enum FakeWatchBridgeFailure {
  failedFuture('returns a failed future'),
  throwsBeforeFuture('throws before returning a future');

  new(this.description);

  final String description;
}

/// A [WatchBridge] that records what it was given, and answers with
/// [liveResult] and [contextResult].
class FakeWatchBridge implements WatchBridge {
  /// Every snapshot passed to [sendLiveSnapshot], oldest first.
  final List<WatchHeartRateSnapshot> liveSnapshots = [];

  /// Every snapshot passed to [updateApplicationContext], oldest first.
  final List<WatchHeartRateSnapshot> contexts = [];

  WatchDeliveryResult liveResult = WatchDeliveryResult.sent;

  WatchDeliveryResult contextResult = WatchDeliveryResult.sent;

  /// When set, both calls fail with this error instead of returning a
  /// result, standing in for a bug in a bridge.
  Exception? error;

  /// How the calls fail when [error] is set.
  FakeWatchBridgeFailure failure = FakeWatchBridgeFailure.failedFuture;

  @override
  Future<WatchDeliveryResult> sendLiveSnapshot(
    WatchHeartRateSnapshot snapshot,
  ) {
    liveSnapshots.add(snapshot);
    return _answer(liveResult);
  }

  @override
  Future<WatchDeliveryResult> updateApplicationContext(
    WatchHeartRateSnapshot snapshot,
  ) {
    contexts.add(snapshot);
    return _answer(contextResult);
  }

  Future<WatchDeliveryResult> _answer(WatchDeliveryResult result) {
    final error = this.error;
    if (error == null) {
      return Future.value(result);
    }
    return switch (failure) {
      FakeWatchBridgeFailure.failedFuture => Future.error(error),
      FakeWatchBridgeFailure.throwsBeforeFuture => throw error,
    };
  }
}
