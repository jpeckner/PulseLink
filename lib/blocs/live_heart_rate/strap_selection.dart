import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/data/ble/ble_heart_rate_source.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/data/switchable_heart_rate_source.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';

/// Switches the live heart rate to a strap the user picked.
///
/// A small first step: Milestone 4's connection Bloc takes this over, with
/// reconnecting and remembering the last strap.
class StrapSelection {
  /// [createSource] makes the source for a picked strap; tests pass a stub.
  new({
    required this._source,
    required this._cubit,
    HeartRateSource Function(StrapBleIdentifier strapId)? createSource,
  }) : _createSource =
           createSource ?? ((strapId) => BleHeartRateSource(strapId: strapId));

  final SwitchableHeartRateSource _source;
  final LiveHeartRateCubit _cubit;
  final HeartRateSource Function(StrapBleIdentifier strapId) _createSource;

  /// Replaces the current source with one for [strap], then restarts the
  /// live heart rate, which shows waiting until the strap's first reading,
  /// or why it couldn't connect.
  ///
  /// Expected failures (Bluetooth off, strap unreachable) show up as the
  /// cubit's state, not as errors. This only throws if disposing the
  /// previous source fails; the strap is still switched to and started.
  Future<void> select(DiscoveredStrap strap) async {
    try {
      await _source.switchTo(_createSource(strap.id));
    } finally {
      await _cubit.restart();
    }
  }
}
