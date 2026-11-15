import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulselink/data/watch/pigeon_watch_bridge.dart';
import 'package:pulselink/data/watch/watch_api.pigeon.dart' as pigeon;
import 'package:pulselink/data/watch_bridge.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

import '../../helpers/beats_per_minute.dart';
import '../../helpers/strap_connection_failures.dart';

class _MockWatchSessionApi extends Mock implements pigeon.WatchSessionApi;

final _sentAt = DateTime.utc(2026, 11, 14, 9, 30, 10);
final _measuredAt = DateTime.utc(2026, 11, 14, 9, 30, 9, 500);

WatchHeartRateSnapshot _snapshot({
  bool isSimulated = false,
  WatchHeartRateStatus status = const .receiving(),
  HeartRateSample? latestReading,
}) => WatchHeartRateSnapshot(
  sentAt: _sentAt,
  isSimulated: isSimulated,
  status: status,
  latestReading: latestReading,
);

/// The two calls, so each test can run against both.
enum _Call {
  live,
  context;

  Future<WatchDeliveryResult> on(
    WatchBridge bridge,
    WatchHeartRateSnapshot snapshot,
  ) => switch (this) {
    _Call.live => bridge.sendLiveSnapshot(snapshot),
    _Call.context => bridge.updateApplicationContext(snapshot),
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      pigeon.WatchHeartRateSnapshot(
        sentAtMillis: 0,
        source: pigeon.WatchHeartRateSource.demo,
        status: pigeon.WatchWaiting(),
      ),
    );
  });

  group('PigeonWatchBridge', () {
    late _MockWatchSessionApi api;
    late PigeonWatchBridge bridge;

    setUp(() {
      api = _MockWatchSessionApi();
      bridge = PigeonWatchBridge(api: api);
      when(() => api.sendLiveSnapshot(any()))
          .thenAnswer((_) async => pigeon.WatchDeliveryOutcome.sent);
      when(() => api.updateApplicationContext(any()))
          .thenAnswer((_) async => pigeon.WatchDeliveryOutcome.sent);
    });

    /// What the bridge passed to the native side for [call].
    pigeon.WatchHeartRateSnapshot sentFor(_Call call) {
      final captured = switch (call) {
        _Call.live => verify(() => api.sendLiveSnapshot(captureAny())).captured,
        _Call.context => verify(
          () => api.updateApplicationContext(captureAny()),
        ).captured,
      };
      return captured.single as pigeon.WatchHeartRateSnapshot;
    }

    for (final call in _Call.values) {
      group('${call.name}:', () {
        test('sends the time in milliseconds since 1970', () async {
          expect(await call.on(bridge, _snapshot()), WatchDeliveryResult.sent);

          expect(sentFor(call).sentAtMillis, _sentAt.millisecondsSinceEpoch);
        });

        test('sends demo mode and a strap as sources', () async {
          expect(
            await call.on(bridge, _snapshot(isSimulated: true)),
            WatchDeliveryResult.sent,
          );
          expect(sentFor(call).source, pigeon.WatchHeartRateSource.demo);

          expect(await call.on(bridge, _snapshot()), WatchDeliveryResult.sent);
          expect(sentFor(call).source, pigeon.WatchHeartRateSource.strap);
        });

        test('sends waiting and receiving', () async {
          expect(
            await call.on(bridge, _snapshot(status: const .waiting())),
            WatchDeliveryResult.sent,
          );
          expect(sentFor(call).status, isA<pigeon.WatchWaiting>());

          expect(await call.on(bridge, _snapshot()), WatchDeliveryResult.sent);
          expect(sentFor(call).status, isA<pigeon.WatchReceiving>());
        });

        test('sends each failure', () async {
          const expected = [
            pigeon.WatchStrapFailure.bluetoothOff,
            pigeon.WatchStrapFailure.bluetoothUnavailable,
            pigeon.WatchStrapFailure.bluetoothPermissionDenied,
            pigeon.WatchStrapFailure.strapUnreachable,
            pigeon.WatchStrapFailure.notAHeartRateStrap,
            pigeon.WatchStrapFailure.connectionLost,
          ];
          expect(allStrapConnectionFailures, hasLength(expected.length));

          for (final (index, failure) in allStrapConnectionFailures.indexed) {
            expect(
              await call.on(bridge, _snapshot(status: .failed(failure))),
              WatchDeliveryResult.sent,
            );

            final status = sentFor(call).status;
            expect(
              status,
              isA<pigeon.WatchFailed>().having(
                (status) => status.failure,
                'failure',
                expected[index],
              ),
              reason: '$failure',
            );
          }
        });

        test('sends a measured reading', () async {
          expect(
            await call.on(
              bridge,
              _snapshot(
                latestReading: HeartRateSample.measured(
                  beatsPerMinute: beatsPerMinuteOf(72),
                  timestamp: _measuredAt,
                  skinContact: .detected,
                ),
              ),
            ),
            WatchDeliveryResult.sent,
          );

          expect(
            sentFor(call).latestReading,
            isA<pigeon.WatchMeasuredReading>()
                .having((r) => r.beatsPerMinute, 'beatsPerMinute', 72)
                .having(
                  (r) => r.measuredAtMillis,
                  'measuredAtMillis',
                  _measuredAt.millisecondsSinceEpoch,
                ),
          );
        });

        test('sends each kind of unavailable reading', () async {
          const expected = {
            HeartRateUnavailableReason.noSkinContact:
                pigeon.WatchUnavailableReason.noSkinContact,
            HeartRateUnavailableReason.zeroBeatsPerMinute:
                pigeon.WatchUnavailableReason.zeroBeatsPerMinute,
            HeartRateUnavailableReason.implausibleBeatsPerMinute:
                pigeon.WatchUnavailableReason.implausibleBeatsPerMinute,
          };
          expect(expected.keys, HeartRateUnavailableReason.values);

          for (final MapEntry(key: reason, value: pigeonReason)
              in expected.entries) {
            expect(
              await call.on(
                bridge,
                _snapshot(
                  latestReading: HeartRateSample.unavailable(
                    timestamp: _measuredAt,
                    reason: reason,
                  ),
                ),
              ),
              WatchDeliveryResult.sent,
            );

            expect(
              sentFor(call).latestReading,
              isA<pigeon.WatchUnavailableReading>()
                  .having((r) => r.reason, 'reason', pigeonReason)
                  .having(
                    (r) => r.measuredAtMillis,
                    'measuredAtMillis',
                    _measuredAt.millisecondsSinceEpoch,
                  ),
              reason: '$reason',
            );
          }
        });

        test('sends no reading before the first one', () async {
          expect(await call.on(bridge, _snapshot()), WatchDeliveryResult.sent);

          expect(sentFor(call).latestReading, isNull);
        });

        test('returns each outcome as a result', () async {
          const expected = {
            pigeon.WatchDeliveryOutcome.sent: WatchDeliveryResult.sent,
            pigeon.WatchDeliveryOutcome.pending: WatchDeliveryResult.pending,
            pigeon.WatchDeliveryOutcome.watchUnreachable:
                WatchDeliveryResult.watchUnreachable,
            pigeon.WatchDeliveryOutcome.noWatchApp:
                WatchDeliveryResult.noWatchApp,
            pigeon.WatchDeliveryOutcome.unsupported:
                WatchDeliveryResult.unsupported,
            pigeon.WatchDeliveryOutcome.failed: WatchDeliveryResult.failed,
          };
          expect(expected.keys, pigeon.WatchDeliveryOutcome.values);

          for (final MapEntry(key: outcome, value: result)
              in expected.entries) {
            when(() => api.sendLiveSnapshot(any()))
                .thenAnswer((_) async => outcome);
            when(() => api.updateApplicationContext(any()))
                .thenAnswer((_) async => outcome);

            expect(await call.on(bridge, _snapshot()), result);
          }
        });

        test(
          'reports no native handler, as on Android, as unsupported',
          () async {
            final error = PlatformException(code: 'channel-error');
            when(() => api.sendLiveSnapshot(any())).thenThrow(error);
            when(() => api.updateApplicationContext(any())).thenThrow(error);

            expect(
              await call.on(bridge, _snapshot()),
              WatchDeliveryResult.unsupported,
            );
          },
        );

        test('reports any other platform failure as failed', () async {
          final error = PlatformException(code: 'native-error');
          when(() => api.sendLiveSnapshot(any())).thenThrow(error);
          when(() => api.updateApplicationContext(any())).thenThrow(error);

          expect(
            await call.on(bridge, _snapshot()),
            WatchDeliveryResult.failed,
          );
        });

        test('passes on an error that is not a platform failure', () async {
          // Anything else is a bug, such as the generated cast failing; it's
          // left for the zone's error handler.
          final error = StateError('bug');
          when(() => api.sendLiveSnapshot(any())).thenThrow(error);
          when(() => api.updateApplicationContext(any())).thenThrow(error);

          await expectLater(call.on(bridge, _snapshot()), throwsStateError);
        });
      });
    }
  });
}
