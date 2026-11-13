import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/bpm.dart';

/// A [Bpm] for test fixtures. Fails the test, rather than returning null, if
/// [value] is out of range.
Bpm bpmOf(int value) => Bpm.tryFrom(value) ?? fail('$value is not a valid bpm');
