import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/domain/positive_int.dart';

/// A [PositiveInt] for test fixtures. Fails the test, rather than returning
/// null, if [value] isn't above 0.
PositiveInt positiveInt(int value) =>
    PositiveInt.tryFrom(value) ?? fail('$value is not a positive int');
