# data

Everything that talks to the outside world, behind interfaces so it can be
faked in tests: `StrapDataSource` (BLE or fake), `StrapScanner` (BLE),
`AppSettings` (opens the app's page in Settings), `SessionRepository`
(drift), and `WatchBridge` (WatchConnectivity via platform channels).

`ble/` holds the BLE implementations. They talk to native code (CoreBluetooth
on iOS, Android's BLE APIs on Android) through Pigeon platform channels: the
contract is `pigeons/ble_api.dart`, and `tool/pigeon.sh` generates
`ble_api.pigeon.dart` and its Swift and Kotlin counterparts from it. Only this
folder imports the generated code; everything above it sees domain types.
The `keep_pigeon_imports_local` lint enforces that, since Pigeon can't make
the generated fields private.

`app_settings/` works the same way, with its own contract,
`pigeons/app_settings_api.dart`. Pigeon allows one Swift or Kotlin error
class per module, so that contract leaves it to `ble_api.dart`'s generated
code.

`watch/` holds `PigeonWatchBridge`, which sends heart-rate snapshots to the
Apple Watch app through the iPhone's WatchConnectivity code
(`ios/Runner/Watch/`). Its contract is `pigeons/watch_api.dart`, which has no
Android side: there's no watch app on Android. Only this folder imports
`watch_api.pigeon.dart`.
