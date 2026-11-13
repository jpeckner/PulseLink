import 'dart:async';

import 'package:pulselink/data/strap_scanner.dart';

/// A [StrapScanner] that tests drive by hand with [emit], and that records
/// how it was used.
class StubStrapScanner implements StrapScanner {
  MultiStreamController<StrapScanEvent>? _listener;

  int scanCount = 0;

  /// When set, cancelling a scan fails with this error.
  Exception? cancelError;

  /// Whether a scan is being listened to.
  bool get isScanning => _listener != null;

  /// Sends [event] to the scan being listened to. Synchronous, so it has
  /// reached the listener when this returns.
  void emit(StrapScanEvent event) => _listener?.addSync(event);

  @override
  Stream<StrapScanEvent> scan() {
    scanCount++;
    return Stream.multi((listener) {
      _listener = listener;
      listener.onCancel = () {
        _listener = null;
        if (cancelError case final error?) {
          throw error;
        }
      };
    });
  }
}
