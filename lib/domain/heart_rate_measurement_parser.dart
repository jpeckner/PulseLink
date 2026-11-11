import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

part 'heart_rate_measurement_parser.freezed.dart';

/// Why a Heart Rate Measurement packet was rejected.
enum HeartRateParseError {
  /// The packet has no bytes, so not even a flags byte.
  empty,

  /// Too few bytes for the heart-rate value the flags declare.
  truncatedHeartRate,

  /// The flags declare an Energy Expended field that isn't all there.
  truncatedEnergyExpended,

  /// The RR-interval bytes aren't a whole number of uint16 values.
  truncatedRrInterval,
}

/// The outcome of parsing one packet: a sample, or the reason it was rejected.
@freezed
sealed class HeartRateParseResult with _$HeartRateParseResult {
  const factory success(HeartRateSample sample) = HeartRateParseSuccess;

  const factory failure(HeartRateParseError error) = HeartRateParseFailure;
}

// Flags byte (byte 0) bit masks, from the Bluetooth Heart Rate Service spec.
const _heartRateIsUint16 = 0x01;
const _contactDetected = 0x02;
const _contactSupported = 0x04;
const _energyExpendedPresent = 0x08;
const _rrIntervalsPresent = 0x10;

/// Parses a Heart Rate Measurement characteristic value (UUID 0x2A37).
///
/// Never throws: a malformed packet returns [HeartRateParseFailure] rather
/// than a sample with a wrong number in it. Fields after the flags byte are
/// little-endian. Energy Expended is validated but skipped. RR intervals arrive
/// in units of 1/1024 s and are converted to [Duration]s.
HeartRateParseResult parseHeartRateMeasurement(
  Uint8List packet, {
  required DateTime timestamp,
}) {
  if (packet.isEmpty) {
    return const HeartRateParseResult.failure(HeartRateParseError.empty);
  }

  final bytes = ByteData.sublistView(packet);
  final flags = bytes.getUint8(0);
  var offset = 1;

  final int bpm;
  if (flags & _heartRateIsUint16 != 0) {
    if (packet.length < offset + 2) {
      return const HeartRateParseResult.failure(
        HeartRateParseError.truncatedHeartRate,
      );
    }
    bpm = bytes.getUint16(offset, Endian.little);
    offset += 2;
  } else {
    if (packet.length < offset + 1) {
      return const HeartRateParseResult.failure(
        HeartRateParseError.truncatedHeartRate,
      );
    }
    bpm = bytes.getUint8(offset);
    offset += 1;
  }

  if (flags & _energyExpendedPresent != 0) {
    if (packet.length < offset + 2) {
      return const HeartRateParseResult.failure(
        HeartRateParseError.truncatedEnergyExpended,
      );
    }
    offset += 2;
  }

  final rrIntervals = <Duration>[];
  if (flags & _rrIntervalsPresent != 0) {
    final remaining = packet.length - offset;
    if (remaining.isOdd) {
      return const HeartRateParseResult.failure(
        HeartRateParseError.truncatedRrInterval,
      );
    }
    for (; offset < packet.length; offset += 2) {
      final units = bytes.getUint16(offset, Endian.little);
      rrIntervals.add(Duration(microseconds: (units * 1000000 / 1024).round()));
    }
  }

  return HeartRateParseResult.success(
    HeartRateSample(
      bpm: bpm,
      timestamp: timestamp,
      contact: _contactFromFlags(flags),
      rrIntervals: rrIntervals,
    ),
  );
}

SensorContact _contactFromFlags(int flags) {
  if (flags & _contactSupported == 0) return SensorContact.notSupported;
  return flags & _contactDetected != 0
      ? SensorContact.detected
      : SensorContact.notDetected;
}
