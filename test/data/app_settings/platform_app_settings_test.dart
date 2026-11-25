// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/data/app_settings/app_settings_api.pigeon.dart';
import 'package:pulselink/data/app_settings/platform_app_settings.dart';

import '../../helpers/recording_tracker_service.dart';

void main() {
  group('PlatformAppSettings', () {
    const openChannel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.pulselink.AppSettingsApi.openAppSettings',
      AppSettingsApi.pigeonChannelCodec,
    );

    late RecordingTrackerService tracker;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      tracker = RecordingTrackerService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler(openChannel, null);
    });

    void answerWith(bool opened) {
      // Pigeon wraps each reply in a one-item list.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler(
            openChannel,
            (_) async => <Object?>[opened],
          );
    }

    test('completes with true when the native side opened Settings', () async {
      answerWith(true);
      expect(await PlatformAppSettings(tracker: tracker).open(), isTrue);
    });

    test("completes with false when the native side couldn't", () async {
      answerWith(false);
      expect(await PlatformAppSettings(tracker: tracker).open(), isFalse);
    });

    test('completes with false, tracked as non-fatal, when the native side '
        'reports an error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler(
            openChannel,
            (_) async => <Object?>['failed', 'Something broke', null],
          );
      expect(await PlatformAppSettings(tracker: tracker).open(), isFalse);
      final logged = tracker.errors.single;
      expect(logged.name, 'settings');
      expect(logged.error, isA<PlatformException>());
      expect(logged.fatal, isFalse);
    });

    test('completes with false, tracked as non-fatal, when nothing answers '
        'on the channel', () async {
      expect(await PlatformAppSettings(tracker: tracker).open(), isFalse);
      expect(tracker.errors.single.fatal, isFalse);
    });

    test('tracks nothing when the channel answers', () async {
      answerWith(false);
      expect(await PlatformAppSettings(tracker: tracker).open(), isFalse);
      expect(tracker.errors, isEmpty);
    });
  });
}
