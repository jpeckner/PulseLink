import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/blocs/strap_battery/strap_battery_cubit.dart';
import 'package:pulselink/domain/battery_level.dart';

import '../helpers/stub_strap_data_source.dart';

void main() {
  group('StrapBatteryCubit', () {
    late StubStrapDataSource source;

    setUp(() => source = StubStrapDataSource());

    test('starts out unknown', () async {
      final cubit = StrapBatteryCubit(source: source);
      expect(cubit.state, isNull);
      await cubit.close();
    });

    test(
      "follows the source's battery level, including going unknown",
      () async {
        final cubit = StrapBatteryCubit(source: source);
        final states = <BatteryLevel?>[];
        cubit.stream.listen(states.add);

        source
          ..reportBatteryLevel(BatteryLevel.tryFrom(80))
          ..reportBatteryLevel(BatteryLevel.tryFrom(79))
          ..reportBatteryLevel(null);
        await Future<void>.delayed(Duration.zero);
        expect(states, [
          BatteryLevel.tryFrom(80),
          BatteryLevel.tryFrom(79),
          null,
        ]);
        await cubit.close();
      },
    );

    test('close stops listening to the source', () async {
      final cubit = StrapBatteryCubit(source: source);
      expect(source.hasBatteryLevelListener, isTrue);
      await cubit.close();
      expect(source.hasBatteryLevelListener, isFalse);
    });
  });
}
