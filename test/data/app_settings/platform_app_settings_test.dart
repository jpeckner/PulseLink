import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/data/app_settings/app_settings_api.pigeon.dart';
import 'package:pulselink/data/app_settings/platform_app_settings.dart';

void main() {
  group('PlatformAppSettings', () {
    const openChannel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.pulselink.AppSettingsApi.openAppSettings',
      AppSettingsApi.pigeonChannelCodec,
    );

    setUp(TestWidgetsFlutterBinding.ensureInitialized);

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
      expect(await PlatformAppSettings().open(), isTrue);
    });

    test("completes with false when the native side couldn't", () async {
      answerWith(false);
      expect(await PlatformAppSettings().open(), isFalse);
    });

    test(
      'completes with false when the native side reports an error',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler(
              openChannel,
              (_) async => <Object?>['failed', 'Something broke', null],
            );
        expect(await PlatformAppSettings().open(), isFalse);
      },
    );

    test('completes with false when nothing answers on the channel', () async {
      expect(await PlatformAppSettings().open(), isFalse);
    });
  });
}
