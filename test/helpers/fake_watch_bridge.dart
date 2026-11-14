import 'package:pulselink/data/watch_bridge.dart';
import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

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

  @override
  Future<WatchDeliveryResult> sendLiveSnapshot(
    WatchHeartRateSnapshot snapshot,
  ) async {
    liveSnapshots.add(snapshot);
    if (error case final error?) {
      throw error;
    }
    return liveResult;
  }

  @override
  Future<WatchDeliveryResult> updateApplicationContext(
    WatchHeartRateSnapshot snapshot,
  ) async {
    contexts.add(snapshot);
    if (error case final error?) {
      throw error;
    }
    return contextResult;
  }
}
