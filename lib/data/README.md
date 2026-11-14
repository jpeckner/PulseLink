# data

Everything that talks to the outside world, behind interfaces so it can be
faked in tests: `HeartRateSource` (BLE or fake), `StrapScanner` (BLE),
`SessionRepository` (drift), and `WatchBridge` (WatchConnectivity via platform
channels).

`ble/` holds the BLE implementations. They talk to native code (CoreBluetooth
on iOS, Android's BLE APIs on Android) through Pigeon platform channels: the
contract is `pigeons/ble_api.dart`, and `tool/pigeon.sh` generates
`ble_api.pigeon.dart` and its Swift and Kotlin counterparts from it. Only this
folder imports the generated code; everything above it sees domain types.
