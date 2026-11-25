// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulselink/domain/beats_per_minute.dart';
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
const _skinContactDetected = 0x02;
const _skinContactSupported = 0x04;
const _energyExpendedPresent = 0x08;
const _rrIntervalsPresent = 0x10;

/// Parses a Heart Rate Measurement characteristic value (UUID 0x2A37).
///
/// Never throws: a malformed packet returns [HeartRateParseFailure] rather
/// than a sample with a wrong number in it. Fields after the flags byte are
/// little-endian. Energy Expended is checked for length but skipped. RR
/// intervals arrive in units of 1/1024 s and are converted to [Duration]s.
///
/// A well-formed packet with no skin contact, a bpm of 0 or a bpm above
/// [BeatsPerMinute.max] becomes an [UnavailableHeartRateSample] (no skin
/// contact wins if it applies too), and its bpm and RR intervals are dropped.
/// Everything else is a [MeasuredHeartRateSample].
HeartRateParseResult parseHeartRateMeasurement(
  Uint8List packet, {
  required DateTime timestamp,
}) {
  final reader = _ByteReader(packet);

  final flags = reader.uint8();
  if (flags == null) {
    return const HeartRateParseResult.failure(HeartRateParseError.empty);
  }

  final rawBeatsPerMinute = flags & _heartRateIsUint16 != 0
      ? reader.uint16()
      : reader.uint8();
  if (rawBeatsPerMinute == null) {
    return const HeartRateParseResult.failure(
      HeartRateParseError.truncatedHeartRate,
    );
  }

  // Energy Expended is read only to skip past it.
  if (flags & _energyExpendedPresent != 0 && reader.uint16() == null) {
    return const HeartRateParseResult.failure(
      HeartRateParseError.truncatedEnergyExpended,
    );
  }

  final rrIntervals = <Duration>[];
  if (flags & _rrIntervalsPresent != 0) {
    while (!reader.isAtEnd) {
      final units = reader.uint16();
      if (units == null) {
        return const HeartRateParseResult.failure(
          HeartRateParseError.truncatedRrInterval,
        );
      }
      rrIntervals.add(Duration(microseconds: (units * 1000000 / 1024).round()));
    }
  }

  // The whole packet is valid. Now decide whether its bpm can be trusted.
  // Bit 2: the strap supports skin-contact detection. Bit 1: it detects skin
  // contact.
  // Bit 1 means nothing unless bit 2 is set.
  final skinContactSupported = flags & _skinContactSupported != 0;
  final skinContactDetected = flags & _skinContactDetected != 0;
  final beatsPerMinute = BeatsPerMinute.tryFrom(rawBeatsPerMinute);
  final HeartRateSample sample;
  if (skinContactSupported && !skinContactDetected) {
    sample = HeartRateSample.unavailable(
      timestamp: timestamp,
      reason: HeartRateUnavailableReason.noSkinContact,
    );
  } else if (beatsPerMinute == null) {
    sample = HeartRateSample.unavailable(
      timestamp: timestamp,
      // The raw value is unsigned, so out of BeatsPerMinute's range means 0 or
      // too high.
      reason: rawBeatsPerMinute == 0
          ? HeartRateUnavailableReason.zeroBeatsPerMinute
          : HeartRateUnavailableReason.implausibleBeatsPerMinute,
    );
  } else {
    sample = HeartRateSample.measured(
      beatsPerMinute: beatsPerMinute,
      timestamp: timestamp,
      skinContact: skinContactSupported
          ? SkinContact.detected
          : SkinContact.notSupported,
      rrIntervals: rrIntervals,
    );
  }
  return HeartRateParseResult.success(sample);
}

/// Reads little-endian unsigned integers from a packet, front to back. Each
/// read returns null, rather than throwing, when there aren't enough bytes
/// left, so the parser can't read past the end.
class _ByteReader {
  new(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  bool get isAtEnd => _offset >= _bytes.length;

  int? uint8() {
    if (_bytes.length - _offset < 1) {
      return null;
    }
    final value = _bytes[_offset];
    _offset += 1;
    return value;
  }

  int? uint16() {
    if (_bytes.length - _offset < 2) {
      return null;
    }
    final value = _bytes[_offset] | (_bytes[_offset + 1] << 8);
    _offset += 2;
    return value;
  }
}
