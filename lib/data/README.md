# data

Everything that talks to the outside world, behind interfaces so it can be
faked in tests: `HeartRateSource` (BLE or fake), `SessionRepository` (drift),
and `WatchBridge` (WatchConnectivity via platform channels).
