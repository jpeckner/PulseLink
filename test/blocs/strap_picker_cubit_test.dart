import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/blocs/strap_picker/strap_picker_cubit.dart';
import 'package:pulselink/blocs/strap_picker/strap_picker_state.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/discovered_strap.dart';

import '../helpers/stub_strap_scanner.dart';

const _polar = DiscoveredStrap(id: 'polar', name: 'Polar H10');
const _tickr = DiscoveredStrap(id: 'tickr', name: 'TICKR');

void main() {
  group('StrapPickerCubit', () {
    late StubStrapScanner scanner;

    setUp(() => scanner = StubStrapScanner());

    test('starts out scanning with nothing found, before it scans', () async {
      final cubit = StrapPickerCubit(scanner: scanner);
      expect(cubit.state, const StrapPickerState.scanning(straps: []));
      expect(scanner.scanCount, 0);
      await cubit.close();
    });

    test('start scans once, however often it is called', () async {
      final cubit = StrapPickerCubit(scanner: scanner)
        ..start()
        ..start();
      expect(scanner.scanCount, 1);
      expect(scanner.isScanning, isTrue);
      await cubit.close();
    });

    blocTest<StrapPickerCubit, StrapPickerState>(
      'lists each strap found, in the order found',
      build: () => StrapPickerCubit(scanner: scanner),
      act: (cubit) {
        cubit.start();
        scanner
          ..emit(const .scanning())
          ..emit(const .found(_polar))
          ..emit(const .found(_tickr));
      },
      expect: () => const [
        StrapPickerState.scanning(straps: [_polar]),
        StrapPickerState.scanning(straps: [_polar, _tickr]),
      ],
    );

    blocTest<StrapPickerCubit, StrapPickerState>(
      'a strap found again replaces the earlier copy in place',
      build: () => StrapPickerCubit(scanner: scanner),
      act: (cubit) {
        cubit.start();
        scanner
          ..emit(const .found(_polar))
          ..emit(const .found(_tickr))
          ..emit(
            const .found(DiscoveredStrap(id: 'polar', name: 'Polar H10 2')),
          )
          ..emit(const .found(_tickr));
      },
      expect: () => const [
        StrapPickerState.scanning(straps: [_polar]),
        StrapPickerState.scanning(straps: [_polar, _tickr]),
        StrapPickerState.scanning(
          straps: [
            DiscoveredStrap(id: 'polar', name: 'Polar H10 2'),
            _tickr,
          ],
        ),
        // The same strap again changes nothing, so nothing is emitted.
      ],
    );

    for (final problem in BluetoothProblem.values) {
      blocTest<StrapPickerCubit, StrapPickerState>(
        'a scan that fails (${problem.name}) shows why, and forgets the '
        'straps found',
        build: () => StrapPickerCubit(scanner: scanner),
        act: (cubit) {
          cubit.start();
          scanner
            ..emit(const .found(_polar))
            ..emit(StrapScanEvent.failed(problem));
        },
        expect: () => [
          const StrapPickerState.scanning(straps: [_polar]),
          StrapPickerState.failed(problem),
        ],
      );
    }

    blocTest<StrapPickerCubit, StrapPickerState>(
      'scanning again after a failure starts a fresh list',
      build: () => StrapPickerCubit(scanner: scanner),
      act: (cubit) {
        cubit.start();
        scanner
          ..emit(const .found(_polar))
          ..emit(const .failed(.off))
          ..emit(const .scanning())
          ..emit(const .found(_tickr));
      },
      expect: () => const [
        StrapPickerState.scanning(straps: [_polar]),
        StrapPickerState.failed(.off),
        StrapPickerState.scanning(straps: []),
        StrapPickerState.scanning(straps: [_tickr]),
      ],
    );

    blocTest<StrapPickerCubit, StrapPickerState>(
      'a strap found after a failure means it is scanning again',
      build: () => StrapPickerCubit(scanner: scanner),
      act: (cubit) {
        cubit.start();
        scanner
          ..emit(const .failed(.off))
          ..emit(const .found(_tickr));
      },
      expect: () => const [
        StrapPickerState.failed(.off),
        StrapPickerState.scanning(straps: [_tickr]),
      ],
    );

    blocTest<StrapPickerCubit, StrapPickerState>(
      'the list can be read but not changed',
      build: () => StrapPickerCubit(scanner: scanner),
      act: (cubit) {
        cubit.start();
        scanner.emit(const .found(_polar));
      },
      verify: (cubit) {
        switch (cubit.state) {
          case StrapPickerScanning(:final straps):
            expect(() => straps.add(_tickr), throwsUnsupportedError);
          case StrapPickerFailed():
            fail('expected a list of straps');
        }
      },
    );

    group('close', () {
      test('stops the scan', () async {
        final cubit = StrapPickerCubit(scanner: scanner)..start();
        await cubit.close();
        expect(scanner.isScanning, isFalse);
      });

      test('closes the cubit even if stopping the scan fails, and still '
          'reports the failure', () async {
        final failure = Exception('stop failed');
        scanner.cancelError = failure;
        final cubit = StrapPickerCubit(scanner: scanner)..start();
        await expectLater(cubit.close(), throwsA(same(failure)));
        expect(cubit.isClosed, isTrue);
      });

      test('start after close does nothing', () async {
        final cubit = StrapPickerCubit(scanner: scanner);
        await cubit.close();
        cubit.start();
        expect(scanner.scanCount, 0);
      });
    });
  });
}
