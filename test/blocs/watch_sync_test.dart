// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/blocs/watch_sync/watch_sync.dart';
import 'package:pulselink/data/watch_bridge.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

import '../helpers/beats_per_minute.dart';
import '../helpers/fake_watch_bridge.dart';
import '../helpers/strap_connection_failures.dart';

final _now = DateTime.utc(2026, 11, 15, 10, 4);

final _measured = HeartRateSample.measured(
  beatsPerMinute: beatsPerMinuteOf(72),
  timestamp: _now.subtract(const Duration(seconds: 1)),
  skinContact: SkinContact.detected,
);

final _unavailable = HeartRateSample.unavailable(
  timestamp: _now,
  reason: HeartRateUnavailableReason.zeroBeatsPerMinute,
);

/// What unsubscribing from a [_FakeHeartRate] throws, when set to fail.
final _cancelFailure = Exception('cancel failure');

/// A stand-in for `LiveHeartRateCubit`: [emit] sets [state] and delivers it
/// at once.
class _FakeHeartRate implements StateStreamable<LiveHeartRateState> {
  new(this.state, {bool failsToCancel = false})
    : _controller = StreamController(
        sync: true,
        // Single-subscription: unlike a broadcast stream, its cancel()
        // returns the onCancel future, so the failure reaches the listener.
        onCancel: failsToCancel
            ? () => Future<void>.error(_cancelFailure)
            : null,
      );

  final StreamController<LiveHeartRateState> _controller;

  @override
  LiveHeartRateState state;

  bool get hasListener => _controller.hasListener;

  void emit(LiveHeartRateState newState) {
    state = newState;
    _controller.add(newState);
  }

  @override
  Stream<LiveHeartRateState> get stream => _controller.stream;
}

/// Runs [body] with the clock fixed at [_now], so `sentAt` is predictable.
Future<void> _atNow(Future<void> Function() body) =>
    withClock(Clock.fixed(_now), body);

/// Lets the fake bridge's futures, and the results they carry, complete.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

WatchHeartRateSnapshot _snapshot({
  required WatchHeartRateStatus status,
  required HeartRateSample? latestReading,
  bool isSimulated = true,
}) => WatchHeartRateSnapshot(
  sentAt: _now,
  isSimulated: isSimulated,
  status: status,
  latestReading: latestReading,
);

