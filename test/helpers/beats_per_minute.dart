import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/beats_per_minute.dart';

/// A [BeatsPerMinute] for test fixtures. Fails the test, rather than returning
/// null, if [value] is out of range.
BeatsPerMinute beatsPerMinuteOf(int value) =>
    BeatsPerMinute.tryFrom(value) ?? fail('$value is not a valid bpm');
