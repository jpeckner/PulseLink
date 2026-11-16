import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/data/ble/ble_strap_data_source.dart';
import 'package:pulselink/data/strap_data_source.dart';
import 'package:pulselink/data/switchable_strap_data_source.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';

/// Switches the live heart rate to a strap the user picked, back to no
/// strap, or, in debug and profile builds, to demo data.
///
/// A small first step: the connection Bloc planned for Milestone 6 takes
/// this over, with reconnecting and remembering the last strap.
class StrapSelection {
  /// [createSource] makes the source for a picked strap; tests pass a stub.
  new({
    required this._source,
    required this._cubit,
    StrapDataSource Function(StrapBleIdentifier strapId)? createSource,
  }) : _createSource =
           createSource ?? ((strapId) => BleStrapDataSource(strapId: strapId));

  final SwitchableStrapDataSource _source;
  final LiveHeartRateCubit _cubit;
  final StrapDataSource Function(StrapBleIdentifier strapId) _createSource;

  /// Replaces the current source with one for [strap], then restarts the
  /// live heart rate, which shows waiting until the strap's first reading,
  /// or why it couldn't connect.
  ///
  /// Expected failures (Bluetooth off, strap unreachable) show up as the
  /// cubit's state, not as errors. This only throws if disposing the
  /// previous source fails; the strap is still switched to and started.
  Future<void> select(DiscoveredStrap strap) => use(_createSource(strap.id));

  /// Replaces the current source with [next], then restarts the live heart
  /// rate, as [select] does for a strap. Debug and profile builds use it to
  /// switch to demo data.
  ///
  /// This only throws if disposing the previous source fails; [next] is
  /// still switched to and started.
  Future<void> use(StrapDataSource next) async {
    try {
      await _source.switchTo(next);
    } finally {
      await _cubit.restart();
    }
  }

  /// Lets go of the current source, then restarts the live heart rate,
  /// which then shows that there's no strap, as at launch. Debug and
  /// profile builds use it to switch from demo data back to real data.
  ///
  /// This only throws if disposing the previous source fails; the live
  /// heart rate still restarts.
  Future<void> clear() async {
    try {
      await _source.clear();
    } finally {
      await _cubit.restart();
    }
  }
}