void main() {
  group('WatchSync', () {
    late FakeWatchBridge bridge;
    late List<String> logs;

    setUp(() {
      bridge = FakeWatchBridge();
      logs = [];
    });

    WatchSync syncOf(_FakeHeartRate heartRate) =>
        WatchSync(heartRate: heartRate, bridge: bridge, log: logs.add);

    test('sends the current state when started, live and as context', () {
      return _atNow(() async {
        final heartRate = _FakeHeartRate(
          const LiveHeartRateState.waiting(isSimulated: true),
        );
        final sync = syncOf(heartRate)..start();
        await _settle();

        final expected = _snapshot(
          status: const WatchHeartRateStatus.waiting(),
          latestReading: null,
        );
        expect(bridge.liveSnapshots, [expected]);
        expect(bridge.contexts, [expected]);
        await sync.close();
      });
    });

    test('maps each state to a snapshot', () {
      return _atNow(() async {
        final heartRate = _FakeHeartRate(
          const LiveHeartRateState.waiting(isSimulated: false),
        );
        final sync = syncOf(heartRate)..start();
        heartRate
          ..emit(
            LiveHeartRateState.reading(
              sample: _measured,
              isStale: false,
              isSimulated: false,
            ),
          )
          ..emit(
            LiveHeartRateState.reading(
              sample: _unavailable,
              isStale: false,
              isSimulated: false,
            ),
          );
        for (final failure in allStrapConnectionFailures) {
          heartRate.emit(
            LiveHeartRateState.connectionFailed(
              failure: failure,
              isSimulated: false,
            ),
          );
        }
        await _settle();

        final expected = [
          _snapshot(
            status: const WatchHeartRateStatus.waiting(),
            latestReading: null,
            isSimulated: false,
          ),
          _snapshot(
            status: const WatchHeartRateStatus.receiving(),
            latestReading: _measured,
            isSimulated: false,
          ),
          _snapshot(
            status: const WatchHeartRateStatus.receiving(),
            latestReading: _unavailable,
            isSimulated: false,
          ),
          for (final failure in allStrapConnectionFailures)
            _snapshot(
              status: WatchHeartRateStatus.failed(failure),
              latestReading: _unavailable,
              isSimulated: false,
            ),
        ];
        expect(bridge.liveSnapshots, expected);
        expect(bridge.contexts, expected);
        await sync.close();
      });
    });

    test('sends no strap as not simulated, then a strap once one is '
        'picked', () {
      return _atNow(() async {
        final heartRate = _FakeHeartRate(const LiveHeartRateState.noStrap());
        final sync = syncOf(heartRate)..start();
        heartRate
          ..emit(const LiveHeartRateState.waiting(isSimulated: false))
          ..emit(
            LiveHeartRateState.reading(
              sample: _measured,
              isStale: false,
              isSimulated: false,
            ),
          );
        await _settle();

        final expected = [
          _snapshot(
            status: const WatchHeartRateStatus.noStrap(),
            latestReading: null,
            isSimulated: false,
          ),
          _snapshot(
            status: const WatchHeartRateStatus.waiting(),
            latestReading: null,
            isSimulated: false,
          ),
          _snapshot(
            status: const WatchHeartRateStatus.receiving(),
            latestReading: _measured,
            isSimulated: false,
          ),
        ];
        expect(bridge.liveSnapshots, expected);
        expect(bridge.contexts, expected);
        await sync.close();
      });
    });

    test('keeps the last reading while waiting again', () {
      return _atNow(() async {
        final heartRate = _FakeHeartRate(
          LiveHeartRateState.reading(
            sample: _measured,
            isStale: false,
            isSimulated: false,
          ),
        );
        final sync = syncOf(heartRate)..start();
        heartRate.emit(const LiveHeartRateState.waiting(isSimulated: false));
        await _settle();

        expect(
          bridge.liveSnapshots.last,
          _snapshot(
            status: const WatchHeartRateStatus.waiting(),
            latestReading: _measured,
            isSimulated: false,
          ),
        );
        await sync.close();
      });
    });

    for (final (from, to) in [(true, false), (false, true)]) {
      final names = {true: 'demo mode', false: 'a strap'};
      test('forgets the last reading on switching from ${names[from]} to '
          '${names[to]}', () {
        return _atNow(() async {
          final heartRate = _FakeHeartRate(
            LiveHeartRateState.reading(
              sample: _measured,
              isStale: false,
              isSimulated: from,
            ),
          );
          final sync = syncOf(heartRate)..start();
          heartRate.emit(LiveHeartRateState.waiting(isSimulated: to));
          await _settle();

          expect(
            bridge.liveSnapshots.last,
            _snapshot(
              status: const WatchHeartRateStatus.waiting(),
              latestReading: null,
              isSimulated: to,
            ),
          );
          await sync.close();
        });
      });
    }

    test("doesn't send a reading going stale, or a repeated state", () {
      return _atNow(() async {
        final reading = LiveHeartRateState.reading(
          sample: _measured,
          isStale: false,
          isSimulated: true,
        );
        final heartRate = _FakeHeartRate(reading);
        final sync = syncOf(heartRate)..start();
        heartRate
          ..emit(
            LiveHeartRateState.reading(
              sample: _measured,
              isStale: true,
              isSimulated: true,
            ),
          )
          ..emit(reading);
        await _settle();

        expect(bridge.liveSnapshots, hasLength(1));
        expect(bridge.contexts, hasLength(1));
        await sync.close();
      });
    });

    test('starting twice subscribes once', () {
      return _atNow(() async {
        final heartRate = _FakeHeartRate(
          const LiveHeartRateState.waiting(isSimulated: true),
        );
        final sync = syncOf(heartRate)
          ..start()
          ..start();
        heartRate.emit(
          LiveHeartRateState.reading(
            sample: _measured,
            isStale: false,
            isSimulated: true,
          ),
        );
        await _settle();

        expect(bridge.liveSnapshots, hasLength(2));
        await sync.close();
      });
    });

    for (final result in WatchDeliveryResult.values) {
      test('logs a ${result.name} result once, until it changes', () {
        return _atNow(() async {
          bridge
            ..liveResult = result
            ..contextResult = result;
          final heartRate = _FakeHeartRate(
            const LiveHeartRateState.waiting(isSimulated: true),
          );
          final sync = syncOf(heartRate)..start();
          await _settle();
          heartRate.emit(
            LiveHeartRateState.reading(
              sample: _measured,
              isStale: false,
              isSimulated: true,
            ),
          );
          await _settle();

          expect(logs, hasLength(2));
          expect(logs.where((log) => log.startsWith('Live snapshots: ')), [
            hasLength(greaterThan('Live snapshots: '.length)),
          ]);
          expect(logs.where((log) => log.startsWith('Application context: ')), [
            hasLength(greaterThan('Application context: '.length)),
          ]);

          // A different result is logged again.
          final other = switch (result) {
            WatchDeliveryResult.sent => WatchDeliveryResult.watchUnreachable,
            WatchDeliveryResult.pending ||
            WatchDeliveryResult.watchUnreachable ||
            WatchDeliveryResult.noWatchApp ||
            WatchDeliveryResult.unsupported ||
            WatchDeliveryResult.failed => WatchDeliveryResult.sent,
          };
          bridge.liveResult = other;
          heartRate.emit(const LiveHeartRateState.waiting(isSimulated: true));
          await _settle();
          expect(logs, hasLength(3));
          expect(logs.last, startsWith('Live snapshots: '));
          await sync.close();
        });
      });
    }

    test('describes every result differently', () {
      return _atNow(() async {
        final heartRate = _FakeHeartRate(
          const LiveHeartRateState.waiting(isSimulated: true),
        );
        final sync = syncOf(heartRate)..start();
        await _settle();
        for (final result in WatchDeliveryResult.values) {
          bridge.liveResult = result;
          heartRate.emit(
            LiveHeartRateState.connectionFailed(
              // A different state each time, so each is sent.
              failure:
                  allStrapConnectionFailures[result.index %
                      allStrapConnectionFailures.length],
              isSimulated: true,
            ),
          );
          await _settle();
        }

        final live = logs.where((log) => log.startsWith('Live snapshots: '));
        expect(live.toSet(), hasLength(WatchDeliveryResult.values.length));
        await sync.close();
      });
    });

    for (final failure in FakeWatchBridgeFailure.values) {
      test("leaves a bridge's error for the zone's error handler when it "
          '${failure.description}, and still makes both calls', () async {
        bridge
          ..error = Exception('bridge bug')
          ..failure = failure;
        final errors = <Object>[];
        final heartRate = _FakeHeartRate(
          const LiveHeartRateState.waiting(isSimulated: true),
        );
        late WatchSync sync;
        await runZonedGuarded(() async {
          sync = syncOf(heartRate)..start();
          await _settle();
        }, (error, _) => errors.add(error));

        expect(errors, [same(bridge.error), same(bridge.error)]);
        expect(bridge.liveSnapshots, hasLength(1));
        expect(bridge.contexts, hasLength(1));
        await sync.close();
      });
    }

    test('close stops sending', () {
      return _atNow(() async {
        final heartRate = _FakeHeartRate(
          const LiveHeartRateState.waiting(isSimulated: true),
        );
        final sync = syncOf(heartRate)..start();
        expect(heartRate.hasListener, isTrue);
        await sync.close();
        expect(heartRate.hasListener, isFalse);

        sync.start();
        expect(heartRate.hasListener, isFalse);
        await _settle();
        expect(bridge.liveSnapshots, hasLength(1));
      });
    });

    test('close passes on a failure to unsubscribe, and still stops', () {
      return _atNow(() async {
        final heartRate = _FakeHeartRate(
          const LiveHeartRateState.waiting(isSimulated: true),
          failsToCancel: true,
        );
        final sync = syncOf(heartRate)..start();

        await expectLater(sync.close(), throwsA(same(_cancelFailure)));
        expect(heartRate.hasListener, isFalse);
        sync.start();
        expect(heartRate.hasListener, isFalse);
        await _settle();
        expect(bridge.liveSnapshots, hasLength(1));
      });
    });
  });
}
