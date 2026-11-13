import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:pulselink/blocs/strap_picker/strap_picker_state.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/discovered_strap.dart';

/// Scans for straps while the picker is open, and lists what it finds.
class StrapPickerCubit extends Cubit<StrapPickerState> {
  new({required this._scanner}) : super(const .scanning(straps: []));

  final StrapScanner _scanner;
  StreamSubscription<StrapScanEvent>? _subscription;

  /// Starts scanning, until [close]. Safe to call more than once; does
  /// nothing after [close].
  void start() {
    if (isClosed) {
      return;
    }
    // No onError: StrapScanner.scan reports expected failures as events, and
    // an error would be a bug, left for the zone's error handler.
    _subscription ??= _scanner.scan().listen(_onEvent);
  }

  void _onEvent(StrapScanEvent event) {
    switch (event) {
      case StrapScanScanning():
        switch (state) {
          case StrapPickerFailed():
            emit(const .scanning(straps: []));
          case StrapPickerScanning():
            // Already scanning, and keeping what's been found.
            break;
        }
      case StrapFound(:final strap):
        emit(.scanning(straps: _withStrap(strap)));
      case StrapScanFailed(:final problem):
        emit(.failed(problem));
    }
  }

  /// The straps shown so far, plus [strap]. A strap found again replaces the
  /// earlier copy in place, in case its name has changed.
  List<DiscoveredStrap> _withStrap(DiscoveredStrap strap) {
    final straps = switch (state) {
      StrapPickerScanning(:final straps) => straps,
      // A strap found means the phone is scanning again. Shouldn't happen,
      // since scanning resumes with a StrapScanScanning first.
      StrapPickerFailed() => const <DiscoveredStrap>[],
    };
    final index = straps.indexWhere((shown) => shown.id == strap.id);
    return index < 0
        ? List.unmodifiable([...straps, strap])
        : List.unmodifiable([
            ...straps.take(index),
            strap,
            ...straps.skip(index + 1),
          ]);
  }

  @override
  Future<void> close() async {
    try {
      // Stops the scan.
      await _subscription?.cancel();
    } finally {
      // Close even if stopping failed; the error still reaches the caller.
      await super.close();
    }
  }
}
